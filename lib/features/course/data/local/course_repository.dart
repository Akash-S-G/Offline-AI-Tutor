import 'package:sqflite/sqflite.dart';

import '../../domain/course_tree.dart';
import 'app_database.dart';

class CourseRepository {
  CourseRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

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
      {'id': 'sub_comp_10', 'course_id': 'course_10', 'name': 'Computer (Optional)'},
    ];

    for (var grade = 6; grade <= 9; grade += 1) {
      final gradeSubjects = _upperSubjects;
      for (final name in gradeSubjects) {
        final idName = name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');
        subjects.add(
          <String, String>{
            'id': 'sub_${idName}_$grade',
            'course_id': 'course_$grade',
            'name': name,
          },
        );
      }
    }

    final chapters = <Map<String, String>>[
      {
        'id': 'chap_linear_eq',
        'subject_id': 'sub_math_10',
        'title': 'Linear Equations',
        'summary': 'Solve one-variable equations and word problems using balancing steps.',
      },
      {
        'id': 'chap_quad_eq_10',
        'subject_id': 'sub_math_10',
        'title': 'Quadratic Equations',
        'summary': 'Factorization and formula-based methods for solving quadratic equations.',
      },
      {
        'id': 'chap_trigonometry_10',
        'subject_id': 'sub_math_10',
        'title': 'Introduction to Trigonometry',
        'summary': 'Understand sine, cosine, tangent and apply identities to simple problems.',
      },
      {
        'id': 'chap_chemical_rxn',
        'subject_id': 'sub_sci_10',
        'title': 'Chemical Reactions',
        'summary': 'Understand reaction types, balancing equations, and real-world examples.',
      },
      {
        'id': 'chap_life_processes_10',
        'subject_id': 'sub_sci_10',
        'title': 'Life Processes',
        'summary': 'Study nutrition, respiration, transport and excretion in living organisms.',
      },
      {
        'id': 'chap_light_10',
        'subject_id': 'sub_sci_10',
        'title': 'Light Reflection and Refraction',
        'summary': 'Learn image formation with mirrors and lenses using ray diagrams.',
      },
      {
        'id': 'chap_nationalism_10',
        'subject_id': 'sub_soc_10',
        'title': 'Rise of Nationalism in Europe',
        'summary': 'Understand key events and ideas that shaped nationalism in Europe.',
      },
      {
        'id': 'chap_resources_10',
        'subject_id': 'sub_soc_10',
        'title': 'Resources and Development',
        'summary': 'Explore different types of resources, their use and conservation.',
      },
      {
        'id': 'chap_prose_10',
        'subject_id': 'sub_eng_10',
        'title': 'Reading Comprehension and Prose',
        'summary': 'Build understanding, vocabulary and analytical reading skills.',
      },
      {
        'id': 'chap_grammar_10',
        'subject_id': 'sub_eng_10',
        'title': 'Grammar and Writing Skills',
        'summary': 'Practice sentence structure, tenses, and short-form writing.',
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

        chapters.add(
          <String, String>{
            'id': 'chap_${idName}_foundations_$grade',
            'subject_id': subjectId,
            'title': '$name Foundations',
            'summary':
                'Core $name concepts and examples for Class $grade learners.',
          },
        );
      }
    }

    chapters.addAll(
      <Map<String, String>>[
        {
          'id': 'chap_kannada_10',
          'subject_id': 'sub_kan_10',
          'title': 'Kannada Language Skills',
          'summary': 'Reading comprehension, grammar, and writing practice in Kannada.',
        },
        {
          'id': 'chap_computer_10',
          'subject_id': 'sub_comp_10',
          'title': 'Computer Fundamentals',
          'summary': 'Basic computer operations, internet safety, and productivity skills.',
        },
      ],
    );

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

  Future<List<Course>> getCourses() async {
    final db = await _database.database;
    final rows = await db.query('courses', orderBy: 'name ASC');

    final all = rows
        .map(
          (row) => Course(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
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

    return filtered;
  }

  Future<List<Subject>> getSubjects(String courseId) async {
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
      return all;
    }

    final allowedNames = _upperSubjects;
    final allowedSet = allowedNames.toSet();
    final filtered = all.where((subject) => allowedSet.contains(subject.name)).toList();

    filtered.sort((a, b) {
      final ai = allowedNames.indexOf(a.name);
      final bi = allowedNames.indexOf(b.name);
      return ai.compareTo(bi);
    });

    return filtered;
  }

  Future<List<Chapter>> getChapters(String subjectId) async {
    final db = await _database.database;
    final rows = await db.query(
      'chapters',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'title ASC',
    );

    return rows
        .map(
          (row) => Chapter(
            id: row['id'] as String,
            subjectId: row['subject_id'] as String,
            title: row['title'] as String,
            summary: row['summary'] as String,
          ),
        )
        .toList();
  }

  Future<List<Chapter>> getAllChapters() async {
    final db = await _database.database;
    final rows = await db.query('chapters', orderBy: 'title ASC');

    return rows
        .map(
          (row) => Chapter(
            id: row['id'] as String,
            subjectId: row['subject_id'] as String,
            title: row['title'] as String,
            summary: row['summary'] as String,
          ),
        )
        .toList();
  }
}
