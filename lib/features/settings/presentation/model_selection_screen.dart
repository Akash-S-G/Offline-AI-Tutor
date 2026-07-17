import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../chat/data/llm_admin_channel_service.dart';

class ModelSelectionScreen extends StatefulWidget {
  const ModelSelectionScreen({super.key});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  final LlmAdminChannelService _service = LlmAdminChannelService();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _timeoutMsController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();

  ModelMetadata? _metadata;
  GenerationConfig? _generationConfig;
  EngineStatus? _engineStatus;

  bool _loading = true;
  bool _updatingModelPath = false;
  bool _updatingConfig = false;
  bool _validatingModel = false;
  String? _error;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maxTokensController.dispose();
    _timeoutMsController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final metadata = await _service.getModelMetadata();
      final config = await _service.getGenerationConfig();
      final status = await _service.getEngineStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _metadata = metadata;
        _generationConfig = config;
        _engineStatus = status;
        _maxTokensController.text = config.maxTokens.toString();
        _timeoutMsController.text = config.timeoutMs.toString();
        _systemPromptController.text = config.systemPrompt;
        _loading = false;
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(context)!.settingsModelNotAvailable;
        _loading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? AppLocalizations.of(context)!.settingsModelLoadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndSetModel() async {
    setState(() {
      _updatingModelPath = true;
      _error = null;
    });

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      final path = picked?.files.single.path;
      if (path == null || path.isEmpty) {
        if (mounted) {
          setState(() {
            _updatingModelPath = false;
          });
        }
        return;
      }

      if (!path.toLowerCase().endsWith('.gguf')) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = 'Please select a .gguf model file.';
          _updatingModelPath = false;
        });
        return;
      }

      final updated = await _service.setModelPath(path);
      if (!updated) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = 'Model path was rejected by native engine. Ensure it is a readable .gguf file.';
          _updatingModelPath = false;
        });
        return;
      }

      await _load();
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Updating model path is not supported on this platform yet. Currently implemented on Android.';
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? 'Failed to update model path.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingModelPath = false;
        });
      }
    }
  }

  Future<void> _saveGenerationConfig() async {
    setState(() {
      _updatingConfig = true;
      _error = null;
    });

    final maxTokens = int.tryParse(_maxTokensController.text.trim());
    final timeoutMs = int.tryParse(_timeoutMsController.text.trim());
    final systemPrompt = _systemPromptController.text.trim();

    if (maxTokens == null || timeoutMs == null) {
      setState(() {
        _error = 'Max tokens and timeout must be valid numbers.';
        _updatingConfig = false;
      });
      return;
    }

    try {
      final updatedConfig = await _service.updateGenerationConfig(
        maxTokens: maxTokens,
        timeoutMs: timeoutMs,
        systemPrompt: systemPrompt,
      );
      final updatedStatus = await _service.getEngineStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _generationConfig = updatedConfig;
        _engineStatus = updatedStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model configuration updated.')),
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Model configuration is not available on this platform yet. Currently implemented on Android.';
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? 'Failed to update model configuration.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingConfig = false;
        });
      }
    }
  }

  Future<void> _validateSelectedModel() async {
    setState(() {
      _validatingModel = true;
      _validationMessage = null;
      _error = null;
    });

    try {
      final probe = await _service.runPerformanceProbe(iterations: 1);
      final status = await _service.getEngineStatus();
      if (!mounted) {
        return;
      }

      final ok = probe['ok'] as bool? ?? false;
      final details = probe['details']?.toString() ?? '';
      final msPerInference = probe['msPerInference'];

      setState(() {
        _engineStatus = status;
        _validationMessage = ok
            ? 'Model validation passed. ms/inference: ${msPerInference ?? 'n/a'}'
            : 'Validation failed. ${details.isNotEmpty ? details : 'Check engine status error below.'}';
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? 'Model validation failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _validatingModel = false;
        });
      }
    }
  }

  Future<void> _resetEngine() async {
    try {
      await _service.resetEngine();
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model engine reset.')),
      );
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? 'Failed to reset model engine.';
      });
    }
  }

  void _applyPreset({
    required int maxTokens,
    required int timeoutMs,
    required String systemPrompt,
  }) {
    setState(() {
      _maxTokensController.text = maxTokens.toString();
      _timeoutMsController.text = timeoutMs.toString();
      _systemPromptController.text = systemPrompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metadata = _metadata;
    final engineStatus = _engineStatus;
    final config = _generationConfig;
    final selectedAt = (metadata?.lastSelectedAtMillis ?? 0) > 0
        ? DateTime.fromMillisecondsSinceEpoch(metadata!.lastSelectedAtMillis)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Selection'),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Model',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          metadata?.path.isNotEmpty == true
                              ? metadata!.path
                              : 'No model selected',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Size: ${((metadata?.sizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB',
                        ),
                        Text(
                          'Last selected: ${selectedAt?.toLocal().toString() ?? 'n/a'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (engineStatus != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Engine Status',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text('Loaded: ${engineStatus.loaded ? 'yes' : 'no'}'),
                          Text('Inferences: ${engineStatus.totalInferenceCount}'),
                          Text(
                            'Last inference: ${engineStatus.lastInferenceDurationMs} ms',
                          ),
                          Text(
                            'Avg inference: ${engineStatus.avgInferenceDurationMs} ms',
                          ),
                          if (engineStatus.lastEngineError.trim().isNotEmpty)
                            Text(
                              'Last error: ${engineStatus.lastEngineError}',
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _updatingModelPath ? null : _pickAndSetModel,
                    icon: _updatingModelPath
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    label: const Text('Pick .gguf model file'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _validatingModel ? null : _validateSelectedModel,
                          icon: _validatingModel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.verified_rounded),
                          label: const Text('Validate Model'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetEngine,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reset Engine'),
                        ),
                      ),
                    ],
                  ),
                  if (_validationMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _validationMessage!,
                      style: const TextStyle(color: Color(0xFF0B6E4F)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Model Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyPreset(
                          maxTokens: 128,
                          timeoutMs: 60000,
                          systemPrompt:
                              'You are a concise tutor. Give short, direct answers with one example.',
                        ),
                        child: const Text('Fast'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyPreset(
                          maxTokens: 256,
                          timeoutMs: 120000,
                          systemPrompt:
                              'You are a helpful tutor. Explain clearly with step-by-step reasoning when needed.',
                        ),
                        child: const Text('Balanced'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyPreset(
                          maxTokens: 512,
                          timeoutMs: 240000,
                          systemPrompt:
                              'You are an expert tutor. Provide detailed explanations and structured steps.',
                        ),
                        child: const Text('Deep Explain'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _maxTokensController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max output tokens',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeoutMsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Timeout (ms)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _systemPromptController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'System prompt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _updatingConfig ? null : _saveGenerationConfig,
                    icon: _updatingConfig
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.tune_rounded),
                    label: const Text('Save Model Configuration'),
                  ),
                  if (config != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Active: ${config.maxTokens} tokens, ${config.timeoutMs} ms timeout',
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
