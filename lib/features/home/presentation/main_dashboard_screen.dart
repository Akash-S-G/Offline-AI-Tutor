import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../course/data/local/app_database.dart' as offline_tutor_app;
import '../../assessment/data/local/quiz_result_repository.dart';
import '../../assessment/domain/quiz_result.dart';
import '../../chat/presentation/chapter_chat_screen.dart';
import '../../course/data/local/course_repository.dart';
import '../../course/domain/course_tree.dart';
import '../../p2p/data/p2p_channel_service.dart';
import '../../p2p/presentation/p2p_screen.dart';
import '../../progress/presentation/progress_dashboard_screen.dart';
import '../../rag/presentation/screens/document_rag_ingestion_screen.dart';
import '../../settings/presentation/model_selection_screen.dart';
import '../../settings/presentation/manage_content_screen.dart';
import '../../onboarding/presentation/grade_selection_screen.dart';
import 'my_learning_screen.dart';
import '../../math_studio/presentation/math_studio_home_screen.dart';
import 'quiz_assessment_screen.dart';

import '../../experiment/builder/screens/experiment_builder_screen.dart';
import '../../experiment_sharing/screens/experiment_share_screen.dart';
import '../../experiment_sharing/controllers/experiment_sharing_controller.dart';
import '../../experiment_sharing/repositories/experiment_sharing_repository.dart';
import '../../experiment/builder/storage/builder_draft_manager.dart';
import '../../experiment/builder/storage/builder_draft_repository.dart';
import '../../experiment/builder/data/repositories/experiment_manifest_repository.dart';
import '../../experiment/builder/data/api/experiment_manifest_api_service.dart';
import '../../experiment/presentation/screens/experiment_hub_screen.dart';
import '../../experiment/phet/presentation/experiment_catalog_screen.dart';
import '../../network/domain/backend_config.dart';
import '../../network/presentation/classroom_connection_banner.dart';

