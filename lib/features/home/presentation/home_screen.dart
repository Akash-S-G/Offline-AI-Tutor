import 'package:flutter/material.dart';

import '../../chat/presentation/chapter_chat_screen.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../../p2p/presentation/p2p_screen.dart';
import '../../progress/presentation/progress_dashboard_screen.dart';
import '../../rag/presentation/screens/document_rag_ingestion_screen.dart';
import '../../settings/presentation/model_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.courseRepository,
    required this.languageCode,
    super.key,
  });

  final CourseRepository courseRepository;
  final String languageCode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final courses = await widget.courseRepository.getCourses(
      languageCode: widget.languageCode,
    );
    if (courses.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final selectedCourse = courses.first;
    final subjects = await widget.courseRepository.getSubjects(
      selectedCourse.id,
      languageCode: widget.languageCode,
    );
    final selectedSubject = subjects.isEmpty ? null : subjects.first;
    final chapters = selectedSubject == null
        ? <Chapter>[]
        : await widget.courseRepository.getChapters(
            selectedSubject.id,
            languageCode: widget.languageCode,
          );

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
    if (course == null) {
      return;
    }

    final subjects = await widget.courseRepository.getSubjects(
      course.id,
      languageCode: widget.languageCode,
    );
    final selectedSubject = subjects.isEmpty ? null : subjects.first;
    final chapters = selectedSubject == null
        ? <Chapter>[]
        : await widget.courseRepository.getChapters(
            selectedSubject.id,
            languageCode: widget.languageCode,
          );

    setState(() {
      _selectedCourse = course;
      _subjects = subjects;
      _selectedSubject = selectedSubject;
      _chapters = chapters;
      _selectedChapter = chapters.isEmpty ? null : chapters.first;
    });
  }

  Future<void> _onSubjectChanged(Subject? subject) async {
    if (subject == null) {
      return;
    }

    final chapters = await widget.courseRepository.getChapters(
      subject.id,
      languageCode: widget.languageCode,
    );

    setState(() {
      _selectedSubject = subject;
      _chapters = chapters;
      _selectedChapter = chapters.isEmpty ? null : chapters.first;
    });
  }

  void _onChapterChanged(Chapter? chapter) {
    if (chapter == null) {
      return;
    }

    setState(() {
      _selectedChapter = chapter;
    });
  }

  void _openTutor() {
    final course = _selectedCourse;
    final subject = _selectedSubject;
    final chapter = _selectedChapter;

    if (course == null || subject == null || chapter == null) {
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

  void _openP2P() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => P2PScreen(
          courseRepository: widget.courseRepository,
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openProgressDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProgressDashboardScreen(
          courseRepository: widget.courseRepository,
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openModelSelection() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ModelSelectionScreen(),
      ),
    );
  }

  void _openRagIngestion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DocumentRagIngestionScreen(
          textbooksPath: '/home/akash/Desktop/TEXTBOOKS',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Tutor'),
        actions: [
          IconButton(
            onPressed: _openProgressDashboard,
            tooltip: 'Learning progress',
            icon: const Icon(Icons.trending_up_rounded),
          ),
          IconButton(
            onPressed: _openRagIngestion,
            tooltip: 'RAG data ingestion',
            icon: const Icon(Icons.cloud_upload_rounded),
          ),
          IconButton(
            onPressed: _openModelSelection,
            tooltip: 'Model selection',
            icon: const Icon(Icons.memory_rounded),
          ),
          IconButton(
            onPressed: _openP2P,
            tooltip: 'P2P sharing',
            icon: const Icon(Icons.wifi_tethering_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose your learning context',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Course>(
              initialValue: _selectedCourse,
              items: _courses
                  .map(
                    (course) => DropdownMenuItem<Course>(
                      value: course,
                      child: Text(course.name),
                    ),
                  )
                  .toList(),
              onChanged: _onCourseChanged,
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Subject>(
              initialValue: _selectedSubject,
              items: _subjects
                  .map(
                    (subject) => DropdownMenuItem<Subject>(
                      value: subject,
                      child: Text(subject.name),
                    ),
                  )
                  .toList(),
              onChanged: _onSubjectChanged,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Chapter>(
              initialValue: _selectedChapter,
              items: _chapters
                  .map(
                    (chapter) => DropdownMenuItem<Chapter>(
                      value: chapter,
                      child: Text(chapter.title),
                    ),
                  )
                  .toList(),
              onChanged: _onChapterChanged,
              decoration: const InputDecoration(
                labelText: 'Chapter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedChapter != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_selectedChapter!.summary),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _openTutor,
              icon: const Icon(Icons.school_rounded),
              label: const Text('Start Tutor Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
