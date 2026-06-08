import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../../application/background_ingestion_queue_service.dart';
import '../../application/document_loader_service.dart';
import '../../application/rag_ingestion_service.dart';
import '../../../course/data/local/course_repository.dart';
import '../../../course/domain/course_tree.dart';

/// Enhanced RAG ingestion screen supporting both seed data & document discovery
class DocumentRagIngestionScreen extends StatefulWidget {
  final String? textbooksPath;

  const DocumentRagIngestionScreen({
    this.textbooksPath,
    super.key,
  });

  @override
  State<DocumentRagIngestionScreen> createState() =>
      _DocumentRagIngestionScreenState();
}

class _DocumentRagIngestionScreenState extends State<DocumentRagIngestionScreen> {
  final _ingestionService = RagIngestionService();
  final _queueService = BackgroundIngestionQueueService();
  final _courseRepository = CourseRepository();

  List<DocumentFile> _availableDocuments = [];
  List<bool> _selectedDocuments = [];
  List<Chapter> _chapters = [];
  String? _selectedChapterId;
  bool _isLoading = false;
  bool _isDiscovering = false;
  String? _errorMessage;
  String? _successMessage;
  final List<String> _queueSummaryLines = <String>[];
  IngestionQueueSnapshot? _queueSnapshot;
  StreamSubscription<IngestionQueueSnapshot>? _queueSub;

  late String _textbooksPath;

  @override
  void initState() {
    super.initState();
    _textbooksPath = widget.textbooksPath ?? '/home/akash/Desktop/IDP/TEXTBOOKS';
    _loadChapters();
    _discoverDocuments();
    _initQueue();
  }

