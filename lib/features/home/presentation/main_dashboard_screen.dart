import 'package:flutter/material.dart';

import '../../chat/presentation/chapter_chat_screen.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../../p2p/presentation/p2p_screen.dart';
import '../../progress/presentation/progress_dashboard_screen.dart';
import '../../rag/presentation/screens/document_rag_ingestion_screen.dart';
import '../../settings/presentation/model_selection_screen.dart';
import 'learning_materials_screen.dart';
import 'math_simulator_screen.dart';
import 'quiz_assessment_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({
    required this.courseRepository,
    super.key,
  });

  final CourseRepository courseRepository;

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  List<Course> _courses = const [];
  List<Subject> _subjects = const [];
  List<Chapter> _chapters = const [];

  Course? _selectedCourse;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final courses = await widget.courseRepository.getCourses();
    if (courses.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final selectedCourse = courses.first;
    final subjects = await widget.courseRepository.getSubjects(selectedCourse.id);
    final selectedSubject = subjects.isEmpty ? null : subjects.first;
    final chapters = selectedSubject == null
        ? <Chapter>[]
        : await widget.courseRepository.getChapters(selectedSubject.id);

    setState(() {
      _courses = courses;
      _selectedCourse = selectedCourse;
      _subjects = subjects;
      _selectedSubject = selectedSubject;
      _chapters = chapters;
      _selectedChapter = chapters.isEmpty ? null : chapters.first;
      _loading = false;
    });
  }

  Future<void> _onCourseChanged(Course? course) async {
    if (course == null) return;

    final subjects = await widget.courseRepository.getSubjects(course.id);
    final selectedSubject = subjects.isEmpty ? null : subjects.first;
    final chapters = selectedSubject == null
        ? <Chapter>[]
        : await widget.courseRepository.getChapters(selectedSubject.id);

    setState(() {
      _selectedCourse = course;
      _subjects = subjects;
      _selectedSubject = selectedSubject;
      _chapters = chapters;
      _selectedChapter = chapters.isEmpty ? null : chapters.first;
    });
  }

  Future<void> _onSubjectChanged(Subject? subject) async {
    if (subject == null) return;

    final chapters = await widget.courseRepository.getChapters(subject.id);

    setState(() {
      _selectedSubject = subject;
      _chapters = chapters;
      _selectedChapter = chapters.isEmpty ? null : chapters.first;
    });
  }

  void _onChapterChanged(Chapter? chapter) {
    if (chapter == null) return;
    setState(() {
      _selectedChapter = chapter;
    });
  }

  void _navigateTutor() {
    final course = _selectedCourse;
    final subject = _selectedSubject;
    final chapter = _selectedChapter;

    if (course == null || subject == null || chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter first')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterChatScreen(
          course: course,
          subject: subject,
          chapter: chapter,
        ),
      ),
    );
  }

  void _navigateMaterials() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningMaterialsScreen(
          courseRepository: widget.courseRepository,
        ),
      ),
    );
  }

  void _navigateQuiz() {
    final course = _selectedCourse;
    final subject = _selectedSubject;
    final chapter = _selectedChapter;

    if (course == null || subject == null || chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter first')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAssessmentScreen(
          course: course,
          subject: subject,
          chapter: chapter,
        ),
      ),
    );
  }

  void _navigateP2PForTest() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => P2PScreen(
          courseRepository: widget.courseRepository,
        ),
      ),
    );
  }

  Course? _selectedCourseInList() {
    final selectedId = _selectedCourse?.id;
    if (selectedId == null) {
      return null;
    }
    for (final course in _courses) {
      if (course.id == selectedId) {
        return course;
      }
    }
    return null;
  }

  Subject? _selectedSubjectInList() {
    final selectedId = _selectedSubject?.id;
    if (selectedId == null) {
      return null;
    }
    for (final subject in _subjects) {
      if (subject.id == selectedId) {
        return subject;
      }
    }
    return null;
  }

  Chapter? _selectedChapterInList() {
    final selectedId = _selectedChapter?.id;
    if (selectedId == null) {
      return null;
    }
    for (final chapter in _chapters) {
      if (chapter.id == selectedId) {
        return chapter;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const primary = Color(0xFF0B6E4F);
    const accent = Color(0xFFFF6B35);
    final selectedCourseValue = _selectedCourseInList();
    final selectedSubjectValue = _selectedSubjectInList();
    final selectedChapterValue = _selectedChapterInList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Tutor'),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProgressDashboardScreen(
                  courseRepository: widget.courseRepository,
                ),
              ),
            ),
            tooltip: 'Learning progress',
            icon: const Icon(Icons.trending_up_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DocumentRagIngestionScreen(
                  textbooksPath: '/home/akash/Desktop/IDP/TEXTBOOKS',
                ),
              ),
            ),
            tooltip: 'Import materials',
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ModelSelectionScreen(),
              ),
            ),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Your Learning Path',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Course>(
                      key: ValueKey('course-${_courses.length}-${selectedCourseValue?.id ?? 'none'}'),
                      initialValue: selectedCourseValue,
                      isExpanded: true,
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem<Course>(
                              value: course,
                              child: Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => _courses
                          .map(
                            (course) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onCourseChanged,
                      decoration: InputDecoration(
                        labelText: 'Course',
                        prefixIcon: const Icon(Icons.school_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Subject>(
                      key: ValueKey('subject-${_subjects.length}-${selectedSubjectValue?.id ?? 'none'}'),
                      initialValue: selectedSubjectValue,
                      isExpanded: true,
                      items: _subjects
                          .map(
                            (subject) => DropdownMenuItem<Subject>(
                              value: subject,
                              child: Text(
                                subject.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => _subjects
                          .map(
                            (subject) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                subject.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onSubjectChanged,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: const Icon(Icons.category_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Chapter>(
                      key: ValueKey('chapter-${_chapters.length}-${selectedChapterValue?.id ?? 'none'}'),
                      initialValue: selectedChapterValue,
                      isExpanded: true,
                      items: _chapters
                          .map(
                            (chapter) => DropdownMenuItem<Chapter>(
                              value: chapter,
                              child: Text(
                                chapter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => _chapters
                          .map(
                            (chapter) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                chapter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onChapterChanged,
                      decoration: InputDecoration(
                        labelText: 'Chapter',
                        prefixIcon: const Icon(Icons.bookmark_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Learning Options
            const Text(
              'Learning Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // AI Tutor Card
            _LearningCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Tutor',
              description: 'Chat with intelligent tutor',
              color: primary,
              onTap: _navigateTutor,
            ),

            const SizedBox(height: 12),

            // Materials Card
            _LearningCard(
              icon: Icons.library_books_rounded,
              title: 'Learning Materials',
              description: 'Textbooks, videos & resources',
              color: const Color(0xFF6366F1),
              onTap: _navigateMaterials,
            ),

            const SizedBox(height: 12),

            // Quiz Card
            _LearningCard(
              icon: Icons.quiz_rounded,
              title: 'Quiz & Assessment',
              description: 'Test your knowledge',
              color: accent,
              onTap: _navigateQuiz,
            ),

            const SizedBox(height: 12),

            // Math Simulator Card
            _LearningCard(
              icon: Icons.calculate_rounded,
              title: 'Math Simulator',
              description: '2D formula and geometry simulation',
              color: const Color(0xFF2563EB),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MathSimulatorScreen(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // P2P Card
            _LearningCard(
              icon: Icons.group_rounded,
              title: 'Community Learning',
              description: 'Connect with peers (P2P)',
              color: const Color(0xFF10B981),
              onTap: _navigateP2PForTest,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (enabled ? color : Colors.grey).withValues(alpha: 0.1),
                (enabled ? color : Colors.grey).withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (enabled ? color : Colors.grey).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled ? color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: enabled ? color : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
