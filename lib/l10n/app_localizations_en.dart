// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Offline Tutor';

  @override
  String get offlineTutor => 'Offline Tutor';

  @override
  String get learnAnywhereAnytime => 'Learn Anywhere, Anytime';

  @override
  String get richContentTitle => 'Rich Content';

  @override
  String get richContentDescription => 'Textbooks, videos, and materials';

  @override
  String get smartTutorTitle => 'Smart Tutor';

  @override
  String get smartTutorDescription => 'AI-powered learning assistance';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityDescription => 'Connect and learn with peers';

  @override
  String get getStarted => 'Get Started';

  @override
  String get offlineTutorOnboarding => 'Offline Tutor Onboarding';

  @override
  String get whatGradeAreYouStudying => 'What grade are you studying?';

  @override
  String get selectYourGradeDescription =>
      'Select your grade to download the required offline curriculum. This reduces storage usage and sync time.';

  @override
  String get continueLabel => 'Continue';

  @override
  String gradeLabel(Object grade) {
    return 'Grade $grade';
  }

  @override
  String get voiceTutorTitle => 'Voice Tutor';

  @override
  String get developerMode => 'Developer Mode';

  @override
  String get languageLabel => 'Language';

  @override
  String get tapMicToStartTalking => 'Tap the mic to start talking';

  @override
  String get tapMicToAskQuestion => 'Tap the mic to ask a question!';

  @override
  String get voiceDebugTitle => 'Voice Debug';

  @override
  String get reset => 'Reset';

  @override
  String get playRecording => 'Play Recording';

  @override
  String get permissionLabel => 'Permission';

  @override
  String get recordingLabel => 'Recording';

  @override
  String get durationLabel => 'Duration';

  @override
  String get playingLabel => 'Playing';

  @override
  String get granted => 'Granted';

  @override
  String get notGranted => 'Not granted';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get offlineMessage =>
      'You are currently offline. Local features are still available.';

  @override
  String get retry => 'RETRY';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get manageOfflineContent => 'Manage Offline Content';

  @override
  String get removeGrade => 'Remove Grade';

  @override
  String removeGradePrompt(Object grade) {
    return 'Remove all downloaded content for Grade $grade?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get noGradesInstalled => 'No grades installed.';

  @override
  String installedSubjects(Object subjects) {
    return 'Installed subjects: $subjects';
  }

  @override
  String get reSyncGrade => 'Re-sync Grade';

  @override
  String get installAdditionalGrade => 'Install Additional Grade';

  @override
  String get modelSelection => 'Model Selection';

  @override
  String get refresh => 'Refresh';

  @override
  String loaded(Object value) {
    return 'Loaded: $value';
  }

  @override
  String inferences(Object count) {
    return 'Inferences: $count';
  }

  @override
  String get pickModelFile => 'Pick .gguf model file';

  @override
  String get validateModel => 'Validate Model';

  @override
  String get resetEngine => 'Reset Engine';

  @override
  String get fast => 'Fast';

  @override
  String get balanced => 'Balanced';

  @override
  String get deepExplain => 'Deep Explain';

  @override
  String get saveModelConfiguration => 'Save Model Configuration';

  @override
  String get modelConfigurationUpdated => 'Model configuration updated.';

  @override
  String get modelEngineReset => 'Model engine reset.';

  @override
  String get offlineLearningReport => 'Offline Learning Report';

  @override
  String get yourLearningInsights => 'Your Learning Insights';

  @override
  String get generatedLocally => 'Generated locally on your device';

  @override
  String get keepLearning => 'Keep learning to discover your strengths.';

  @override
  String get noMajorWeakAreasDetected =>
      'No major weak areas detected. Great job!';

  @override
  String get completeChapters =>
      'Complete chapters and quizzes to earn badges.';

  @override
  String get chatSyllabusNotesHint =>
      'Paste syllabus notes for this chapter...';

  @override
  String get chatMessageTutorHint => 'Message your tutor';

  @override
  String get chatVoiceTutorTooltip => 'Voice tutor';

  @override
  String get chatVoiceRequiresBackendTooltip =>
      'Voice requires backend connection';

  @override
  String get chatStopResponseTooltip => 'Stop response';

  @override
  String get chatSendTooltip => 'Send';

  @override
  String chatStatusTranslating(Object lang) {
    return 'Translating to $lang...';
  }

  @override
  String chatTranslationHeaderOriginal(
    Object original,
    Object lang,
    Object translated,
  ) {
    return 'Original (EN):\n$original\n\nTranslated ($lang):\n$translated';
  }

  @override
  String get navMyLearning => 'My Learning';

  @override
  String get navToolsClass => 'Tools & Class';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardTakeQuizHint => 'Take your first chapter quiz';

  @override
  String dashboardAttemptsCount(Object count) {
    return '$count attempt(s) recorded';
  }

  @override
  String dashboardAttemptsSummary(Object count, Object percent, Object label) {
    return '$count attempt(s), latest $percent% ($label)';
  }

  @override
  String get settingsModelNotAvailable =>
      'Model selection is not available on this platform yet. Currently implemented on Android.';

  @override
  String get settingsModelLoadFailed => 'Failed to load model metadata.';

  @override
  String get settingsLanguageTitle => 'Language Settings';

  @override
  String get settingsLanguageSubtitle =>
      'Choose your default language (English / Kannada)';

  @override
  String get settingsLanguageDialogTitle => 'Select App Language';

  @override
  String get close => 'Close';

  @override
  String get settingsDiagnosticsTitle => 'Settings & Diagnostics';

  @override
  String get activeLearningGrade => 'Active Learning Grade';

  @override
  String gradeCurriculum(Object grade) {
    return 'Grade $grade Curriculum';
  }

  @override
  String get change => 'Change';

  @override
  String get systemActions => 'System Actions';

  @override
  String get learningProgress => 'Learning Progress';

  @override
  String get learningProgressSubtitle =>
      'View quiz attempts and performance statistics';

  @override
  String get manageContentPacks => 'Manage Content Packs';

  @override
  String get manageContentPacksSubtitle =>
      'Sync, install, and clear offline content packs';

  @override
  String get importCustomMaterials => 'Import Custom Materials';

  @override
  String get importCustomMaterialsSubtitle =>
      'Import PDF files to parse and build local indexes';

  @override
  String get modelSettings => 'Model Settings';

  @override
  String get modelSettingsSubtitle => 'Select offline/online LLM configuration';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get myLearningJourney => 'My Learning Journey';

  @override
  String get myLearningJourneyDescription =>
      'Study textbooks, take interactive quizzes, and ask the AI Tutor questions fully offline.';

  @override
  String get viewReport => 'View Report';

  @override
  String chaptersCount(Object count) {
    return '$count Chapters';
  }

  @override
  String chapterCount(Object count) {
    return '$count Chapter';
  }

  @override
  String noContentForGrade(Object grade) {
    return 'No Content for Grade $grade';
  }

  @override
  String noContentForGradeDescription(Object grade) {
    return 'You haven\'t installed any offline content packs for Grade $grade yet. Download content to start learning offline.';
  }

  @override
  String installGradeContent(Object grade) {
    return 'Install Grade $grade Content';
  }

  @override
  String get progressDashboard => 'Progress Dashboard';

  @override
  String get studyStreak => 'Study Streak';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get chapters => 'Chapters';

  @override
  String get experiments => 'Experiments';

  @override
  String daysCount(Object count) {
    return '$count Days';
  }
}
