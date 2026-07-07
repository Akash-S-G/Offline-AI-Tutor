import '../../chat/data/platform_tutor_inference_gateway.dart';
import '../../course/domain/course_tree.dart';
import '../../course/domain/curriculum_models.dart';
import '../data/local/translation_engine_config_service.dart';
import 'separate_translation_layer_service.dart';

class ContentLocalizationService {
  ContentLocalizationService({
    SeparateTranslationLayerService? translationService,
    TranslationEngineConfigService? configService,
  })  : _configService = configService ?? TranslationEngineConfigService(),
        _translationService = translationService ??
            SeparateTranslationLayerService(
              gateway: PlatformTutorInferenceGateway(),
            );

  final TranslationEngineConfigService _configService;
  final SeparateTranslationLayerService _translationService;
  TranslationEngineConfig? _cachedConfig;

  Future<TranslationEngineConfig> _config() async {
    return _cachedConfig ??= await _configService.load();
  }

  Future<String> translateText(
    String text, {
    required String artifactType,
    required String sourceLanguage,
    required String targetLanguage,
    String? contentId,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || sourceLanguage == targetLanguage) {
      return text;
    }

    final result = await _translationService.translate(
      text: text,
      sourceLang: sourceLanguage,
      targetLang: targetLanguage,
      config: await _config(),
      artifactType: artifactType,
      contentId: contentId,
    );
    return result.translated;
  }

  Future<Course> localizeCourse(
    Course course, {
    required String targetLanguage,
  }) async {
    return Course(
      id: course.id,
      name: await translateText(
        course.name,
        artifactType: 'course_name',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: course.id,
      ),
    );
  }

  Future<Subject> localizeSubject(
    Subject subject, {
    required String targetLanguage,
  }) async {
    return Subject(
      id: subject.id,
      courseId: subject.courseId,
      name: await translateText(
        subject.name,
        artifactType: 'subject_name',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: subject.id,
      ),
    );
  }

  Future<Chapter> localizeChapter(
    Chapter chapter, {
    required String targetLanguage,
  }) async {
    return Chapter(
      id: chapter.id,
      subjectId: chapter.subjectId,
      title: await translateText(
        chapter.title,
        artifactType: 'chapter_title',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: chapter.id,
      ),
      summary: await translateText(
        chapter.summary,
        artifactType: 'chapter_summary',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: chapter.id,
      ),
    );
  }

  Future<List<Course>> localizeCourses(
    List<Course> courses, {
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return courses;
    }
    return Future.wait(
      courses.map((course) => localizeCourse(course, targetLanguage: targetLanguage)),
    );
  }

  Future<List<Subject>> localizeSubjects(
    List<Subject> subjects, {
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return subjects;
    }
    return Future.wait(
      subjects.map((subject) => localizeSubject(subject, targetLanguage: targetLanguage)),
    );
  }

  Future<List<Chapter>> localizeChapters(
    List<Chapter> chapters, {
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return chapters;
    }
    return Future.wait(
      chapters.map((chapter) => localizeChapter(chapter, targetLanguage: targetLanguage)),
    );
  }

  Future<List<CurriculumGrade>> localizeCurriculum(
    List<CurriculumGrade> curriculum, {
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return curriculum;
    }

    return Future.wait(
      curriculum.map((grade) async {
        final localizedSubjects = await Future.wait(
          grade.subjects.map((subject) async {
            final localizedChapters = await Future.wait(
              subject.chapters.map(
                (chapter) => translateCurriculumChapter(
                  chapter,
                  targetLanguage: targetLanguage,
                ),
              ),
            );
            return CurriculumSubject(
              name: await translateText(
                subject.name,
                artifactType: 'curriculum_subject',
                sourceLanguage: 'en',
                targetLanguage: targetLanguage,
                contentId: '${grade.grade}:${subject.name}',
              ),
              grade: subject.grade,
              chapters: localizedChapters,
            );
          }),
        );
        return CurriculumGrade(
          grade: grade.grade,
          subjects: localizedSubjects,
        );
      }),
    );
  }

  Future<CurriculumChapter> translateCurriculumChapter(
    CurriculumChapter chapter, {
    required String targetLanguage,
  }) async {
    if (targetLanguage == 'en') {
      return chapter;
    }

    return CurriculumChapter(
      packId: chapter.packId,
      title: await translateText(
        chapter.title,
        artifactType: 'curriculum_chapter_title',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: chapter.packId,
      ),
      subject: await translateText(
        chapter.subject,
        artifactType: 'curriculum_chapter_subject',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: chapter.packId,
      ),
      grade: chapter.grade,
      rootPath: chapter.rootPath,
      summary: await translateText(
        chapter.summary,
        artifactType: 'curriculum_chapter_summary',
        sourceLanguage: 'en',
        targetLanguage: targetLanguage,
        contentId: chapter.packId,
      ),
      language: targetLanguage,
    );
  }
}
