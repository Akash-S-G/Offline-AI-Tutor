#include <jni.h>
#include <android/log.h>

#include <chrono>
#include <cctype>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#include "llama.h"

namespace {

constexpr const char * kTag = "LlamaJNI";

std::mutex g_mutex;
std::once_flag g_backend_once;

llama_model * g_model = nullptr;
llama_context * g_ctx = nullptr;
llama_sampler * g_sampler = nullptr;
std::string g_model_path;
std::string g_last_error;

void loge(const std::string & msg) {
    __android_log_print(ANDROID_LOG_ERROR, kTag, "%s", msg.c_str());
    g_last_error = msg;
}

void release_native_locked() {
    if (g_sampler != nullptr) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    if (g_ctx != nullptr) {
        llama_free(g_ctx);
        g_ctx = nullptr;
    }
    if (g_model != nullptr) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    g_model_path.clear();
}

std::string token_to_string(const llama_vocab * vocab, llama_token token) {
    char piece[256];
    const int32_t n = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, true);
    if (n <= 0) {
        return {};
    }
    return std::string(piece, piece + n);
}

std::string sanitize_for_jni(const std::string & input) {
    // Keep JNI-safe output by filtering non-printable bytes from token pieces.
    std::string out;
    out.reserve(input.size());
    for (unsigned char ch : input) {
        if (ch == '\n' || ch == '\r' || ch == '\t' || (ch >= 32 && ch <= 126)) {
            out.push_back(static_cast<char>(ch));
        }
    }
    if (out.empty()) {
        return "I could not generate a readable answer. Please try again.";
    }
    constexpr size_t kMaxResponseChars = 6000;
    if (out.size() > kMaxResponseChars) {
        out.resize(kMaxResponseChars);
    }
    return out;
}

jstring new_safe_jstring(JNIEnv * env, const std::string & text) {
    const std::string safe = sanitize_for_jni(text);
    return env->NewStringUTF(safe.c_str());
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_offline_1tutor_1app_LlamaEngine_nativeInit(
    JNIEnv * env,
    jobject /* thiz */,
    jstring model_path,
    jint n_ctx,
    jint n_threads) {
    const char * model_cstr = env->GetStringUTFChars(model_path, nullptr);
    if (model_cstr == nullptr) {
        return JNI_FALSE;
    }

    const std::string model(model_cstr);
    env->ReleaseStringUTFChars(model_path, model_cstr);

    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_model != nullptr && g_ctx != nullptr && g_model_path == model) {
        return JNI_TRUE;
    }

    release_native_locked();

    std::call_once(g_backend_once, []() {
        llama_backend_init();
    });

    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;
    model_params.use_mmap = true;
    model_params.use_direct_io = false;
    model_params.use_mlock = false;
    model_params.check_tensors = false;
    model_params.use_extra_bufts = false;

    g_model = llama_model_load_from_file(model.c_str(), model_params);
    if (g_model == nullptr) {
        loge("Failed to load model: " + model);
        release_native_locked();
        return JNI_FALSE;
    }

    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = static_cast<uint32_t>(n_ctx);
    ctx_params.n_batch = 256;
    ctx_params.n_ubatch = 256;
    ctx_params.n_threads = n_threads;
    ctx_params.n_threads_batch = n_threads;

    g_ctx = llama_init_from_model(g_model, ctx_params);
    if (g_ctx == nullptr) {
        loge("Failed to create llama context");
        release_native_locked();
        return JNI_FALSE;
    }

    llama_set_n_threads(g_ctx, n_threads, n_threads);

    auto sparams = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(sparams);
    // Greedy sampling is faster and more stable for low-latency tutor responses.
    llama_sampler_chain_add(g_sampler, llama_sampler_init_greedy());

    g_model_path = model;
    g_last_error.clear();
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_offline_1tutor_1app_LlamaEngine_nativeGenerate(
    JNIEnv * env,
    jobject /* thiz */,
    jstring prompt,
    jint max_tokens,
    jfloat /* temperature */,
    jint max_duration_ms) {
    const char * prompt_cstr = env->GetStringUTFChars(prompt, nullptr);
    if (prompt_cstr == nullptr) {
        return new_safe_jstring(env, "Failed to read prompt.");
    }
    const std::string prompt_text(prompt_cstr);
    env->ReleaseStringUTFChars(prompt, prompt_cstr);

    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_model == nullptr || g_ctx == nullptr || g_sampler == nullptr) {
        g_last_error = "Native model runtime is not initialized.";
        return new_safe_jstring(env, "Native model runtime is not initialized.");
    }

    // Clear sequence metadata only to reduce per-request overhead.
    llama_memory_clear(llama_get_memory(g_ctx), false);
    llama_sampler_reset(g_sampler);

    const llama_vocab * vocab = llama_model_get_vocab(g_model);
    std::vector<llama_token> prompt_tokens(prompt_text.size() + 32);
    int32_t prompt_count = llama_tokenize(
        vocab,
        prompt_text.c_str(),
        static_cast<int32_t>(prompt_text.size()),
        prompt_tokens.data(),
        static_cast<int32_t>(prompt_tokens.size()),
        false,
        false);

    if (prompt_count < 0) {
        const int32_t required = -prompt_count;
        prompt_tokens.resize(static_cast<size_t>(required));
        prompt_count = llama_tokenize(
            vocab,
            prompt_text.c_str(),
            static_cast<int32_t>(prompt_text.size()),
            prompt_tokens.data(),
            required,
            false,
            false);
    }

    if (prompt_count <= 0) {
        g_last_error = "Tokenization failed.";
        return new_safe_jstring(env, "Tokenization failed.");
    }

    const uint32_t n_ctx = llama_n_ctx(g_ctx);
    if (n_ctx > 0 && static_cast<uint32_t>(prompt_count + 8) >= n_ctx) {
        g_last_error = "Prompt is too long for current context window.";
        return new_safe_jstring(env, "Prompt is too long for current context window.");
    }

    if (llama_decode(
            g_ctx,
            llama_batch_get_one(prompt_tokens.data(), prompt_count)) != 0) {
        g_last_error = "Prompt decode failed.";
        return new_safe_jstring(env, "Prompt decode failed.");
    }

    std::string generated;
    generated.reserve(1024);
    const auto started = std::chrono::steady_clock::now();

    for (int i = 0; i < max_tokens; ++i) {
        const auto now = std::chrono::steady_clock::now();
        const auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - started).count();
        if (max_duration_ms > 0 && elapsed_ms >= max_duration_ms) {
            if (generated.empty()) {
                generated = "Model response timed out. Try a smaller model or shorter question.";
                g_last_error = generated;
            }
            break;
        }

        const llama_token token = llama_sampler_sample(g_sampler, g_ctx, -1);
        if (llama_vocab_is_eog(vocab, token)) {
            break;
        }

        generated += token_to_string(vocab, token);

        llama_sampler_accept(g_sampler, token);

        llama_token next_token = token;
        if (llama_decode(g_ctx, llama_batch_get_one(&next_token, 1)) != 0) {
            break;
        }
    }

    if (generated.empty()) {
        generated = "I could not generate an answer. Please try again.";
    }

    g_last_error.clear();

    return new_safe_jstring(env, generated);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_offline_1tutor_1app_LlamaEngine_nativeGetLastError(
    JNIEnv * env,
    jobject /* thiz */) {
    return new_safe_jstring(env, g_last_error);
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_offline_1tutor_1app_LlamaEngine_nativeRelease(
    JNIEnv * /* env */,
    jobject /* thiz */) {
    std::lock_guard<std::mutex> lock(g_mutex);
    release_native_locked();
}
