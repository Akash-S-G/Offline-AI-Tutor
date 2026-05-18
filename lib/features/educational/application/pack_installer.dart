import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../../../config/app_environment.dart';
import '../data/educational_repository.dart';
import '../models/educational_models.dart';

/// Installs educational packs and indexes their content
/// 
/// Responsibilities:
/// - Extract pack archives
/// - Validate pack integrity
/// - Index pack content for search
/// - Parse educational structure (grades, subjects, chapters, concepts)
class PackInstaller {
  final String packId;
  final String sourcePath;
  final String targetPath;

  PackInstaller({
    required this.packId,
    required this.sourcePath,
    required this.targetPath,
  });

  /// Install a pack from source to target location
  /// 
  /// If source is a ZIP file, extracts it.
  /// If source is a directory, indexes it directly.
  Future<bool> install({
    ProgressCallback? onProgress,
  }) async {
    try {
      AppEnvironment.log('SYNC', 'Installing pack: $packId from $sourcePath');

      final sourceFile = File(sourcePath);
      final targetDir = Directory(targetPath);

      // Create target directory
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Extract if it's a ZIP file
      if (sourcePath.endsWith('.zip')) {
        await _extractZip(sourceFile, targetDir, onProgress: onProgress);
      } else if (await File(sourcePath).exists()) {
        // Copy file
        await sourceFile.copy(path.join(targetPath, path.basename(sourcePath)));
      } else if (await Directory(sourcePath).exists()) {
        // Copy directory
        await _copyDirectory(Directory(sourcePath), targetDir);
      }

      // Index content after installation
      await indexPackContent();

      AppEnvironment.log('SYNC', 'Pack installed successfully: $packId');
      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error installing pack: $e');
      return false;
    }
  }

  /// Extract ZIP archive to target directory
  Future<void> _extractZip(
    File zipFile,
    Directory targetDir, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int filesProcessed = 0;
      final totalFiles = archive.length;

      for (final file in archive) {
        filesProcessed++;
        onProgress?.call(filesProcessed / totalFiles);

        final filePath = path.join(targetDir.path, file.name);
        
        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          final outputDir = Directory(filePath);
          await outputDir.create(recursive: true);
        }
      }

