import 'dart:async';
import '../models/classroom_session.dart';
import '../models/classroom_assignment.dart';
import '../models/classroom_submission.dart';

/// A repository acting as an abstraction over P2P/LAN for Classroom Distribution.
/// For local testing without physical peers, it implements an in-memory mock broadcast.
class ClassroomRepository {
  // In-memory mock states for single-device simulation
  static final List<ClassroomSession> _activeSessions = [];
  static final List<ClassroomAssignment> _assignments = [];
  static final List<ClassroomSubmission> _submissions = [];

  final _sessionsController = StreamController<List<ClassroomSession>>.broadcast();
  final _assignmentsController = StreamController<List<ClassroomAssignment>>.broadcast();
  final _submissionsController = StreamController<List<ClassroomSubmission>>.broadcast();

  Stream<List<ClassroomSession>> get sessionsStream => _sessionsController.stream;
  Stream<List<ClassroomAssignment>> get assignmentsStream => _assignmentsController.stream;
  Stream<List<ClassroomSubmission>> get submissionsStream => _submissionsController.stream;

  Future<void> createSession(ClassroomSession session) async {
    // In a real scenario, this would advertise the session via P2PChannelService
    await Future.delayed(const Duration(milliseconds: 500));
    _activeSessions.add(session);
    _sessionsController.add(List.unmodifiable(_activeSessions));
  }

  Future<void> closeSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _activeSessions.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      _activeSessions[index] = _activeSessions[index].copyWith(isActive: false);
      _sessionsController.add(List.unmodifiable(_activeSessions));
    }
  }

  Future<void> distributeAssignment(ClassroomAssignment assignment) async {
    // In a real scenario, broadcast package to connected students
    await Future.delayed(const Duration(milliseconds: 500));
    _assignments.add(assignment);
    _assignmentsController.add(List.unmodifiable(_assignments));
  }

  Future<void> submitAssignment(ClassroomSubmission submission) async {
    // In a real scenario, send data back to teacher via P2P
    await Future.delayed(const Duration(seconds: 1));
    _submissions.add(submission);
    _submissionsController.add(List.unmodifiable(_submissions));
  }

  Future<List<ClassroomSession>> fetchActiveSessions() async {
    return _activeSessions.where((s) => s.isActive).toList();
  }

  Future<List<ClassroomAssignment>> fetchAssignmentsForSession(String sessionId) async {
    return _assignments.where((a) => a.sessionId == sessionId).toList();
  }

  Future<List<ClassroomSubmission>> fetchSubmissionsForSession(String sessionId) async {
    final sessionAssignmentIds = _assignments.where((a) => a.sessionId == sessionId).map((a) => a.id).toSet();
    return _submissions.where((s) => sessionAssignmentIds.contains(s.assignmentId)).toList();
  }
}
