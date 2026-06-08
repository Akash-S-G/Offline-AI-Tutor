// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'builder_draft.dart';
import 'builder_draft_repository.dart';

class BuilderDraftManager extends ChangeNotifier {
  final BuilderDraftRepository _repository;
  
  List<BuilderDraft> _drafts = [];
  List<BuilderDraft> get drafts => List.unmodifiable(_drafts);
  
  String? _currentDraftId;
  String? get currentDraftId => _currentDraftId;

  Timer? _autoSaveTimer;
  
  BuilderDraftManager(this._repository) {
    _loadAllDrafts();
  }
  
  Future<void> _loadAllDrafts() async {
    _drafts = await _repository.getDrafts();
    _drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // newest first
    notifyListeners();
  }

  Future<void> createDraft(String title, Map<String, dynamic> initialManifest) async {
    final draft = BuilderDraft(
      draftId: const Uuid().v4(),
      title: title,
      updatedAt: DateTime.now(),
      manifest: initialManifest,
    );
    
    await _repository.saveDraft(draft);
    _currentDraftId = draft.draftId;
    await _loadAllDrafts();
    print('[BUILDER] DRAFT_CREATED');
  }

  Future<void> saveCurrentDraft(String title, Map<String, dynamic> manifest, {bool isAutoSave = false}) async {
    if (_currentDraftId == null) {
      await createDraft(title, manifest);
      return;
    }
    
    final draft = BuilderDraft(
      draftId: _currentDraftId!,
      title: title,
      updatedAt: DateTime.now(),
      manifest: manifest,
    );
    
    await _repository.saveDraft(draft);
    
    // Only update local array memory without forcing full reload for performance if autosaving
    final index = _drafts.indexWhere((d) => d.draftId == draft.draftId);
    if (index >= 0) {
      _drafts[index] = draft;
      _drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    
    if (isAutoSave) {
      print('[BUILDER] AUTO_SAVE');
    } else {
      print('[BUILDER] DRAFT_SAVED');
    }
    notifyListeners();
  }

  Future<void> loadDraft(String draftId) async {
    final draft = _drafts.firstWhere((d) => d.draftId == draftId, orElse: () => throw Exception('Draft not found'));
    _currentDraftId = draft.draftId;
    print('[BUILDER] DRAFT_LOADED');
    notifyListeners();
  }

  Future<void> deleteDraft(String draftId) async {
    await _repository.deleteDraft(draftId);
    if (_currentDraftId == draftId) {
      _currentDraftId = null;
    }
    await _loadAllDrafts();
    print('[BUILDER] DRAFT_DELETED');
  }

  Future<void> duplicateDraft(String draftId) async {
    try {
      final draft = _drafts.firstWhere((d) => d.draftId == draftId);
      await createDraft('${draft.title} (Copy)', draft.manifest);
    } catch (e) {
      print('Error duplicating draft: $e');
    }
  }

  void startAutoSave(String Function() getTitle, Map<String, dynamic> Function() getManifest) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      saveCurrentDraft(getTitle(), getManifest(), isAutoSave: true);
    });
  }

  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  @override
  void dispose() {
    stopAutoSave();
    super.dispose();
  }
}
