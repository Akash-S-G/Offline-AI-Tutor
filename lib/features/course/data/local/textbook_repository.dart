import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/textbook_models.dart';

class TextbookRepository {
  Future<TextbookChapter?> loadChapter(String rootPath) async {
    try {
      final file = File(p.join(rootPath, 'textbook.json'));
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      return TextbookChapter.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      print('Error loading textbook.json: $e');
      return null;
    }
  }
}
