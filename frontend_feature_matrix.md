# Frontend Feature Matrix

## Feature: Curriculum
- **Purpose**: Browse grade, subject, chapter, topic hierarchy
- **Primary Screens**:
  - `CurriculumHomeScreen`
  - `GradeScreen`
  - `SubjectScreen`
  - `ChapterScreen`
  - `TopicScreen`
- **Repositories**:
  - `CourseRepository`
  - `CurriculumRepository`
  - `TextbookRepository`
  - `EducationalRepository`
- **Services**:
  - `PackSyncService`
  - `BackgroundPrefetchService`
- **Status**: Active

## Feature: Tutor (AI Chat)
- **Purpose**: AI tutor chat with offline inference
- **Primary Screens**:
  - `ChapterChatScreen`
  - `DatabaseDiagnosticsScreen`
  - `RetrievalDiagnosticsScreen`
- **Repositories**:
  - `ChatSessionRepository`
  - `ChatMemoryPolicyRepository`
- **Services**:
  - `TutorInferenceGateway`
  - `ConversationMemoryService`
  - `TutorPromptBuilder`
- **Status**: Active

## Feature: Experiments
- **Purpose**: Create, manage, and execute experiments
- **Primary Screens**:
  - `ExperimentBuilderScreen`
  - `ExperimentPlayerScreen`
  - `ExperimentCatalogScreen`
  - `ExperimentDetailsScreen`
  - `ExperimentHubScreen`
- **Repositories**:
  - `ExperimentRepository`
  - `ExperimentRunRepository`
  - `ExperimentManifestRepository`
  - `ExperimentTemplateRepository`
- **Services**:
  - `ExperimentExecutionOrchestrator`
  - `ExperimentExecutionPlanner`
  - `TelemetryService`
- **Status**: Active

## Feature: Math Studio
- **Purpose**: Algebra, geometry, stats, formula visualization
- **Primary Screens**:
  - `MathStudioHomeScreen`
  - `AlgebraWorkspaceScreen`
  - `GeometryWorkspaceScreen`
  - `FunctionsWorkspaceScreen`
  - `StatisticsWorkspaceScreen`
  - `FormulaPlaygroundScreen`
- **Repositories**:
  - `ExplorationRepository`
- **Services**:
  - `MathEvaluatorService`
- **Status**: Active

## Feature: Downloads
- **Purpose**: Download and sync content packs
- **Primary Screens**:
  - `ContentPackInstallerScreen`
- **Repositories**:
  - `ContentPackRepository`
- **Services**:
  - `ContentPackSyncService`
  - `ContentPackArchiveService`
- **Status**: Active

## Feature: Flashcards
- **Purpose**: Flashcard review
- **Primary Screens**:
  - (Embedded in `QuizPlayerScreen`)
- **Repositories**:
  - `QuizResultRepository`
- **Services**:
  - `FlashcardEngine`
- **Status**: Active

## Feature: Quizzes
- **Purpose**: Quiz assessments
- **Primary Screens**:
  - `QuizAssessmentScreen`
  - `QuizPlayerScreen`
- **Repositories**:
  - `QuizResultRepository`
- **Services**:
  - `QuizFlashcardEngine`
- **Status**: Active

## Feature: PDF Reader
- **Purpose**: PDF and textbook reading
- **Primary Screens**:
  - `PdfChapterReaderScreen`
  - `PdfViewerScreen`
  - `ChapterReaderScreen`
- **Repositories**:
  - `TextbookRepository`
- **Services**:
  - `PdfExtractionService`
  - `PdfStructureExtractionService`
- **Status**: Active

## Feature: Progress Tracking
- ** inventory**:
  - `ProgressDashboardScreen`
- **Repositories**:
  - `ProgressRepository`
- **Services**:
  - `LearningInsightsService`
  - `AchievementService`
- **Status**: Active

## Feature: Offline Content
- **Purpose**: Offline-first data and media
- **Primary Screens**:
  - `OfflineLearningReportScreen`
- **Repositories**:
  - `MediaResourceRepository`
  - `StudyNoteRepository`
- **Services**:
  - `OfflineTutorService`
  - `LocalSearchService`
- **Status**: Active

## Feature: Classroom Management
- **Purpose**: Teacher/student classroom management
- **Primary Screens**:
  - `TeacherDashboardScreen`
  - `StudentDashboardScreen`
  - `AssignmentDetailScreen`
  - `TeacherReviewScreen`
- **Repositories**:
  - `ClassroomRepository`
- **Services**:
  - `ClassroomSessionManager`
  - `ClassroomMetricsCollector`
- **Status**: Active

## Feature: P2P
- **Purpose**: Peer-to-peer content sharing
- **Primary Screens**:
  - `P2PScreen`
- **Repositories**:
  - `P2PSecuritySettingsRepository`
  - `TrustedPeerRepository`
- **Services**:
  - `P2PSecretBootstrapService`
  - `P2PBundleService`
  - `P2PChannelService`
- **Status**: Active

## Feature: RAG (Retrieval-Augmented Generation)
- **Purpose**: Document ingestion for RAG
- **Primary Screens**:
  - `RagIngestionScreen`
  - `DocumentRagIngestionScreen`
- **Repositories**:
  - `RagRepository`
  - `RUIS`: `RagRepositoryV2`
  - `EmbeddingIndexRepository`
- **Services**:
  - `RagIngestionService`
  - `HybridRetrievalService`
  - `EmbeddingIndexService`
- **Status**: Active

## Feature: Settings
- **Purpose**: App settings
- **Primary Screens**:
  - `ManageContentScreen`
  - `ModelSelectionScreen`
- **Repositories**:
  - None
- **Services**:
  - None
- **Status**: Active
