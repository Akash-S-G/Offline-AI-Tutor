import 'package:flutter/material.dart';

import '../../guided_runtime/engine/guided_experiment_engine.dart';
import '../../investigation/comparison/trial_comparison_engine.dart';
import '../../investigation/conclusions/conclusion_engine.dart';
import '../../investigation/trials/experiment_trial_manager.dart';
import '../analytics/assessment_analytics.dart';
import '../engine/assessment_engine.dart';
import '../engine/learning_outcome_evaluator.dart';
import '../models/assessment_result.dart';
import '../models/assessment_question.dart';
import '../models/experiment_assessment.dart';
import '../models/experiment_lab_report.dart';
import '../models/learning_outcome.dart';
import '../models/learning_outcome_result.dart';
import '../reports/lab_report_builder.dart';
import '../reports/report_exporter.dart';

class ReportPanel extends StatefulWidget {
  final GuidedExperimentEngine? guidedEngine;
  final ExperimentTrialManager? trialManager;
  final TrialComparisonEngine? comparisonEngine;
  final ConclusionEngine? conclusionEngine;
  final ExperimentAssessment assessment;
  final List<LearningOutcome> learningOutcomes;
  final AssessmentAnalytics analytics;
  final ValueChanged<AssessmentResult>? onAssessmentComplete;
  final ValueChanged<List<LearningOutcomeResult>>? onOutcomesEvaluated;
  final ValueChanged<String>? onFeedback;

  const ReportPanel({
    super.key,
    required this.guidedEngine,
    required this.trialManager,
    required this.comparisonEngine,
    required this.conclusionEngine,
    required this.assessment,
    required this.learningOutcomes,
    required this.analytics,
    this.onAssessmentComplete,
    this.onOutcomesEvaluated,
    this.onFeedback,
  });

  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _answers = {};
  AssessmentResult? _result;
  ExperimentLabReport? _report;
  List<LearningOutcomeResult> _outcomes = const [];
  String? _jsonPreview;
  int? _pdfBytes;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.assessment.questions;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _Header(
          title: widget.assessment.title,
          description: widget.assessment.description,
          score: _result?.score,
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          const Text('No assessment questions configured.')
        else
          ...questions.map(_questionCard),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: questions.isEmpty ? null : _evaluate,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Submit Assessment'),
            ),
            OutlinedButton.icon(
              onPressed: _result == null ? null : _generateReport,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate Report'),
            ),
            OutlinedButton.icon(
              onPressed: _report == null ? null : _exportJson,
              icon: const Icon(Icons.data_object),
              label: const Text('JSON'),
            ),
            OutlinedButton.icon(
              onPressed: _report == null ? null : _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
            ),
          ],
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          _ResultCard(result: _result!),
        ],
        if (_outcomes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _OutcomeCard(outcomes: _outcomes),
        ],
        if (_report != null) ...[
          const SizedBox(height: 12),
          _ReportSummary(report: _report!, pdfBytes: _pdfBytes),
        ],
        if (_jsonPreview != null) ...[
          const SizedBox(height: 12),
          Text(
            _jsonPreview!,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _questionCard(AssessmentQuestion question) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.prompt,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (question.type == AssessmentQuestionType.multipleChoice ||
                question.type == AssessmentQuestionType.trueFalse)
              ..._optionsFor(question).map((option) {
                final selected = _answers[question.id] == option;
                return InkWell(
                  onTap: () => setState(() => _answers[question.id] = option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(option)),
                      ],
                    ),
                  ),
                );
              })
            else
              TextField(
                controller: _controllerFor(question.id),
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your response',
                ),
                onChanged: (value) => _answers[question.id] = value,
              ),
          ],
        ),
      ),
    );
  }

  List<String> _optionsFor(AssessmentQuestion question) {
    if (question.type == AssessmentQuestionType.trueFalse) {
      return const ['True', 'False'];
    }
    return question.options;
  }

  TextEditingController _controllerFor(String id) {
    return _controllers.putIfAbsent(id, TextEditingController.new);
  }

  void _evaluate() {
    final result = AssessmentEngine(
      analytics: widget.analytics,
    ).evaluate(assessment: widget.assessment, answers: _answers);
    final outcomes = LearningOutcomeEvaluator(analytics: widget.analytics)
        .evaluate(
          outcomes: widget.learningOutcomes,
          assessmentResult: result,
          missionCompleted:
              widget.guidedEngine?.state.missionCompleted ?? false,
          completedTrials: widget.trialManager?.completedTrialCount ?? 0,
        );
    setState(() {
      _result = result;
      _outcomes = outcomes;
    });
    widget.onAssessmentComplete?.call(result);
    widget.onOutcomesEvaluated?.call(outcomes);
    widget.onFeedback?.call('Assessment evaluated');
  }

  void _generateReport() {
    final trials = widget.trialManager?.trials ?? const [];
    final comparisons =
        widget.comparisonEngine?.compareSeries(trials) ?? const [];
    final conclusion =
        widget.conclusionEngine?.generate(
          trials: trials,
          comparisons: comparisons,
        ) ??
        '';
    final report = LabReportBuilder(analytics: widget.analytics).build(
      title: widget.guidedEngine?.mission?.title ?? widget.assessment.title,
      mission: widget.guidedEngine?.mission,
      trials: trials,
      comparisons: comparisons,
      conclusion: conclusion,
      assessmentResult: _result,
      learningOutcomes: _outcomes,
    );
    setState(() => _report = report);
    widget.onFeedback?.call('Lab report generated');
  }

  void _exportJson() {
    final report = _report;
    if (report == null) return;
    setState(() => _jsonPreview = ReportExporter().exportJson(report));
    widget.onFeedback?.call('Report JSON generated');
  }

  void _exportPdf() {
    final report = _report;
    if (report == null) return;
    final bytes = ReportExporter().exportPdf(report);
    setState(() => _pdfBytes = bytes.length);
    widget.onFeedback?.call('Report PDF generated');
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String description;
  final double? score;

  const _Header({required this.title, required this.description, this.score});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description),
            ],
            if (score != null) ...[
              const SizedBox(height: 8),
              Text('Score: ${score!.toStringAsFixed(1)}%'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AssessmentResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: result.passed
          ? const Color(0xFFECFDF5)
          : const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(result.passed ? 'Assessment Passed' : 'Needs Review'),
      subtitle: Text(result.feedback),
      trailing: Text('${result.score.toStringAsFixed(0)}%'),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  final List<LearningOutcomeResult> outcomes;

  const _OutcomeCard({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Outcomes',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...outcomes.map((outcome) {
              return Text('${outcome.outcomeId}: ${outcome.status.name}');
            }),
          ],
        ),
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final ExperimentLabReport report;
  final int? pdfBytes;

  const _ReportSummary({required this.report, this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_turned_in_outlined),
        title: Text(report.title),
        subtitle: Text(
          'Trials ${report.trials.length} | Score ${report.assessmentResult?.score.toStringAsFixed(1) ?? 'n/a'}%',
        ),
        trailing: pdfBytes == null ? null : Text('${pdfBytes!} B'),
      ),
    );
  }
}