import '../../classroom/repositories/classroom_repository.dart';
import '../../classroom/controllers/teacher_dashboard_controller.dart';
import '../../classroom/controllers/student_dashboard_controller.dart';
import '../../classroom/screens/teacher_dashboard_screen.dart';
import '../../classroom/screens/student_dashboard_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({required this.courseRepository, super.key});

  final CourseRepository courseRepository;

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final QuizResultRepository _quizResultRepository = QuizResultRepository();
  final P2PChannelService _p2pChannelService = P2PChannelService();
  final ClassroomRepository _classroomRepository = ClassroomRepository();

  int _currentIndex = 0;
  List<Course> _courses = const [];
  List<Subject> _subjects = const [];
  List<Chapter> _chapters = const [];

  Course? _selectedCourse;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;

  bool _loading = true;
  int _quizAttempts = 0;
  QuizResult? _latestQuizResult;
  String _p2pSummary = 'Scanning peers...';
  bool _p2pAvailable = true;
  int _selectedGrade = 8;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _loadFeatureInsights();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      final db = await offline_tutor_app.AppDatabase.instance.database;
      final packs =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM material_packs'),
          ) ??
          0;
      final chunks =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM rag_chunks'),
          ) ??
          0;

      print('====================================================');
      print('[DIAGNOSTICS] PHASE 1 & 2 REPORT');
      print('[DB] CONTENT_PACKS_COUNT=$packs');
      print('[DB] RAG_CHUNKS_COUNT=$chunks');

      final ftsTableExists =
          Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='rag_chunks_fts'",
            ),
          ) ??
          0;

      if (ftsTableExists > 0) {
        final ftsChunks =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM rag_chunks_fts'),
            ) ??
            0;
        print('[DB] RAG_FTS_COUNT=$ftsChunks');
      } else {
        print('[DB] RAG_FTS_COUNT=0 (Table does not exist)');
      }

      final packRows = await db.query('material_packs');
      for (final row in packRows) {
        final packId = row['pack_id'];
        final items =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM material_pack_items WHERE pack_id = ?',
                [packId],
              ),
            ) ??
            0;
        print(
          '[DIAGNOSTICS] PACK_ID=$packId, INSERTED_CHUNKS=0 (Items: $items)',
        );
      }
      print('====================================================');
    } catch (e) {
      print('[DIAGNOSTICS] Error running diagnostics: $e');
    }
  }

  Future<void> _loadFeatureInsights() async {
    QuizResult? latest;
    var attemptCount = 0;
    var p2pSummary = 'Scanning peers...';
    var p2pAvailable = true;

    try {
      final allResults = await _quizResultRepository.getAllResults();
      attemptCount = allResults.length;
      if (allResults.isNotEmpty) {
        latest = allResults.first;
      }
    } catch (_) {}

    try {
      final status = await _p2pChannelService.getStatus();
      final peers = await _p2pChannelService.listPeers();
      if (!status.supported) {
        p2pSummary = 'P2P unsupported on this device';
      } else if (!status.enabled) {
        p2pSummary = 'P2P is off, enable sharing to discover peers';
      } else if (peers.isEmpty) {
        p2pSummary = 'No peers found nearby';
      } else {
        p2pSummary = '${peers.length} peer(s) available for transfer';
      }
    } on MissingPluginException {
      p2pAvailable = false;
      p2pSummary = 'P2P available on Android builds';
    } on PlatformException {
      p2pSummary = 'P2P status unavailable right now';
    } catch (_) {
      p2pSummary = 'P2P status unavailable right now';
    }

    final prefs = await SharedPreferences.getInstance();
    final grade = prefs.getInt('selected_grade') ?? 8;

    if (!mounted) return;

    setState(() {
      _quizAttempts = attemptCount;
      _latestQuizResult = latest;
      _p2pSummary = p2pSummary;
      _p2pAvailable = p2pAvailable;
      _selectedGrade = grade;
    });
  }

  Future<void> _loadInitial() async {
    try {
      final courses = await widget.courseRepository.getCourses();
      if (courses.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final selectedCourse = courses.first;
      final subjects = await widget.courseRepository.getSubjects(
        selectedCourse.id,
      );
      final selectedSubject = subjects.isEmpty ? null : subjects.first;
      final chapters = selectedSubject == null
          ? <Chapter>[]
          : await widget.courseRepository.getChapters(selectedSubject.id);

      if (mounted) {
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
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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

  Future<void> _navigateQuiz() async {
    final course = _selectedCourse;
    final subject = _selectedSubject;
    final chapter = _selectedChapter;

    if (course == null || subject == null || chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter first')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAssessmentScreen(
          course: course,
          subject: subject,
          chapter: chapter,
        ),
      ),
    );

    await _loadFeatureInsights();
  }

  Future<void> _navigateP2PForTest() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => P2PScreen(courseRepository: widget.courseRepository),
      ),
    );

    await _loadFeatureInsights();
  }

  Future<void> _quickSendSelectedChapter() async {
    final chapter = _selectedChapter;
    if (chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a chapter first')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => P2PScreen(
          courseRepository: widget.courseRepository,
          initialChapterId: chapter.id,
          quickSendPreset: true,
        ),
      ),
    );

    await _loadFeatureInsights();
  }

  void _navigateExperimentHub() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExperimentCatalogScreen()),
    );
  }

  void _navigateExperimentSharing() {
    final config =
        BackendConfig.fromEnvironment() ??
        BackendConfig(baseUrl: 'http://localhost', apiKey: 'dummy');
    final manifestRepo = ExperimentManifestRepositoryImpl(
      ExperimentManifestApiService(config),
    );
    final draftManager = BuilderDraftManager(
      SharedPreferencesBuilderDraftRepository(),
    );
    final sharingController = ExperimentSharingController(
      sharingRepository: ExperimentSharingRepository(),
      manifestRepository: manifestRepo,
      draftManager: draftManager,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExperimentShareScreen(
          sharingController: sharingController,
          draftManager: draftManager,
        ),
      ),
    );
  }

  void _navigateTeacherDashboard() {
    final draftManager = BuilderDraftManager(
      SharedPreferencesBuilderDraftRepository(),
    );
    final controller = TeacherDashboardController(_classroomRepository);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherDashboardScreen(
          controller: controller,
          draftManager: draftManager,
        ),
      ),
    );
  }

  void _navigateStudentDashboard() {
    final controller = StudentDashboardController(_classroomRepository);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentDashboardScreen(controller: controller),
      ),
    );
  }

  String _quizDescription() {
    if (_quizAttempts == 0) {
      return 'Take your first chapter quiz';
    }

    final latest = _latestQuizResult;
    if (latest == null) {
      return '$_quizAttempts attempt(s) recorded';
    }

    return '$_quizAttempts attempt(s), latest ${latest.percentage}% (${latest.performanceLabel})';
  }

  Course? _selectedCourseInList() {
    final selectedId = _selectedCourse?.id;
    if (selectedId == null) return null;
    for (final course in _courses) {
      if (course.id == selectedId) return course;
    }
    return null;
  }

  Subject? _selectedSubjectInList() {
    final selectedId = _selectedSubject?.id;
    if (selectedId == null) return null;
    for (final subject in _subjects) {
      if (subject.id == selectedId) return subject;
    }
    return null;
  }

  Chapter? _selectedChapterInList() {
    final selectedId = _selectedChapter?.id;
    if (selectedId == null) return null;
    for (final chapter in _chapters) {
      if (chapter.id == selectedId) return chapter;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0B6E4F),
        unselectedItemColor: const Color(0xFF64748B),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadFeatureInsights();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'My Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.construction_rounded),
            label: 'Tools & Class',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex == 0) const ClassroomConnectionBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  const MyLearningScreen(),
                  _buildToolsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab() {
    const primary = Color(0xFF0B6E4F);
    const accent = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tools & Classroom'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Interactive Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.calculate_rounded,
              title: 'Math Studio',
              description: 'Interactive mathematical exploration',
              color: const Color(0xFF2563EB),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MathStudioHomeScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.science_rounded,
              title: 'Experiment Studio',
              description: 'Create, test, and manage physics experiments',
              color: Colors.purple,
              onTap: _navigateExperimentHub,
            ),
            const SizedBox(height: 24),

            const Text(
              'Sharing & P2P Transfer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.group_rounded,
              title: 'Community Learning',
              description: _p2pSummary,
              color: const Color(0xFF10B981),
              onTap: _p2pAvailable
                  ? () {
                      _navigateP2PForTest();
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.share_rounded,
              title: 'Share Experiments',
              description: 'P2P Experiment Exchange',
              color: Colors.deepOrange,
              onTap: _navigateExperimentSharing,
            ),
            const SizedBox(height: 24),

            const Text(
              'Classroom Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.school_rounded,
              title: 'Teacher Dashboard',
              description: 'Distribute & Collect Assignments',
              color: Colors.teal,
              onTap: _navigateTeacherDashboard,
            ),
            const SizedBox(height: 12),
            _LearningCard(
              icon: Icons.backpack_rounded,
              title: 'Student Dashboard',
              description: 'Receive & Submit Assignments',
              color: Colors.indigo,
              onTap: _navigateStudentDashboard,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    const primary = Color(0xFF0B6E4F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: primary, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Learning Grade',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grade $_selectedGrade Curriculum',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => const GradeSelectionScreen(),
                          ),
                        )
                        .then((_) => _loadFeatureInsights());
                  },
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'System Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            icon: Icons.trending_up_rounded,
            title: 'Learning Progress',
            subtitle: 'View quiz attempts and performance statistics',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProgressDashboardScreen(
                  courseRepository: widget.courseRepository,
                ),
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.folder_zip_rounded,
            title: 'Manage Content Packs',
            subtitle: 'Sync, install, and clear offline content packs',
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageContentScreen(),
                  ),
                )
                .then((_) => _loadFeatureInsights()),
          ),
          _buildSettingsItem(
            icon: Icons.upload_file_rounded,
            title: 'Import Custom Materials',
            subtitle: 'Import PDF files to parse and build local indexes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DocumentRagIngestionScreen(
                  textbooksPath: '/home/akash/Desktop/IDP/TEXTBOOKS',
                ),
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.settings_rounded,
            title: 'Model Settings',
            subtitle: 'Select offline/online LLM configuration',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ModelSelectionScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF475569)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                enabled
                    ? Icons.arrow_forward_rounded
                    : Icons.lock_outline_rounded,
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
