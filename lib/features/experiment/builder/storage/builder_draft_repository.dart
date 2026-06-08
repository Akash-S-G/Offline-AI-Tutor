import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'builder_draft.dart';

List<String> _encodeDrafts(List<BuilderDraft> drafts) {
  return drafts.map((d) => jsonEncode(d.toJson())).toList();
}

List<BuilderDraft> _decodeDrafts(List<String> list) {
  return list.map((str) => BuilderDraft.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
}

abstract class BuilderDraftRepository {
  Future<void> saveDraft(BuilderDraft draft);
  Future<List<BuilderDraft>> getDrafts();
  Future<void> deleteDraft(String draftId);
}

class SharedPreferencesBuilderDraftRepository implements BuilderDraftRepository {
  static const String _draftsKey = 'experiment_builder_drafts';

  @override
  Future<void> saveDraft(BuilderDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();
    
    final index = drafts.indexWhere((d) => d.draftId == draft.draftId);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }
    
    final encodedList = await compute(_encodeDrafts, drafts);
    await prefs.setStringList(_draftsKey, encodedList);
  }

  @override
  Future<List<BuilderDraft>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_draftsKey);
    if (list == null) return [];
    
    try {
      return await compute(_decodeDrafts, list);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();
    
    drafts.removeWhere((d) => d.draftId == draftId);
    
    final encodedList = await compute(_encodeDrafts, drafts);
    await prefs.setStringList(_draftsKey, encodedList);
  }
}

