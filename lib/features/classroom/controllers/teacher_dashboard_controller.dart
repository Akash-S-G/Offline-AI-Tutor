import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/classroom_session.dart';
import '../models/classroom_assignment.dart';
import '../models/classroom_submission.dart';
import '../repositories/classroom_repository.dart';

class TeacherDashboardController extends ChangeNotifier {
  final ClassroomRepository _repository;

  List<ClassroomSession> activeSessions = [];
  List<ClassroomAssignment> assignments = [];
  List<ClassroomSubmission> submissions = [];

  StreamSubscription? _sessionsSub;
  StreamSubscription? _assignmentsSub;
  StreamSubscription? _submissionsSub;

  TeacherDashboardController(this._repository) {
    _initStreams();
  }

  void _initStreams() async {
    activeSessions = await _repository.fetchActiveSessions();
    notifyListeners();

    _sessionsSub = _repository.sessionsStream.listen((sessions) {
      activeSessions = sessions.where((s) => s.isActive).toList();
      notifyListeners();
    });

    _assignmentsSub = _repository.assignmentsStream.listen((assigns) {
      // In a real app, filter to teacher's assignments
      assignments = assigns;
      notifyListeners();
    });

    _submissionsSub = _repository.submissionsStream.listen((subs) {
      submissions = subs;
      notifyListeners();
    });
  }

  Future<void> createSession(String topic) async {
    final session = ClassroomSession(
      id: const Uuid().v4(),
      topic: topic,
      teacherName: 'Teacher (Local)',
    );
    await _repository.createSession(session);
  }

  Future<void> closeSession(String sessionId) async {
    await _repository.closeSession(sessionId);
  }

  Future<void> distributeExperiment(String sessionId, String title, Map<String, dynamic> manifest) async {
    final assignment = ClassroomAssignment(
      id: const Uuid().v4(),
      sessionId: sessionId,
      title: title,
      instructions: 'Complete the experiment by following the layout.',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      executionModes: ['Simulation', 'Hardware'],
      requiredSensors: ['Accelerometer'],
      manifest: manifest,
    );
    await _repository.distributeAssignment(assignment);
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    _assignmentsSub?.cancel();
    _submissionsSub?.cancel();
    super.dispose();
  }
}
