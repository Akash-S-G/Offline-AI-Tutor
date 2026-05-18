import 'package:flutter/material.dart';
import '../application/offline_tutor_service.dart';
import '../models/educational_models.dart';
import 'educational_cards.dart';

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
      appBar: AppBar(
        title: Text(widget.concept.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Definition section
            if (widget.concept.definition != null) ...[
              Text(
                'Definition',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Text(
                  widget.concept.definition!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Examples section
            if (widget.concept.examples != null) ...[
              Text(
                'Examples',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  widget.concept.examples!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Ask Tutor section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ask the Tutor',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_showTutorInput) ...[
                      Text(
                        'Have a question about this topic?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showTutorInput = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Ask a Question'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _questionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Ask your question about ${widget.concept.name}...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _askTutor,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Get Help'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions section
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Show related concepts
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Related Topics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open notes or save for later
                    },
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Save'),
                  ),
                ),
              ],
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
