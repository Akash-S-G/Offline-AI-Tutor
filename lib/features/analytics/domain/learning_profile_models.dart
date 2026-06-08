class LearningProfile {
  final int studyStreakDays;
  final int completedChapters;
  final int totalLearningTimeMinutes;
  final int experimentsCompleted;
  final double averageQuizAccuracy;
  final List<StudentStrength> strengths;
  final List<StudentWeakness> weaknesses;
  final List<LearningRecommendation> recommendations;
  final List<StudentAchievement> achievements;

  LearningProfile({
    required this.studyStreakDays,
    required this.completedChapters,
    required this.totalLearningTimeMinutes,
    required this.experimentsCompleted,
    required this.averageQuizAccuracy,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.achievements,
  });
}

class StudentStrength {
  final String topic;
  final String description;

  StudentStrength(this.topic, this.description);
}

class StudentWeakness {
  final String topic;
  final String description;
  final String suggestedAction;

  StudentWeakness(this.topic, this.description, this.suggestedAction);
}

class LearningRecommendation {
  final String title;
  final String description;
  final String actionRoute; // e.g., 'quiz', 'experiment', 'chapter'
  final String targetId; // chapterId or experimentId

  LearningRecommendation({
    required this.title,
    required this.description,
    required this.actionRoute,
    required this.targetId,
  });
}

class StudentAchievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime earnedAt;

  StudentAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.earnedAt,
  });
}

class ChapterAnalytics {
  final String chapterId;
  final bool hasRead;
  final int quizAttempts;
  final double latestQuizScore;
  final int experimentsCompleted;
  final int tutorQuestionsAsked;

  ChapterAnalytics({
    required this.chapterId,
    required this.hasRead,
    required this.quizAttempts,
    required this.latestQuizScore,
    required this.experimentsCompleted,
    required this.tutorQuestionsAsked,
  });
}
