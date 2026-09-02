import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../builder/templates/experiment_templates.dart';
import '../../runtime/runtime_world.dart';
import '../../runtime/runtime_profiles.dart';
import '../../../../core/theme/idp_colors.dart';
import '../../../../core/widgets/idp_core_widgets.dart';

class TemplateCertificationScreen extends StatefulWidget {
  const TemplateCertificationScreen({super.key});

  @override
  State<TemplateCertificationScreen> createState() => _TemplateCertificationScreenState();
}

class _TemplateCertificationScreenState extends State<TemplateCertificationScreen> {
  final List<Map<String, dynamic>> _results = [];
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _runCertification();
  }

  Future<void> _runCertification() async {
    final List<Map<String, dynamic>> templatesToTest = List.from(ExperimentTemplates.allTemplates);
    try {
      final String jsonString = await rootBundle.loadString('assets/experiment_blueprints/water_cycle.json');
      templatesToTest.add(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (e) {
      print('Failed to load water_cycle.json: $e');
    }

    for (final template in templatesToTest) {
      final name = template['scene']?['name'] ?? 'Unknown';
      try {
        final world = RuntimeWorld();
        
        final scene = template['scene'] as Map<String, dynamic>;
        final metadata = template['metadata'] as Map<String, dynamic>? ?? {};

        world.initialize(
          variablesJson: (scene['variables'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          objectsJson: (scene['objects'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          rulesJson: (scene['rules'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          runtimeProfile: RuntimeProfile.general,
          curriculumMetadata: metadata,
        );

        world.start();

        for (int i = 0; i < 50; i++) {
          world.tick(0.1);
        }
        
        world.stop();
        world.dispose();

        setState(() {
          _results.add({
            'name': name,
            'status': 'PASS',
            'detail': 'Successfully ran 5s simulation',
            'error': false,
          });
        });
      } catch (e, stack) {
        setState(() {
          _results.add({
            'name': name,
            'status': 'FAIL',
            'detail': e.toString(),
            'error': true,
          });
        });
      }
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Template Certification Workspace', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(IDPSpacing.md),
              color: IDPColors.surfaceContainerLow,
              child: Row(
                children: [
                  if (_isRunning) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: IDPColors.primary),
                    ),
                    const SizedBox(width: IDPSpacing.sm),
                    Text('Running Certification...', style: IDPTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  ] else ...[
                    const Icon(Icons.check_circle_rounded, color: IDPColors.secondary),
                    const SizedBox(width: IDPSpacing.sm),
                    Text('Certification Complete', style: IDPTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  ],
                  const Spacer(),
                  Text(
                    '${_results.length} / ${ExperimentTemplates.allTemplates.length} processed',
                    style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(IDPSpacing.md),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isError = result['error'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: IDPSpacing.sm),
                    child: IDPCard(
                      child: Row(
                        children: [
                          Icon(
                            isError ? Icons.error_rounded : Icons.check_circle_rounded,
                            color: isError ? IDPColors.error : IDPColors.secondary,
                          ),
                          const SizedBox(width: IDPSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(result['name'], style: IDPTypography.titleSmall),
                                const SizedBox(height: IDPSpacing.xs / 2),
                                Text(
                                  result['detail'],
                                  style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: IDPSpacing.sm, vertical: IDPSpacing.xs),
                            decoration: BoxDecoration(
                              color: isError ? IDPColors.errorContainer : IDPColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(IDPRadius.sm),
                            ),
                            child: Text(
                              result['status'],
                              style: IDPTypography.labelSmall.copyWith(
                                color: isError ? IDPColors.onErrorContainer : IDPColors.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

