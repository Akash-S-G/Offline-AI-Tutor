class CurriculumGrade {
  const CurriculumGrade({
    required this.grade,
    required this.subjects,
  });

  final int grade;
  final List<CurriculumSubject> subjects;
}

class CurriculumSubject {
  const CurriculumSubject({
    required this.name,
    required this.grade,
    required this.chapters,
  });

  final String name;
  final int grade;
  final List<CurriculumChapter> chapters;
}

class CurriculumChapter {
  const CurriculumChapter({
    required this.packId,
    required this.title,
    required this.subject,
    required this.grade,
    required this.rootPath,
    required this.summary,
    required this.language,
  });

  final String packId;
  final String title;
  final String subject;
  final int grade;
  final String rootPath;
  final String summary;
  final String language;
}