  Future<void> _initQueue() async {
    _queueSnapshot = await _queueService.getSnapshot();
    _queueSub = _queueService.snapshots.listen((snapshot) {
      if (!mounted) {
        return;
      }
      setState(() {
        _queueSnapshot = snapshot;
      });
    });
    await _queueService.start();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    _queueService.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _courseRepository.getAllChapters();
      if (!mounted) {
        return;
      }
      setState(() {
        _chapters = chapters;
        _selectedChapterId = chapters.isEmpty ? null : (_selectedChapterId ?? chapters.first.id);
      });
    } catch (_) {
      // Non-blocking: ingestion can still proceed with fallback chapter id.
    }
  }

  Future<void> _importPdfFiles() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: true,
      );

      final files = picked?.files ?? const <PlatformFile>[];
      if (files.isEmpty) {
        return;
      }

      final existingPaths = _availableDocuments.map((d) => d.path).toSet();
      final added = <DocumentFile>[];

      for (final file in files) {
        final path = file.path;
        if (path == null || path.isEmpty || existingPaths.contains(path)) {
          continue;
        }
        final bytes = file.size;
        added.add(
          DocumentFile(
            path: path,
            name: file.name,
            sizeMB: (bytes / (1024 * 1024)).toStringAsFixed(2),
            modifiedAt: DateTime.now(),
            type: 'pdf',
          ),
        );
      }

      if (!mounted) {
        return;
      }

      if (added.isEmpty) {
        _showErrorSnackbar('No new PDF files selected.');
        return;
      }

      setState(() {
        final updatedDocs = <DocumentFile>[...added, ..._availableDocuments];
        _availableDocuments = updatedDocs;
        _selectedDocuments = List<bool>.filled(updatedDocs.length, false);
        for (var i = 0; i < added.length; i++) {
          _selectedDocuments[i] = true;
        }
      });

      _showSuccessSnackbar('Added ${added.length} PDF files.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Import failed: $e';
      });
      _showErrorSnackbar('Failed to import PDFs: $e');
    }
  }

  Future<void> _discoverDocuments() async {
    setState(() {
      _isDiscovering = true;
      _errorMessage = null;
    });

    try {
      final documents =
          await DocumentLoaderService.listPdfFiles(_textbooksPath);

      if (mounted) {
        setState(() {
          _availableDocuments = documents;
          _selectedDocuments = List.filled(documents.length, false);
          _isDiscovering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
          _errorMessage = 'Failed to discover documents: $e';
        });
      }
    }
  }

  Future<void> _processSelectedDocuments() async {
    final selectedDocs = <DocumentFile>[];
    for (var i = 0; i < _selectedDocuments.length; i++) {
      if (_selectedDocuments[i]) {
        selectedDocs.add(_availableDocuments[i]);
      }
    }

    if (selectedDocs.isEmpty) {
      _showErrorSnackbar('Please select at least one document');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final chapterId = _selectedChapterId ?? 'chapter-imported-documents';
      final jobId = await _queueService.enqueueJob(
        chapterId: chapterId,
        files: selectedDocs,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _successMessage =
            'Queued ${selectedDocs.length} documents (job #$jobId). Processing in background.';
        _selectedDocuments = List.filled(_availableDocuments.length, false);
      });

      _showSuccessSnackbar(_successMessage!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Queueing failed: $e';
        });
      }
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _queueAllDiscoveredDocumentsByChapter() async {
    if (_availableDocuments.isEmpty) {
      _showErrorSnackbar('No textbooks discovered to queue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _queueSummaryLines.clear();
    });

    try {
      final chapterById = <String, Chapter>{
        for (final chapter in _chapters) chapter.id: chapter,
      };
      final grouped = <String, List<DocumentFile>>{};

      for (final doc in _availableDocuments) {
        final chapterId = _resolveChapterForDocument(doc);
        grouped.putIfAbsent(chapterId, () => <DocumentFile>[]).add(doc);
      }

      var totalQueuedDocs = 0;
      var queuedJobs = 0;
      final summary = <String>[];

      for (final entry in grouped.entries) {
        final chapterId = entry.key;
        final docs = entry.value;
        if (docs.isEmpty) {
          continue;
        }

        final jobId = await _queueService.enqueueJob(
          chapterId: chapterId,
          files: docs,
        );
        queuedJobs += 1;
        totalQueuedDocs += docs.length;

        final chapterName = chapterById[chapterId]?.title ?? chapterId;
        summary.add('$chapterName: ${docs.length} file(s) queued (job #$jobId)');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _selectedDocuments = List<bool>.filled(_availableDocuments.length, false);
        _queueSummaryLines
          ..clear()
          ..addAll(summary);
        _successMessage =
            'Queued $totalQueuedDocs textbook file(s) into $queuedJobs chapter job(s).';
      });

      _showSuccessSnackbar(_successMessage!);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bulk queue failed: $e';
      });
      _showErrorSnackbar('Bulk queue failed: $e');
    }
  }

  String _resolveChapterForDocument(DocumentFile doc) {
    final name = doc.name.toLowerCase();

    if (name.contains('math') || name.contains('maths')) {
      return _chapterIdOrFallback('chap_linear_eq');
    }
    if (name.contains('science') || name.contains('sci')) {
      return _chapterIdOrFallback('chap_chemical_rxn');
    }
    if (name.contains('social') || name.contains('history') || name.contains('civics')) {
      return _chapterIdOrFallback('chap_resources_10');
    }
    if (name.contains('english') || name.contains('grammar') || name.contains('prose')) {
      return _chapterIdOrFallback('chap_prose_10');
    }

    return _selectedChapterId ?? _chapters.first.id;
  }

  String _chapterIdOrFallback(String preferredChapterId) {
    final exists = _chapters.any((chapter) => chapter.id == preferredChapterId);
    if (exists) {
      return preferredChapterId;
    }
    return _selectedChapterId ?? _chapters.first.id;
  }

  Future<void> _ingestSeedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await _ingestionService.ingestSeedData('assets/seed_data_math_science.json');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _successMessage =
                'Seed data ingested: ${result.chunksIngested} chunks';
          } else {
            _errorMessage = result.message;
          }
        });

        if (result.success) {
          _showSuccessSnackbar(_successMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ingestion failed: $e';
        });
      }
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleDocumentSelection(int index) {
    setState(() {
      _selectedDocuments[index] = !_selectedDocuments[index];
    });
  }

  void _selectAll() {
    setState(() {
      for (var i = 0; i < _selectedDocuments.length; i++) {
        _selectedDocuments[i] = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (var i = 0; i < _selectedDocuments.length; i++) {
        _selectedDocuments[i] = false;
      }
    });
  }

  int get _selectedCount =>
      _selectedDocuments.where((s) => s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAG Document Ingestion'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seed data section
              _buildSeedDataSection(),
              const SizedBox(height: 24),

              // Document discovery section
              _buildDocumentDiscoveryHeader(),
              const SizedBox(height: 12),
              _buildImportControls(),
              const SizedBox(height: 12),
              _buildQueueStatusCard(),
              const SizedBox(height: 12),

              if (_isDiscovering)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )
              else if (_availableDocuments.isEmpty)
                _buildEmptyState()
              else ...[
                _buildSelectionControls(),
                const SizedBox(height: 12),
                _buildDocumentsList(),
              ],

              // Messages
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                _buildSuccessCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedDataSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pre-built Curriculum',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Load curated Math & Physics content with formulas and definitions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _ingestSeedData,
              icon: const Icon(Icons.download),
              label: const Text('Load Seed Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentDiscoveryHeader() {
    return Text(
      'Discover & Process Textbooks',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildImportControls() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_chapters.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedChapterId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Target chapter for imported documents',
                  border: OutlineInputBorder(),
                ),
                items: _chapters
                    .map(
                      (chapter) => DropdownMenuItem<String>(
                        value: chapter.id,
                        child: Text(
                          chapter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => _chapters
                    .map(
                      (chapter) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          chapter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedChapterId = value;
                        });
                      },
              ),
            if (_chapters.isNotEmpty) const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _discoverDocuments,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Scan Textbooks Folder'),
                ),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _importPdfFiles,
                  icon: const Icon(Icons.file_open_rounded),
                  label: const Text('Import PDFs'),
                ),
                FilledButton.icon(
                  onPressed: _isLoading || _availableDocuments.isEmpty
                      ? null
                      : _queueAllDiscoveredDocumentsByChapter,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Queue All By Chapter'),
                ),
              ],
            ),
            if (_queueSummaryLines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Queued Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final line in _queueSummaryLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $line',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No PDF files detected in $_textbooksPath',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _discoverDocuments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: _importPdfFiles,
                  icon: const Icon(Icons.file_open_rounded),
                  label: const Text('Import PDFs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$_selectedCount selected',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextButton(
              onPressed: _selectAll,
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear All'),
            ),
            TextButton.icon(
              onPressed:
                  _isLoading || _selectedCount == 0
                      ? null
                      : _processSelectedDocuments,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade700,
                        ),
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatusCard() {
    final snapshot = _queueSnapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Background Ingestion Queue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Pending: ${snapshot.pending}')),
                Chip(label: Text('Running: ${snapshot.running}')),
                Chip(label: Text('Failed: ${snapshot.failed}')),
                Chip(label: Text('Completed: ${snapshot.completed}')),
                Chip(label: Text(snapshot.paused ? 'Paused' : 'Active')),
              ],
            ),
            if (snapshot.lastMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                snapshot.lastMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: snapshot.paused ? _queueService.resume : _queueService.pause,
                  icon: Icon(snapshot.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(snapshot.paused ? 'Resume Queue' : 'Pause Queue'),
                ),
                OutlinedButton.icon(
                  onPressed: snapshot.failed > 0 ? _queueService.retryFailedJobs : null,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Failed Jobs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Card(
      elevation: 1,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _availableDocuments.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final doc = _availableDocuments[index];
          final metadata = DocumentLoaderService.parseFilename(doc.name);
          final selected = _selectedDocuments[index];

          return ListTile(
            leading: Checkbox(
              value: selected,
              onChanged: (_) => _toggleDocumentSelection(index),
            ),
            title: Text(metadata.displayName),
            subtitle: Text(
                '${doc.sizeMB} MB • ${_languageLabel(metadata.language)}'),
            trailing: Icon(
              Icons.description,
              color: metadata.language == 'kn'
                  ? Colors.purple.shade600
                  : Colors.blue.shade600,
            ),
            onTap: () => _toggleDocumentSelection(index),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? '',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _successMessage ?? '',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(String lang) {
    return lang == 'kn' ? 'Kannada' : 'English';
  }
}
