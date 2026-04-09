package com.arm.aichat

import com.arm.aichat.InferenceEngine.State
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

interface InferenceEngine {
    val state: StateFlow<State>

    suspend fun loadModel(pathToModel: String)

    suspend fun setSystemPrompt(systemPrompt: String)

    fun sendUserPrompt(message: String, predictLength: Int = DEFAULT_PREDICT_LENGTH): Flow<String>

    // NEW: Fast path for complete response in single JNI call (system prompt processed separately)
    suspend fun generateFastResponse(
        userPrompt: String,
        maxTokens: Int
    ): String

    suspend fun bench(pp: Int, tg: Int, pl: Int, nr: Int = 1): String

    fun cleanUp()

    fun stopGeneration()

    fun destroy()

    sealed class State {
        object Uninitialized : State()
        object Initializing : State()
        object Initialized : State()

        object LoadingModel : State()
        object UnloadingModel : State()
        object ModelReady : State()

        object Benchmarking : State()
        object ProcessingSystemPrompt : State()
        object ProcessingUserPrompt : State()

        object Generating : State()

        data class Error(val exception: Exception) : State()
    }

    companion object {
        const val DEFAULT_PREDICT_LENGTH = 1024
    }
}

class UnsupportedArchitectureException : Exception()
