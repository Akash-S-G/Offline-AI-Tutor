/// Educational data models for offline learning system.
/// 
/// Defines all models for:
/// - Curriculum structure (grades, subjects, chapters, concepts)
/// - Quizzes and flashcards
/// - Educational pack metadata
/// - Learner progress tracking

/// Grade model representing a school year level.
class GradeModel {
  final int? id;
  final String name;
  final int gradeNumber;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  GradeModel({
    this.id,
    required this.name,
    required this.gradeNumber,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gradeNumber': gradeNumber,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      gradeNumber: map['gradeNumber'] as int,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class SubjectModel {
  final int? id;
  final int gradeId;
  final String name;
  final String? description;
  final String? icon;
  final int? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectModel({
    this.id,
    required this.gradeId,
    required this.name,
    this.description,
    this.icon,
    this.colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gradeId': gradeId,
      'name': name,
      'description': description,
      'icon': icon,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as int?,
      gradeId: map['gradeId'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      colorHex: map['colorHex'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class ChapterModel {
  final int? id;
  final int subjectId;
  final String name;
  final int sequenceNumber;
  final String? summary;
  final String? content;
  final int? estimatedReadingMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChapterModel({
    this.id,
    required this.subjectId,
    required this.name,
    required this.sequenceNumber,
    this.summary,
    this.content,
    this.estimatedReadingMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'sequenceNumber': sequenceNumber,
      'summary': summary,
      'content': content,
      'estimatedReadingMinutes': estimatedReadingMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChapterModel.fromMap(Map<String, dynamic> map) {
    return ChapterModel(
      id: map['id'] as int?,
      subjectId: map['subjectId'] as int,
      name: map['name'] as String,
      sequenceNumber: map['sequenceNumber'] as int,
      summary: map['summary'] as String?,
      content: map['content'] as String?,
      estimatedReadingMinutes: map['estimatedReadingMinutes'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class ConceptModel {
  final int? id;
  final int chapterId;
  final String name;
  final int sequenceNumber;
  final String? definition;
  final String? examples;
  final String? relatedConcepts; // JSON array of related concept IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  ConceptModel({
    this.id,
    required this.chapterId,
    required this.name,
    required this.sequenceNumber,
    this.definition,
    this.examples,
    this.relatedConcepts,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'name': name,
      'sequenceNumber': sequenceNumber,
      'definition': definition,
      'examples': examples,
      'relatedConcepts': relatedConcepts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ConceptModel.fromMap(Map<String, dynamic> map) {
    return ConceptModel(
      id: map['id'] as int?,
      chapterId: map['chapterId'] as int,
      name: map['name'] as String,
      sequenceNumber: map['sequenceNumber'] as int,
      definition: map['definition'] as String?,
      examples: map['examples'] as String?,
      relatedConcepts: map['relatedConcepts'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class QuizModel {
  final int? id;
  final int chapterId;
  final String title;
  final String? description;
  final int sequenceNumber;
  final List<QuizQuestion> questions;
  final int passingScorePercent;
  final int maxAttempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizModel({
    this.id,
    required this.chapterId,
    required this.title,
    this.description,
    required this.sequenceNumber,
    required this.questions,
    this.passingScorePercent = 70,
    this.maxAttempts = 3,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'title': title,
      'description': description,
      'sequenceNumber': sequenceNumber,
      'questions': questions.toString(), // Serialized for storage
      'passingScorePercent': passingScorePercent,
      'maxAttempts': maxAttempts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] as int?,
      chapterId: map['chapterId'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      sequenceNumber: map['sequenceNumber'] as int,
      questions: [], // Should be loaded separately
      passingScorePercent: map['passingScorePercent'] as int? ?? 70,
      maxAttempts: map['maxAttempts'] as int? ?? 3,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class QuizQuestion {
  final int? id;
  final int quizId;
  final int sequenceNumber;
  final String question;
  final String type; // "mcq", "fill-blank", "match", "sequence"
  final List<String> options; // For MCQ
  final String correctAnswer;
  final String? explanation;
  final int points;

  QuizQuestion({
    this.id,
    required this.quizId,
    required this.sequenceNumber,
    required this.question,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    this.points = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'sequenceNumber': sequenceNumber,
      'question': question,
      'type': type,
      'options': options.toString(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int?,
      quizId: map['quizId'] as int,
      sequenceNumber: map['sequenceNumber'] as int,
      question: map['question'] as String,
      type: map['type'] as String,
      options: [], // Parse from stored string
      correctAnswer: map['correctAnswer'] as String,
      explanation: map['explanation'] as String?,
      points: map['points'] as int? ?? 1,
    );
  }
}

class FlashcardModel {
  final int? id;
  final int chapterId;
  final String term;
  final String definition;
  final String? example;
  final int sequenceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardModel({
    this.id,
    required this.chapterId,
    required this.term,
    required this.definition,
    this.example,
    required this.sequenceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'term': term,
      'definition': definition,
      'example': example,
      'sequenceNumber': sequenceNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as int?,
      chapterId: map['chapterId'] as int,
      term: map['term'] as String,
      definition: map['definition'] as String,
      example: map['example'] as String?,
      sequenceNumber: map['sequenceNumber'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class EducationalPackModel {
  final int? id;
  final String packId; // Unique identifier (e.g., "nutrition_in_plants")
  final String name;
  final String? description;
  final String version;
  final String localPath; // Path to extracted pack contents
  final String syncState; // "synced", "pending", "failed", "cached"
  final double downloadProgress; // 0.0 to 1.0
  final int? gradeId;
  final int? subjectId;
  final int totalChapters;
  final int downloadedChapters;
  final DateTime? lastSyncedAt;
  final DateTime? nextSyncDueAt;
  final bool isOfflineAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  EducationalPackModel({
    this.id,
    required this.packId,
    required this.name,
    this.description,
    required this.version,
    required this.localPath,
    this.syncState = 'cached',
    this.downloadProgress = 0.0,
    this.gradeId,
    this.subjectId,
    this.totalChapters = 0,
    this.downloadedChapters = 0,
    this.lastSyncedAt,
    this.nextSyncDueAt,
    this.isOfflineAvailable = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packId': packId,
      'name': name,
      'description': description,
      'version': version,
      'localPath': localPath,
      'syncState': syncState,
      'downloadProgress': downloadProgress,
      'gradeId': gradeId,
      'subjectId': subjectId,
      'totalChapters': totalChapters,
      'downloadedChapters': downloadedChapters,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'nextSyncDueAt': nextSyncDueAt?.toIso8601String(),
      'isOfflineAvailable': isOfflineAvailable ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EducationalPackModel.fromMap(Map<String, dynamic> map) {
    return EducationalPackModel(
      id: map['id'] as int?,
      packId: map['packId'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      version: map['version'] as String,
      localPath: map['localPath'] as String,
      syncState: map['syncState'] as String? ?? 'cached',
      downloadProgress: map['downloadProgress'] as double? ?? 0.0,
      gradeId: map['gradeId'] as int?,
      subjectId: map['subjectId'] as int?,
      totalChapters: map['totalChapters'] as int? ?? 0,
      downloadedChapters: map['downloadedChapters'] as int? ?? 0,
      lastSyncedAt: map['lastSyncedAt'] != null ? DateTime.parse(map['lastSyncedAt'] as String) : null,
      nextSyncDueAt: map['nextSyncDueAt'] != null ? DateTime.parse(map['nextSyncDueAt'] as String) : null,
      isOfflineAvailable: (map['isOfflineAvailable'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class LearnerProgressModel {
  final int? id;
  final int chapterId;
  final String completionState; // "not-started", "in-progress", "completed"
  final int readingProgressPercent; // 0-100
  final int? quizAttempts;
  final int? quizBestScore;
  final int? flashcardsReviewed;
  final DateTime? lastAccessedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearnerProgressModel({
    this.id,
    required this.chapterId,
    this.completionState = 'not-started',
    this.readingProgressPercent = 0,
    this.quizAttempts,
    this.quizBestScore,
    this.flashcardsReviewed,
    this.lastAccessedAt,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'completionState': completionState,
      'readingProgressPercent': readingProgressPercent,
      'quizAttempts': quizAttempts,
      'quizBestScore': quizBestScore,
      'flashcardsReviewed': flashcardsReviewed,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearnerProgressModel.fromMap(Map<String, dynamic> map) {
    return LearnerProgressModel(
      id: map['id'] as int?,
      chapterId: map['chapterId'] as int,
      completionState: map['completionState'] as String? ?? 'not-started',
      readingProgressPercent: map['readingProgressPercent'] as int? ?? 0,
      quizAttempts: map['quizAttempts'] as int?,
      quizBestScore: map['quizBestScore'] as int?,
      flashcardsReviewed: map['flashcardsReviewed'] as int?,
      lastAccessedAt: map['lastAccessedAt'] != null ? DateTime.parse(map['lastAccessedAt'] as String) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
