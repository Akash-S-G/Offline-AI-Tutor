import 'dart:convert';
import 'dart:io';

import 'local/linux_llm_config_service.dart';
import 'tutor_inference_gateway.dart';

class LinuxTutorInferenceGateway implements TutorInferenceGateway {
  LinuxTutorInferenceGateway({LinuxLlmConfigService? configService})
    : _configService = configService ?? LinuxLlmConfigService();

  final LinuxLlmConfigService _configService;
  Process? _activeProcess;
  final Map<String, _LlamaCliCapabilities> _capabilityCache =
      <String, _LlamaCliCapabilities>{};
  static final RegExp _ansiEscape = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');

  @override
  Stream<String> streamResponse({required String prompt}) async* {
    final config = await _configService.load();
    final executable = config.executablePath.trim();
    final model = config.modelPath.trim();

    if (executable.isEmpty || model.isEmpty) {
      throw Exception(
        'Linux model is not configured. Select executable and model path in chat settings.',
      );
    }

    final resolvedExecutable = await _configService.autoDetectExecutable();
    final executableToUse =
        resolvedExecutable != null &&
            executable == LinuxLlmConfig.defaults.executablePath
        ? resolvedExecutable
        : executable;

    if (executableToUse.contains('/')) {
      final execFile = File(executableToUse);
      if (!await execFile.exists()) {
        throw Exception('LLM executable not found: $executableToUse');
      }
    }

    final modelFile = File(model);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found: $model');
    }

    final capabilities = await _detectCapabilities(executableToUse);

    final selected = await _selectExecutionTarget(
      executable: executableToUse,
      capabilities: capabilities,
    );

    final args = _buildArgs(
      model: model,
      maxTokens: config.maxTokens,
      prompt: prompt,
      executable: selected.executable,
      capabilities: selected.capabilities,
    );

    await stopGeneration();

    final process = await Process.start(
      selected.executable,
      args,
      runInShell: false,
    );
    _activeProcess = process;

    final stderrBuffer = StringBuffer();
    // Capture stderr continuously because some llama.cpp builds emit tokens/logs to stderr.
    process.stderr.transform(utf8.decoder).listen((chunk) {
      if (chunk.isEmpty) return;
      stderrBuffer.write(chunk);
      final cleaned = chunk.replaceAll(_ansiEscape, '');
      // Print diagnostics so we can see why UI might be waiting forever.
      // Keep stderr streaming separate from stdout-yielding stream.
      // ignore: avoid_print
      print('[LLAMA STDERR] ${cleaned.trim()}');
    });

