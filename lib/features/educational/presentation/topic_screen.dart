import 'package:flutter/material.dart';
import '../application/offline_tutor_service.dart';
import '../models/educational_models.dart';
import 'educational_cards.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';

/// Shows detailed information about a topic/concept
/// 
/// Displays:
/// - Concept definition
/// - Examples
/// - Related concepts
/// - Option to get tutoring on this topic
class TopicScreen extends StatefulWidget {
  final ConceptModel concept;

  const TopicScreen({
    Key? key,
    required this.concept,
  }) : super(key: key);

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final TextEditingController _questionController = TextEditingController();
  final OfflineTutorService _tutorService = OfflineTutorService();
  bool _showTutorInput = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: Text(widget.concept.name, style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IDPSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Definition section
            if (widget.concept.definition != null) ...[
              const IDPSectionHeader(title: 'Definition'),
              const SizedBox(height: IDPSpacing.sm),
              IDPCard(
                backgroundColor: IDPColors.primaryContainer.withValues(alpha: 0.4),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    widget.concept.definition!,
                    style: IDPTypography.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: IDPSpacing.lg),
            ],

            // Examples section
            if (widget.concept.examples != null) ...[
              const IDPSectionHeader(title: 'Examples'),
              const SizedBox(height: IDPSpacing.sm),
              IDPCard(
                backgroundColor: IDPColors.secondaryContainer.withValues(alpha: 0.4),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    widget.concept.examples!,
                    style: IDPTypography.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: IDPSpacing.lg),
            ],

            // Ask Tutor section
            IDPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: IDPColors.primaryContainer,
                        child: Icon(Icons.school_rounded, color: IDPColors.primary),
                      ),
                      const SizedBox(width: IDPSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Need Help?', style: IDPTypography.titleSmall),
                            Text('Ask AI Tutor about ${widget.concept.name}', style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IDPSpacing.md),
                  if (!_showTutorInput) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: IDPColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.defaultRadius)),
                        ),
                        onPressed: () {
                          setState(() {
                            _showTutorInput = true;
                          });
                        },
                        icon: const Icon(Icons.help_outline_rounded, color: IDPColors.primary),
                        label: Text('Ask a Question', style: IDPTypography.labelLarge.copyWith(color: IDPColors.primary)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _questionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ask your question about ${widget.concept.name}...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(IDPRadius.defaultRadius)),
                      ),
                    ),
                    const SizedBox(height: IDPSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showTutorInput = false;
                              _questionController.clear();
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: IDPSpacing.sm),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: IDPColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.defaultRadius)),
                          ),
                          onPressed: _isLoading ? null : _askTutor,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text('Get Help'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ask the tutor a question
  void _askTutor() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _tutorService.answerQuestion(question).then((response) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _showTutorInput = false;
        _questionController.clear();
      });

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate tutor response right now.')),
        );
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: EducationalResponseCard(
              title: widget.concept.name,
              explanation: response.explanation,
              keyPoints: response.keyPoints,
              examples: response.examples,
              relatedTopics: response.relatedConcepts,
              confidence: response.confidencePercent,
              onContinue: () => Navigator.pop(context),
              onRate: () {
                _tutorService.rateResponse(response.id, 5);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
              },
            ),
          );
        },
      );
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to contact offline tutor.')),
      );
    });
  }
}

