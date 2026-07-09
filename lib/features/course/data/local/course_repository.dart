import 'package:sqflite/sqflite.dart';

import '../../../content_packs/data/local/content_pack_repository.dart';
import '../../../translation/application/content_localization_service.dart';
import '../../domain/course_tree.dart';
import 'app_database.dart';

class CourseRepository {
  CourseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final ContentLocalizationService _localizer = ContentLocalizationService();
  final ContentPackRepository _packRepository = ContentPackRepository();

  static const List<String> _upperSubjects = <String>[
    'Mathematics',
    'English',
    'Kannada',
    'Science',
    'Social Science',
    'Computer (Optional)',
  ];

  Future<void> ensureSeedData() async {
    final db = await _database.database;

    final batch = db.batch();

    const courses = <Map<String, String>>[
      {'id': 'course_6', 'name': 'Class 6'},
      {'id': 'course_7', 'name': 'Class 7'},
      {'id': 'course_8', 'name': 'Class 8'},
      {'id': 'course_9', 'name': 'Class 9'},
      {'id': 'course_10', 'name': 'Class 10'},
    ];

    final subjects = <Map<String, String>>[
      {'id': 'sub_math_10', 'course_id': 'course_10', 'name': 'Mathematics'},
      {'id': 'sub_sci_10', 'course_id': 'course_10', 'name': 'Science'},
      {'id': 'sub_soc_10', 'course_id': 'course_10', 'name': 'Social Science'},
      {'id': 'sub_eng_10', 'course_id': 'course_10', 'name': 'English'},
      {'id': 'sub_kan_10', 'course_id': 'course_10', 'name': 'Kannada'},
      {
        'id': 'sub_comp_10',
        'course_id': 'course_10',
        'name': 'Computer (Optional)',
      },
    ];

    for (var grade = 6; grade <= 9; grade += 1) {
      final gradeSubjects = _upperSubjects;
      for (final name in gradeSubjects) {
        final idName = name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
        subjects.add(<String, String>{
          'id': 'sub_${idName}_$grade',
          'course_id': 'course_$grade',
          'name': name,
        });
      }
    }

    final chapters = <Map<String, String>>[
      {
        'id': 'chap_linear_eq',
        'subject_id': 'sub_math_10',
        'title': 'Linear Equations',
        'summary':
            'Solve one-variable equations and word problems using balancing steps.',
      },
      {
        'id': 'chap_quad_eq_10',
        'subject_id': 'sub_math_10',
        'title': 'Quadratic Equations',
        'summary':
            'Factorization and formula-based methods for solving quadratic equations.',
      },
      {
        'id': 'chap_trigonometry_10',
        'subject_id': 'sub_math_10',
        'title': 'Introduction to Trigonometry',
        'summary':
            'Understand sine, cosine, tangent and apply identities to simple problems.',
      },
      {
        'id': 'chap_chemical_rxn',
        'subject_id': 'sub_sci_10',
        'title': 'Chemical Reactions',
        'summary':
            'Understand reaction types, balancing equations, and real-world examples.',
      },
      {
        'id': 'chap_life_processes_10',
        'subject_id': 'sub_sci_10',
        'title': 'Life Processes',
        'summary':
            'Study nutrition, respiration, transport and excretion in living organisms.',
      },
      {
        'id': 'chap_light_10',
        'subject_id': 'sub_sci_10',
        'title': 'Light Reflection and Refraction',
        'summary':
            'Learn image formation with mirrors and lenses using ray diagrams.',
      },
      {
        'id': 'chap_nationalism_10',
        'subject_id': 'sub_soc_10',
        'title': 'Rise of Nationalism in Europe',
        'summary':
            'Understand key events and ideas that shaped nationalism in Europe.',
      },
      {
        'id': 'chap_resources_10',
        'subject_id': 'sub_soc_10',
        'title': 'Resources and Development',
        'summary':
            'Explore different types of resources, their use and conservation.',
      },
      {
        'id': 'chap_prose_10',
        'subject_id': 'sub_eng_10',
        'title': 'Reading Comprehension and Prose',
        'summary':
            'Build understanding, vocabulary and analytical reading skills.',
      },
      {
        'id': 'chap_grammar_10',
        'subject_id': 'sub_eng_10',
        'title': 'Grammar and Writing Skills',
        'summary':
            'Practice sentence structure, tenses, and short-form writing.',
      },
    ];

    for (var grade = 6; grade <= 9; grade += 1) {
      final gradeSubjects = _upperSubjects;
      for (final name in gradeSubjects) {
        final idName = name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
        final subjectId = 'sub_${idName}_$grade';

        chapters.add(<String, String>{
          'id': 'chap_${idName}_foundations_$grade',
          'subject_id': subjectId,
          'title': '$name Foundations',
          'summary':
              'Core $name concepts and examples for Class $grade learners.',
        });
      }
    }

    chapters.addAll(<Map<String, String>>[
      {
        'id': 'chap_kannada_10',
        'subject_id': 'sub_kan_10',
        'title': 'Kannada Language Skills',
        'summary':
            'Reading comprehension, grammar, and writing practice in Kannada.',
      },
      {
        'id': 'chap_computer_10',
        'subject_id': 'sub_comp_10',
        'title': 'Computer Fundamentals',
        'summary':
            'Basic computer operations, internet safety, and productivity skills.',
      },
    ]);

    for (final course in courses) {
      batch.insert(
        'courses',
        course,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final subject in subjects) {
      batch.insert(
        'subjects',
        subject,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final chapter in chapters) {
      batch.insert(
        'chapters',
        chapter,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Course>> getCourses({String languageCode = 'en'}) async {
    final db = await _database.database;
    final rows = await db.query('courses', orderBy: 'name ASC');

    final all = rows
        .map(
          (row) => Course(id: row['id'] as String, name: row['name'] as String),
        )
        .toList();

    final filtered = all.where((course) {
      final match = RegExp(r'^course_(\d+)$').firstMatch(course.id);
      if (match == null) {
        return false;
      }
      final grade = int.tryParse(match.group(1) ?? '');
      return grade != null && grade >= 6 && grade <= 10;
    }).toList();

    filtered.sort((a, b) {
      final ga = int.parse(RegExp(r'\d+').firstMatch(a.id)!.group(0)!);
      final gb = int.parse(RegExp(r'\d+').firstMatch(b.id)!.group(0)!);
      return ga.compareTo(gb);
    });

    return _localizeCourses(filtered, languageCode);
  }

  Future<List<Subject>> getSubjects(
    String courseId, {
    String languageCode = 'en',
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'subjects',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'name ASC',
    );

    final all = rows
        .map(
          (row) => Subject(
            id: row['id'] as String,
            courseId: row['course_id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();

    final gradeMatch = RegExp(r'^course_(\d+)$').firstMatch(courseId);
    final grade = int.tryParse(gradeMatch?.group(1) ?? '');
    if (grade == null) {
      return _localizeSubjects(all, languageCode);
    }

    final merged = <String, Subject>{};
    for (final subject in all) {
      merged[_subjectKey(subject.name)] = subject;
    }

    final installedSubjects = await _installedPackSubjects(
      grade: grade,
      courseId: courseId,
    );
    for (final subject in installedSubjects) {
      merged.putIfAbsent(_subjectKey(subject.name), () => subject);
    }

    final subjects = merged.values.toList()
      ..sort((a, b) {
        final ai = _subjectSortIndex(a.name);
        final bi = _subjectSortIndex(b.name);
        if (ai != bi) {
          return ai.compareTo(bi);
        }
        return a.name.compareTo(b.name);
      });

    return _localizeSubjects(subjects, languageCode);
  }

  Future<List<Chapter>> getChapters(
    String subjectId, {
    String languageCode = 'en',
  }) async {
    final db = await _database.database;
    final subjectRows = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [subjectId],
      limit: 1,
    );
    String? subjectName;
    String? courseId;

    if (subjectRows.isNotEmpty) {
      final subjectRow = subjectRows.first;
      subjectName = subjectRow['name'] as String? ?? '';
      courseId = subjectRow['course_id'] as String? ?? '';
    } else {
      subjectName = _subjectNameFromSubjectId(subjectId);
      courseId = _courseIdFromSubjectId(subjectId);
    }

    final grade = courseId == null ? null : _gradeFromCourseId(courseId);

    final localChapters = <Chapter>[];
    if (grade != null && subjectName != null && subjectName.isNotEmpty) {
      final installedPackChapters = await _chaptersFromInstalledPacks(
        grade: grade,
        subjectName: subjectName,
        subjectId: subjectId,
      );
      localChapters.addAll(installedPackChapters);
    }

    if (subjectRows.isEmpty) {
      return _localizeChapters(localChapters, languageCode);
    }

    final rows = await db.query(
      'chapters',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'title ASC',
    );

    final chapters = rows
        .map(
          (row) => Chapter(
            id: row['id'] as String,
            subjectId: row['subject_id'] as String,
            title: row['title'] as String,
            summary: row['summary'] as String,
          ),
        )
        .toList();
    final merged = <String, Chapter>{};

    for (final chapter in localChapters) {
      merged[_chapterKey(chapter)] = chapter;
    }

    for (final chapter in chapters) {
      merged.putIfAbsent(_chapterKey(chapter), () => chapter);
    }

    final mergedChapters = merged.values.toList()
      ..sort((a, b) {
        final titleCompare = a.title.compareTo(b.title);
        if (titleCompare != 0) {
          return titleCompare;
        }
        return a.id.compareTo(b.id);
      });

    return _localizeChapters(mergedChapters, languageCode);
  }

  Future<List<Chapter>> _chaptersFromInstalledPacks({
    required int grade,
    required String subjectName,
    required String subjectId,
  }) async {
    final packs = await _packRepository.listInstalledPacks();
    final normalizedSubject = _normalizeSubjectName(subjectName);
    final chapters = <Chapter>[];

    for (final pack in packs) {
      if (pack.gradeMin > grade || pack.gradeMax < grade) {
        continue;
      }

      if (_normalizeSubjectName(pack.subject) != normalizedSubject) {
        continue;
      }

      final title = _packTitle(pack);
      chapters.add(
        Chapter(
          id: pack.packId,
          subjectId: subjectId,
          title: title,
          summary: title,
        ),
      );
    }

    return chapters;
  }

  String _packTitle(dynamic pack) {
    final rawTitle = (pack.title as String?)?.trim() ?? '';
    if (rawTitle.isNotEmpty) {
      return _capitalize(rawTitle);
    }
    return 'Untitled Chapter';
  }

  int? _gradeFromCourseId(String courseId) {
    final match = RegExp(r'^course_(\d+)$').firstMatch(courseId);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  String _normalizeSubjectName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower == 'maths' || lower == 'mathematics') {
      return 'mathematics';
    }
    if (lower == 'science') {
      return 'science';
    }
    if (lower == 'english') {
      return 'english';
    }
    if (lower == 'kannada') {
      return 'kannada';
    }
    if (lower == 'social science' ||
        lower == 'social_science' ||
        lower == 'socialscience') {
      return 'social science';
    }
    return lower;
  }

  String _displaySubjectName(String name) {
    final normalized = name.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) {
      return '';
    }

    final lower = normalized.toLowerCase();
    if (lower == 'maths' || lower == 'mathematics') {
      return 'Mathematics';
    }
    if (lower == 'science') {
      return 'Science';
    }
    if (lower == 'english') {
      return 'English';
    }
    if (lower == 'kannada') {
      return 'Kannada';
    }
    if (lower == 'social science' || lower == 'socialscience') {
      return 'Social Science';
    }
    return _capitalize(normalized);
  }

  String _subjectKey(String name) {
    return _normalizeSubjectName(name);
  }

  String _chapterKey(Chapter chapter) {
    return '${chapter.subjectId}::${chapter.id}::${chapter.title}'
        .toLowerCase();
  }

  int _subjectSortIndex(String name) {
    final index = _upperSubjects.indexWhere(
      (subject) => _subjectKey(subject) == _subjectKey(name),
    );
    return index == -1 ? _upperSubjects.length : index;
  }

  String _subjectIdFromName(String subjectName, int grade) {
    final slug = _subjectKey(
      subjectName,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'sub_${slug}_$grade';
  }

  String? _subjectNameFromSubjectId(String subjectId) {
    final db = RegExp(r'^sub_(.+?)_(\d+)$').firstMatch(subjectId);
    if (db == null) {
      return null;
    }

    final slug = db.group(1)?.replaceAll('_', ' ').trim() ?? '';
    if (slug.isEmpty) {
      return null;
    }
    return _displaySubjectName(slug);
  }

  String? _courseIdFromSubjectId(String subjectId) {
    final match = RegExp(r'_(\d+)$').firstMatch(subjectId);
    if (match == null) {
      return null;
    }
    return 'course_${match.group(1)}';
  }

  Future<List<Subject>> _installedPackSubjects({
    required int grade,
    required String courseId,
  }) async {
    final packs = await _packRepository.listInstalledPacks();
    final subjects = <Subject>[];
    final seen = <String>{};

    for (final pack in packs) {
      if (pack.gradeMin > grade || pack.gradeMax < grade) {
        continue;
      }

      final subjectName = _displaySubjectName(pack.subject);
      if (subjectName.isEmpty) {
        continue;
      }

      final key = _subjectKey(subjectName);
      if (!seen.add(key)) {
        continue;
      }

      subjects.add(
        Subject(
          id: _subjectIdFromName(subjectName, grade),
          courseId: courseId,
          name: subjectName,
        ),
      );
    }

    return subjects;
  }

  String _capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return '';
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<List<Chapter>> getAllChapters({String languageCode = 'en'}) async {
    final db = await _database.database;
    final rows = await db.query('chapters', orderBy: 'title ASC');

    final chaptersById = <String, Chapter>{};
    for (final row in rows) {
      final chapter = Chapter(
        id: row['id'] as String,
        subjectId: row['subject_id'] as String,
        title: row['title'] as String,
        summary: row['summary'] as String,
      );
      chaptersById[chapter.id] = chapter;
    }

    final installedPacks = await _packRepository.listInstalledPacks();
    for (final pack in installedPacks) {
      final subjectName = _displaySubjectName(pack.subject);
      if (subjectName.isEmpty) {
        continue;
      }

      final grade = pack.gradeMin;
      final chapter = Chapter(
        id: pack.packId,
        subjectId: _subjectIdFromName(subjectName, grade),
        title: _packTitle(pack),
        summary: _packTitle(pack),
      );
      chaptersById[chapter.id] = chapter;
    }

    final chapters = chaptersById.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return _localizeChapters(chapters, languageCode);
  }

  Future<List<Course>> _localizeCourses(
    List<Course> courses,
    String languageCode,
  ) async {
    if (languageCode != 'kn') {
      return courses;
    }
    return _localizer.localizeCourses(courses, targetLanguage: languageCode);
  }

  Future<List<Subject>> _localizeSubjects(
    List<Subject> subjects,
    String languageCode,
  ) async {
    if (languageCode != 'kn') {
      return subjects;
    }
    return _localizer.localizeSubjects(subjects, targetLanguage: languageCode);
  }

  Future<List<Chapter>> _localizeChapters(
    List<Chapter> chapters,
    String languageCode,
  ) async {
    if (languageCode != 'kn') {
      return chapters;
    }
    return _localizer.localizeChapters(chapters, targetLanguage: languageCode);
  }
}
