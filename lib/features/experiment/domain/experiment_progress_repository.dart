import 'package:shared_preferences/shared_preferences.dart';

class ExperimentProgressRepository {
  final SharedPreferences _prefs;

  ExperimentProgressRepository(this._prefs);

  static Future<ExperimentProgressRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ExperimentProgressRepository(prefs);
  }

  Future<void> markExperimentStarted(String experimentId, String chapterId) async {
    await _prefs.setBool('exp_started_${experimentId}_$chapterId', true);
  }

  Future<void> markExperimentCompleted(String experimentId, String chapterId, {int? score}) async {
    await _prefs.setBool('exp_completed_${experimentId}_$chapterId', true);
    if (score != null) {
      await _prefs.setInt('exp_score_${experimentId}_$chapterId', score);
    }
  }

  bool isExperimentStarted(String experimentId, String chapterId) {
    return _prefs.getBool('exp_started_${experimentId}_$chapterId') ?? false;
  }

  bool isExperimentCompleted(String experimentId, String chapterId) {
    return _prefs.getBool('exp_completed_${experimentId}_$chapterId') ?? false;
  }

  int? getExperimentScore(String experimentId, String chapterId) {
    return _prefs.getInt('exp_score_${experimentId}_$chapterId');
  }
}
