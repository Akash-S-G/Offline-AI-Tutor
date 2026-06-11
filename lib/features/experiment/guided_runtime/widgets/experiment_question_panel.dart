import 'package:flutter/material.dart';

import '../engine/guided_experiment_engine.dart';
import '../models/experiment_question.dart';

class ExperimentQuestionPanel extends StatefulWidget {
  final GuidedExperimentEngine engine;

  const ExperimentQuestionPanel({super.key, required this.engine});

  @override
  State<ExperimentQuestionPanel> createState() =>
      _ExperimentQuestionPanelState();
}

class _ExperimentQuestionPanelState extends State<ExperimentQuestionPanel> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _results = {};
  final Map<String, String> _selected = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final questions = widget.engine.state.mission?.questions ?? const [];
        if (questions.isEmpty) {
          return const Center(child: Text('No questions for this mission.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) => _QuestionCard(
            question: questions[index],
            selected: _selected[questions[index].id],
            result: _results[questions[index].id],
            controller: _controllerFor(questions[index].id),
            onSelected: (answer) {
              setState(() => _selected[questions[index].id] = answer);
            },
            onSubmit: (answer) {
              final result = widget.engine.answerQuestion(
                questions[index].id,
                answer,
              );
              setState(() => _results[questions[index].id] = result);
            },
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: questions.length,
        );
      },
    );
  }

  TextEditingController _controllerFor(String id) {
    return _controllers.putIfAbsent(id, TextEditingController.new);
  }
}

class _QuestionCard extends StatelessWidget {
  final ExperimentQuestion question;
  final String? selected;
  final bool? result;
  final TextEditingController controller;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onSubmit;

  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.result,
    required this.controller,
    required this.onSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final answer = question.type == ExperimentQuestionType.shortAnswer
        ? controller.text
        : selected;
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
            Text(
              question.question,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (question.type == ExperimentQuestionType.shortAnswer)
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write your answer',
                ),
              )
            else
              ..._optionsFor(question).map((option) {
                final isSelected = selected == option;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(option)),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: answer == null || answer.trim().isEmpty
                  ? null
                  : () => onSubmit(answer),
              child: const Text('Submit Answer'),
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Text(
                result! ? 'Correct' : 'Try again',
                style: TextStyle(
                  color: result! ? const Color(0xFF16A34A) : Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (question.explanation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(question.explanation),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _optionsFor(ExperimentQuestion question) {
    if (question.type == ExperimentQuestionType.trueFalse) {
      return const ['True', 'False'];
    }
    return question.options;
  }
}