    try {
      await for (final chunk in process.stdout.transform(utf8.decoder)) {
        if (chunk.isNotEmpty) {
          final cleaned = chunk.replaceAll(_ansiEscape, '');
          if (cleaned.isNotEmpty) {
            // Some llama.cpp runners may not flush stdout token-by-token.
            // Yield whatever we get (even if it includes partial lines),
            // so the UI can progress and stop showing 'Thinking...'.
            yield cleaned;
          }
        }
      }

      final code = await process.exitCode;
      if (code != 0) {
        final message = stderrBuffer.toString().trim();
        throw Exception(
          message.isEmpty
              ? 'Linux inference failed with exit code $code'
              : 'Linux inference failed: $message',
        );
      }
    } finally {
      if (identical(_activeProcess, process)) {
        _activeProcess = null;
      }
    }
  }

  @override
  Stream<Map<String, dynamic>> metricsStream() {
    return const Stream<Map<String, dynamic>>.empty();
  }

  Future<_LlamaCliCapabilities> _detectCapabilities(String executable) async {
    final cached = _capabilityCache[executable];
    if (cached != null) {
      return cached;
    }

    try {
      final result = await Process.run(executable, const <String>[
        '--help',
      ], runInShell: false);
      final help = '${result.stdout}\n${result.stderr}'.toLowerCase();
      final detected = _LlamaCliCapabilities(
        supportsLongPrompt: help.contains('--prompt'),
        supportsNoDisplayPrompt: help.contains('--no-display-prompt'),
        supportsNoConversation:
            help.contains('--no-conversation') || help.contains('-no-cnv'),
        supportsSimpleIo: help.contains('--simple-io'),
        supportsNoPerf: help.contains('--no-perf'),
      );
      _capabilityCache[executable] = detected;
      return detected;
    } catch (_) {
      const fallback = _LlamaCliCapabilities(
        supportsLongPrompt: false,
        supportsNoDisplayPrompt: false,
        supportsNoConversation: false,
        supportsSimpleIo: false,
        supportsNoPerf: false,
      );
      _capabilityCache[executable] = fallback;
      return fallback;
    }
  }

  List<String> _buildArgs({
    required String model,
    required int maxTokens,
    required String prompt,
    required String executable,
    required _LlamaCliCapabilities capabilities,
  }) {
    final args = <String>[
      '-m',
      model,
      '-n',
      maxTokens.toString(),
      capabilities.supportsLongPrompt ? '--prompt' : '-p',
      prompt,
      '--temp',
      '0.3',
      '--top-k',
      '30',
    ];

    final exeName = executable.split('/').last.toLowerCase();
    if (exeName.contains('llama-completion') &&
        capabilities.supportsNoConversation) {
      // Prevent REPL-style session that never exits and blocks UI completion.
      args.add('--no-conversation');
    }

    if (capabilities.supportsNoDisplayPrompt) {
      args.add('--no-display-prompt');
    }

    if (capabilities.supportsSimpleIo) {
      args.add('--simple-io');
    }

    if (capabilities.supportsNoPerf) {
      args.add('--no-perf');
    }

    return args;
  }

  Future<({String executable, _LlamaCliCapabilities capabilities})>
  _selectExecutionTarget({
    required String executable,
    required _LlamaCliCapabilities capabilities,
  }) async {
    final exeName = executable.split('/').last.toLowerCase();
    if (!exeName.contains('llama-cli')) {
      return (executable: executable, capabilities: capabilities);
    }

    final completionPath = await _findLlamaCompletion(executable);
    if (completionPath == null) {
      return (executable: executable, capabilities: capabilities);
    }

    final completionCapabilities = await _detectCapabilities(completionPath);
    return (executable: completionPath, capabilities: completionCapabilities);
  }

  Future<String?> _findLlamaCompletion(String selectedExecutable) async {
    final candidates = <String>[];
    if (selectedExecutable.contains('/')) {
      final sibling = selectedExecutable.replaceAll(
        'llama-cli',
        'llama-completion',
      );
      candidates.add(sibling);
    }
    candidates.addAll(const <String>[
      '/home/akash/Desktop/IDP/llama.cpp/build/bin/llama-completion',
      '/usr/local/bin/llama-completion',
      '/usr/bin/llama-completion',
      'llama-completion',
    ]);

    for (final candidate in candidates) {
      try {
        if (candidate.contains('/')) {
          final file = File(candidate);
          if (await file.exists()) {
            return candidate;
          }
        } else {
          final which = await Process.run('which', <String>[candidate]);
          if (which.exitCode == 0) {
            final resolved = (which.stdout as String?)?.trim() ?? '';
            if (resolved.isNotEmpty) {
              return resolved;
            }
          }
        }
      } catch (_) {
        // Try the next candidate.
      }
    }

    return null;
  }

  @override
  Future<void> stopGeneration() async {
    final process = _activeProcess;
    if (process == null) {
      return;
    }

    try {
      process.kill(ProcessSignal.sigint);
      await process.exitCode.timeout(
        const Duration(milliseconds: 600),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
    } finally {
      _activeProcess = null;
    }
  }
}

class _LlamaCliCapabilities {
  const _LlamaCliCapabilities({
    required this.supportsLongPrompt,
    required this.supportsNoDisplayPrompt,
    required this.supportsNoConversation,
    required this.supportsSimpleIo,
    required this.supportsNoPerf,
  });

  final bool supportsLongPrompt;
  final bool supportsNoDisplayPrompt;
  final bool supportsNoConversation;
  final bool supportsSimpleIo;
  final bool supportsNoPerf;
}