      AppEnvironment.log('SYNC', 'ZIP extracted: $totalFiles files');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error extracting ZIP: $e');
      rethrow;
    }
  }

  /// Copy directory recursively
  Future<void> _copyDirectory(Directory source, Directory target) async {
    try {
      final entities = source.listSync(recursive: false);
      for (final entity in entities) {
        final targetPath = path.join(target.path, path.basename(entity.path));
        
        if (entity is File) {
          await entity.copy(targetPath);
        } else if (entity is Directory) {
          await Directory(targetPath).create(recursive: true);
          await _copyDirectory(entity, Directory(targetPath));
        }
      }
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error copying directory: $e');
      rethrow;
    }
  }

  /// Index pack content and populate database
  /// 
  /// Scans pack directory for educational structure:
  /// - Grades (numeric directories like "10", "9")
  /// - Subjects (subdirectories like "Maths", "Science")
  /// - Chapters (files or further subdirectories)
  Future<void> indexPackContent() async {
    try {
      AppEnvironment.log('SYNC', 'Indexing pack content: $packId');

      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        throw Exception('Target directory does not exist: $targetPath');
      }

      // Scan for structure
      final entities = targetDir.listSync(recursive: false);
      
      for (final entity in entities) {
        if (entity is Directory) {
          final dirName = path.basename(entity.path);
          
          // Try to parse grade number
          final gradeNumber = int.tryParse(dirName);
          
          if (gradeNumber != null && gradeNumber >= 1 && gradeNumber <= 12) {
            await _indexGrade(gradeNumber, entity);
          }
        }
      }

      AppEnvironment.log('SYNC', 'Pack indexing complete: $packId');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error indexing pack content: $e');
      rethrow;
    }
  }

  /// Index a grade directory
  Future<void> _indexGrade(int gradeNumber, Directory gradeDir) async {
    try {
      // Get or create grade
      final grades = await EducationalRepository.getAllGrades();
      GradeModel? grade;
      
      try {
        grade = grades.firstWhere((g) => g.gradeNumber == gradeNumber);
      } catch (e) {
        grade = null;
      }

      if (grade == null) {
        final gradeId = await EducationalRepository.insertGrade(
          GradeModel(
            name: 'Grade $gradeNumber',
            gradeNumber: gradeNumber,
            description: 'Grade $gradeNumber content',
          ),
        );
        grade = GradeModel(
          id: gradeId,
          name: 'Grade $gradeNumber',
          gradeNumber: gradeNumber,
        );
      }

      // Scan subjects
      final subjectDirs = gradeDir.listSync(recursive: false);
      int subjectSequence = 0;

      for (final entity in subjectDirs) {
        if (entity is Directory) {
          subjectSequence++;
          final subjectName = path.basename(entity.path);
          await _indexSubject(grade.id!, subjectName, entity, subjectSequence);
        }
      }

      AppEnvironment.log('SYNC', 'Grade indexed: Grade $gradeNumber');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error indexing grade: $e');
    }
  }

  /// Index a subject directory
  Future<void> _indexSubject(
    int gradeId,
    String subjectName,
    Directory subjectDir,
    int sequenceNumber,
  ) async {
    try {
      // Create subject
      final subjectId = await EducationalRepository.insertSubject(
        SubjectModel(
          gradeId: gradeId,
          name: subjectName,
          description: 'Subject: $subjectName',
        ),
      );

      // Scan chapters
      final chapterEntities = subjectDir.listSync(recursive: false);
      int chapterSequence = 0;

      for (final entity in chapterEntities) {
        if (entity is Directory) {
          chapterSequence++;
          final chapterName = path.basename(entity.path);
          await _indexChapter(subjectId, chapterName, entity, chapterSequence);
        }
      }

      AppEnvironment.log('SYNC', 'Subject indexed: $subjectName');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error indexing subject: $e');
    }
  }

  /// Index a chapter directory
  Future<void> _indexChapter(
    int subjectId,
    String chapterName,
    Directory chapterDir,
    int sequenceNumber,
  ) async {
    try {
      // Create chapter
      final chapterId = await EducationalRepository.insertChapter(
        ChapterModel(
          subjectId: subjectId,
          name: chapterName,
          sequenceNumber: sequenceNumber,
          summary: 'Chapter: $chapterName',
        ),
      );

      // Scan for concepts or content files
      final contentFiles = chapterDir.listSync(recursive: false);
      int conceptSequence = 0;

      for (final entity in contentFiles) {
        if (entity is File) {
          conceptSequence++;
          final fileName = path.basenameWithoutExtension(entity.path);
          
          // Try to read content
          final content = await _readFileContent(entity);
          
          // Create concept
          await EducationalRepository.insertConcept(
            ConceptModel(
              chapterId: chapterId,
              name: fileName,
              sequenceNumber: conceptSequence,
              definition: 'Concept: $fileName',
              examples: content.substring(0, 200), // First 200 chars
            ),
          );
        }
      }

      AppEnvironment.log('SYNC', 'Chapter indexed: $chapterName');
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error indexing chapter: $e');
    }
  }

  /// Read file content (text files only)
  Future<String> _readFileContent(File file) async {
    try {
      if (file.path.endsWith('.txt') || file.path.endsWith('.md')) {
        final content = await file.readAsString();
        return content.substring(0, (content.length < 500 ? content.length : 500));
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Validate pack integrity
  Future<bool> validatePackIntegrity() async {
    try {
      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        AppEnvironment.log('SYNC', 'Pack directory missing: $targetPath');
        return false;
      }

      // Check for expected structure
      final entities = targetDir.listSync(recursive: false);
      if (entities.isEmpty) {
        AppEnvironment.log('SYNC', 'Pack directory is empty: $targetPath');
        return false;
      }

      AppEnvironment.log('SYNC', 'Pack validation passed: $packId');
      return true;
    } catch (e) {
      AppEnvironment.log('SYNC', 'Error validating pack: $e');
      return false;
    }
  }
}

/// Callback for installation progress
typedef ProgressCallback = void Function(double progress);

/// Result of pack installation
class PackInstallationResult {
  final bool success;
  final String? errorMessage;
  final int? chaptersInstalled;
  final int? conceptsInstalled;

  PackInstallationResult({
    required this.success,
    this.errorMessage,
    this.chaptersInstalled,
    this.conceptsInstalled,
  });
}
