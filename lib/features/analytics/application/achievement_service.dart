import 'package:shared_preferences/shared_preferences.dart';
import '../domain/learning_profile_models.dart';

class AchievementService {
  final SharedPreferences _prefs;

  AchievementService(this._prefs);

  static Future<AchievementService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AchievementService(prefs);
  }

  // Predefined Achievements
  final List<StudentAchievement> _allAchievements = [
    StudentAchievement(
      id: 'first_chapter',
      title: 'First Chapter Completed',
      description: 'You finished reading your first chapter.',
      iconName: 'menu_book_rounded',
      earnedAt: DateTime.now(),
    ),
    StudentAchievement(
      id: 'quiz_master',
      title: 'Quiz Master',
      description: 'Scored 100% on a chapter quiz.',
      iconName: 'workspace_premium_rounded',
      earnedAt: DateTime.now(),
    ),
    StudentAchievement(
      id: 'experiment_explorer',
      title: 'Experiment Explorer',
      description: 'Launched your first experiment.',
      iconName: 'science_rounded',
      earnedAt: DateTime.now(),
    ),
    StudentAchievement(
      id: 'science_champion',
      title: 'Science Champion',
      description: 'Completed 5 Science quizzes.',
      iconName: 'biotech_rounded',
      earnedAt: DateTime.now(),
    ),
    StudentAchievement(
      id: 'math_explorer',
      title: 'Math Explorer',
      description: 'Completed 5 Math quizzes.',
      iconName: 'calculate_rounded',
      earnedAt: DateTime.now(),
    ),
  ];

  Future<void> unlockAchievement(String id) async {
    final unlocked = _prefs.getStringList('unlocked_achievements') ?? [];
    if (!unlocked.contains(id)) {
      unlocked.add(id);
      await _prefs.setStringList('unlocked_achievements', unlocked);
      await _prefs.setString('achievement_date_$id', DateTime.now().toIso8601String());
    }
  }

  List<StudentAchievement> getUnlockedAchievements() {
    final unlockedIds = _prefs.getStringList('unlocked_achievements') ?? [];
    return _allAchievements.where((a) => unlockedIds.contains(a.id)).map((a) {
      final dateStr = _prefs.getString('achievement_date_${a.id}');
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      return StudentAchievement(
        id: a.id,
        title: a.title,
        description: a.description,
        iconName: a.iconName,
        earnedAt: date,
      );
    }).toList();
  }
}
