import 'intent_detector.dart';

/// Persists conversational context across message turns.
///
/// Enables follow-up queries like "another one", "harder", "give hint"
/// to inherit the active intent, topic, and difficulty from the previous turn.
class SessionState {
  TutorIntent? activeIntent;
  String? activeTopic;
  String? activeChapter;
  String? activeDifficulty;
  String? lastQuizId;
  String? lastQuestionId;

  SessionState({
    this.activeIntent,
    this.activeTopic,
    this.activeChapter,
    this.activeDifficulty,
    this.lastQuizId,
    this.lastQuestionId,
  });

  /// Update state from a new detection result.
  void updateFromDetection(IntentDetectionResult result) {
    // Only update activeIntent for non-contextual intents.
    // Contextual intents (continue, repeat, harder) inherit the existing intent.
    if (!result.isContextual) {
      activeIntent = result.intent;
    }

    if (result.topic.isNotEmpty) {
      activeTopic = result.topic;
    }
    if (result.chapter != null && result.chapter!.isNotEmpty) {
      activeChapter = result.chapter;
    }
    if (result.difficulty != null && result.difficulty!.isNotEmpty) {
      activeDifficulty = result.difficulty;
    }
  }

  void setQuizContext({String? quizId, String? questionId}) {
    if (quizId != null) lastQuizId = quizId;
    if (questionId != null) lastQuestionId = questionId;
  }

  void clear() {
    activeIntent = null;
    activeTopic = null;
    activeDifficulty = null;
    lastQuizId = null;
    lastQuestionId = null;
  }

  @override
  String toString() =>
      'SessionState(intent=${activeIntent?.name}, topic=$activeTopic, '
      'chapter=$activeChapter, difficulty=$activeDifficulty, '
      'quizId=$lastQuizId, questionId=$lastQuestionId)';
}
