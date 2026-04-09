class Course {
  const Course({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class Subject {
  const Subject({
    required this.id,
    required this.courseId,
    required this.name,
  });

  final String id;
  final String courseId;
  final String name;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.summary,
  });

  final String id;
  final String subjectId;
  final String title;
  final String summary;
}
