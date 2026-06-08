import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/experiment_package.dart';
import '../../experiment/builder/validation/manifest_sanitizer.dart';

String _encodePackage(ExperimentPackage package) {
  return jsonEncode(package.toJson());
}

ExperimentPackage _decodePackage(String content) {
  final jsonMap = jsonDecode(content) as Map<String, dynamic>;
  jsonMap['manifest'] = ManifestSanitizer.sanitize(jsonMap['manifest'] as Map<String, dynamic>? ?? {});
  return ExperimentPackage.fromJson(jsonMap);
}

class ExperimentSharingRepository {
  /// Exports an ExperimentPackage to a .pihubexp file and returns the file path
  Future<String> exportPackage(ExperimentPackage package, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    final file = File('${directory.path}/$safeFilename.pihubexp');
    
    final jsonString = await compute(_encodePackage, package);
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  /// Opens a file picker, reads a .pihubexp file, and returns the parsed ExperimentPackage
  Future<ExperimentPackage?> importPackage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pihubexp'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      
      try {
        return await compute(_decodePackage, content);
      } catch (e) {
        throw FormatException('Invalid .pihubexp format: $e');
      }
    }
    return null; // User canceled the picker
  }

  /// Validates the basic structural integrity of a package
  bool isValidPackage(ExperimentPackage package) {
    if (!package.isSignatureValid) return false;
    if (package.manifest.isEmpty) return false;
    return true;
  }
}

