import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Tutor'**
  String get appTitle;

  /// No description provided for @offlineTutor.
  ///
  /// In en, this message translates to:
  /// **'Offline Tutor'**
  String get offlineTutor;

  /// No description provided for @learnAnywhereAnytime.
  ///
  /// In en, this message translates to:
  /// **'Learn Anywhere, Anytime'**
  String get learnAnywhereAnytime;

  /// No description provided for @richContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Rich Content'**
  String get richContentTitle;

  /// No description provided for @richContentDescription.
  ///
  /// In en, this message translates to:
  /// **'Textbooks, videos, and materials'**
  String get richContentDescription;

  /// No description provided for @smartTutorTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Tutor'**
  String get smartTutorTitle;

  /// No description provided for @smartTutorDescription.
  ///
  /// In en, this message translates to:
  /// **'AI-powered learning assistance'**
  String get smartTutorDescription;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communityDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect and learn with peers'**
  String get communityDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @offlineTutorOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Offline Tutor Onboarding'**
  String get offlineTutorOnboarding;

  /// No description provided for @whatGradeAreYouStudying.
  ///
  /// In en, this message translates to:
  /// **'What grade are you studying?'**
  String get whatGradeAreYouStudying;

  /// No description provided for @selectYourGradeDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your grade to download the required offline curriculum. This reduces storage usage and sync time.'**
  String get selectYourGradeDescription;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @gradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String gradeLabel(Object grade);

  /// No description provided for @voiceTutorTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Tutor'**
  String get voiceTutorTitle;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get developerMode;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @tapMicToStartTalking.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to start talking'**
  String get tapMicToStartTalking;

  /// No description provided for @tapMicToAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to ask a question!'**
  String get tapMicToAskQuestion;

  /// No description provided for @voiceDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Debug'**
  String get voiceDebugTitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @playRecording.
  ///
  /// In en, this message translates to:
  /// **'Play Recording'**
  String get playRecording;

  /// No description provided for @permissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permissionLabel;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @playingLabel.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playingLabel;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @notGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get notGranted;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline. Local features are still available.'**
  String get offlineMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @manageOfflineContent.
  ///
  /// In en, this message translates to:
  /// **'Manage Offline Content'**
  String get manageOfflineContent;

  /// No description provided for @removeGrade.
  ///
  /// In en, this message translates to:
  /// **'Remove Grade'**
  String get removeGrade;

  /// No description provided for @removeGradePrompt.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloaded content for Grade {grade}?'**
  String removeGradePrompt(Object grade);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noGradesInstalled.
  ///
  /// In en, this message translates to:
  /// **'No grades installed.'**
  String get noGradesInstalled;

  /// No description provided for @installedSubjects.
  ///
  /// In en, this message translates to:
  /// **'Installed subjects: {subjects}'**
  String installedSubjects(Object subjects);

  /// No description provided for @reSyncGrade.
  ///
  /// In en, this message translates to:
  /// **'Re-sync Grade'**
  String get reSyncGrade;

  /// No description provided for @installAdditionalGrade.
  ///
  /// In en, this message translates to:
  /// **'Install Additional Grade'**
  String get installAdditionalGrade;

  /// No description provided for @modelSelection.
  ///
  /// In en, this message translates to:
  /// **'Model Selection'**
  String get modelSelection;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded: {value}'**
  String loaded(Object value);

  /// No description provided for @inferences.
  ///
  /// In en, this message translates to:
  /// **'Inferences: {count}'**
  String inferences(Object count);

  /// No description provided for @pickModelFile.
  ///
  /// In en, this message translates to:
  /// **'Pick .gguf model file'**
  String get pickModelFile;

  /// No description provided for @validateModel.
  ///
  /// In en, this message translates to:
  /// **'Validate Model'**
  String get validateModel;

  /// No description provided for @resetEngine.
  ///
  /// In en, this message translates to:
  /// **'Reset Engine'**
  String get resetEngine;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @deepExplain.
  ///
  /// In en, this message translates to:
  /// **'Deep Explain'**
  String get deepExplain;

  /// No description provided for @saveModelConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Model Configuration'**
  String get saveModelConfiguration;

  /// No description provided for @modelConfigurationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Model configuration updated.'**
  String get modelConfigurationUpdated;

  /// No description provided for @modelEngineReset.
  ///
  /// In en, this message translates to:
  /// **'Model engine reset.'**
  String get modelEngineReset;

  /// No description provided for @offlineLearningReport.
  ///
  /// In en, this message translates to:
  /// **'Offline Learning Report'**
  String get offlineLearningReport;

  /// No description provided for @yourLearningInsights.
  ///
  /// In en, this message translates to:
  /// **'Your Learning Insights'**
  String get yourLearningInsights;

  /// No description provided for @generatedLocally.
  ///
  /// In en, this message translates to:
  /// **'Generated locally on your device'**
  String get generatedLocally;

  /// No description provided for @keepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning to discover your strengths.'**
  String get keepLearning;

  /// No description provided for @noMajorWeakAreasDetected.
  ///
  /// In en, this message translates to:
  /// **'No major weak areas detected. Great job!'**
  String get noMajorWeakAreasDetected;

  /// No description provided for @completeChapters.
  ///
  /// In en, this message translates to:
  /// **'Complete chapters and quizzes to earn badges.'**
  String get completeChapters;

  /// No description provided for @chatSyllabusNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Paste syllabus notes for this chapter...'**
  String get chatSyllabusNotesHint;

  /// No description provided for @chatMessageTutorHint.
  ///
  /// In en, this message translates to:
  /// **'Message your tutor'**
  String get chatMessageTutorHint;

  /// No description provided for @chatVoiceTutorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice tutor'**
  String get chatVoiceTutorTooltip;

  /// No description provided for @chatVoiceRequiresBackendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice requires backend connection'**
  String get chatVoiceRequiresBackendTooltip;

  /// No description provided for @chatStopResponseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop response'**
  String get chatStopResponseTooltip;

  /// No description provided for @chatSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSendTooltip;

  /// No description provided for @chatStatusTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating to {lang}...'**
  String chatStatusTranslating(Object lang);

  /// No description provided for @chatTranslationHeaderOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original (EN):\n{original}\n\nTranslated ({lang}):\n{translated}'**
  String chatTranslationHeaderOriginal(
    Object original,
    Object lang,
    Object translated,
  );

  /// No description provided for @navMyLearning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get navMyLearning;

  /// No description provided for @navToolsClass.
  ///
  /// In en, this message translates to:
  /// **'Tools & Class'**
  String get navToolsClass;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardTakeQuizHint.
  ///
  /// In en, this message translates to:
  /// **'Take your first chapter quiz'**
  String get dashboardTakeQuizHint;

  /// No description provided for @dashboardAttemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s) recorded'**
  String dashboardAttemptsCount(Object count);

  /// No description provided for @dashboardAttemptsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s), latest {percent}% ({label})'**
  String dashboardAttemptsSummary(Object count, Object percent, Object label);

  /// No description provided for @settingsModelNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Model selection is not available on this platform yet. Currently implemented on Android.'**
  String get settingsModelNotAvailable;

  /// No description provided for @settingsModelLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load model metadata.'**
  String get settingsModelLoadFailed;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your default language (English / Kannada)'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select App Language'**
  String get settingsLanguageDialogTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settingsDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Diagnostics'**
  String get settingsDiagnosticsTitle;

  /// No description provided for @activeLearningGrade.
  ///
  /// In en, this message translates to:
  /// **'Active Learning Grade'**
  String get activeLearningGrade;

  /// No description provided for @gradeCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade} Curriculum'**
  String gradeCurriculum(Object grade);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @systemActions.
  ///
  /// In en, this message translates to:
  /// **'System Actions'**
  String get systemActions;

  /// No description provided for @learningProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get learningProgress;

  /// No description provided for @learningProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View quiz attempts and performance statistics'**
  String get learningProgressSubtitle;

  /// No description provided for @manageContentPacks.
  ///
  /// In en, this message translates to:
  /// **'Manage Content Packs'**
  String get manageContentPacks;

  /// No description provided for @manageContentPacksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync, install, and clear offline content packs'**
  String get manageContentPacksSubtitle;

  /// No description provided for @importCustomMaterials.
  ///
  /// In en, this message translates to:
  /// **'Import Custom Materials'**
  String get importCustomMaterials;

  /// No description provided for @importCustomMaterialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import PDF files to parse and build local indexes'**
  String get importCustomMaterialsSubtitle;

  /// No description provided for @modelSettings.
  ///
  /// In en, this message translates to:
  /// **'Model Settings'**
  String get modelSettings;

  /// No description provided for @modelSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select offline/online LLM configuration'**
  String get modelSettingsSubtitle;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @myLearningJourney.
  ///
  /// In en, this message translates to:
  /// **'My Learning Journey'**
  String get myLearningJourney;

  /// No description provided for @myLearningJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'Study textbooks, take interactive quizzes, and ask the AI Tutor questions fully offline.'**
  String get myLearningJourneyDescription;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Chapters'**
  String chaptersCount(Object count);

  /// No description provided for @chapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Chapter'**
  String chapterCount(Object count);

  /// No description provided for @noContentForGrade.
  ///
  /// In en, this message translates to:
  /// **'No Content for Grade {grade}'**
  String noContentForGrade(Object grade);

  /// No description provided for @noContentForGradeDescription.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t installed any offline content packs for Grade {grade} yet. Download content to start learning offline.'**
  String noContentForGradeDescription(Object grade);

  /// No description provided for @installGradeContent.
  ///
  /// In en, this message translates to:
  /// **'Install Grade {grade} Content'**
  String installGradeContent(Object grade);

  /// No description provided for @progressDashboard.
  ///
  /// In en, this message translates to:
  /// **'Progress Dashboard'**
  String get progressDashboard;

  /// No description provided for @studyStreak.
  ///
  /// In en, this message translates to:
  /// **'Study Streak'**
  String get studyStreak;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @experiments.
  ///
  /// In en, this message translates to:
  /// **'Experiments'**
  String get experiments;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysCount(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
