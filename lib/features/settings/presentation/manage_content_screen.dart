import 'package:flutter/material.dart';
import '../../content_packs/data/local/content_pack_repository.dart';
import '../../onboarding/presentation/grade_selection_screen.dart';
import '../../onboarding/presentation/grade_sync_screen.dart';
import '../../course/data/local/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageContentScreen extends StatefulWidget {
  const ManageContentScreen({super.key});

  @override
  State<ManageContentScreen> createState() => _ManageContentScreenState();
}

class _ManageContentScreenState extends State<ManageContentScreen> {
  final ContentPackRepository _repository = ContentPackRepository();
  bool _loading = true;
  
  int _packCount = 0;
  int _chunkCount = 0;
  double _storageUsageMb = 0;
  Set<int> _installedGrades = {};
  Set<String> _installedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final db = await AppDatabase.instance.database;
      
      final packs = await _repository.listInstalledPacks();
      _packCount = packs.length;

      double totalSize = 0;
      Set<int> grades = {};
      Set<String> subjects = {};

      for (final pack in packs) {
        totalSize += pack.contentSizeBytes;
        grades.add(pack.gradeMin);
        grades.add(pack.gradeMax);
        subjects.add(pack.subject.toUpperCase());
      }
      
      _storageUsageMb = totalSize / (1024 * 1024);
      _installedGrades = grades;
      _installedSubjects = subjects;

      final chunkRows = await db.rawQuery('SELECT COUNT(*) AS c FROM rag_chunks_v2');
      _chunkCount = (chunkRows.first['c'] as int?) ?? 0;
      
      if (_chunkCount == 0) {
        final legacyChunkRows = await db.rawQuery('SELECT COUNT(*) AS c FROM rag_chunks');
        _chunkCount = (legacyChunkRows.first['c'] as int?) ?? 0;
      }

    } catch (e) {
      print('Error loading content management data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeGrade(int grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Grade'),
        content: Text('Remove all downloaded content for Grade $grade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
    });

    try {
      final packs = await _repository.listInstalledPacks();
      for (final pack in packs) {
        if (pack.gradeMin == grade || pack.gradeMax == grade) {
          await _repository.deletePack(pack.packId);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final currentGrade = prefs.getInt('selected_grade');
      if (currentGrade == grade) {
        await prefs.remove('selected_grade');
      }

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed Grade $grade content')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  void _installGrade() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
    ).then((_) => _loadData());
  }

  void _resyncGrade(int grade) {
    final languageCode = Localizations.localeOf(context).languageCode;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GradeSyncScreen(
          grade: grade,
          languageCode: languageCode,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offline Content'),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0B6E4F)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard('Storage Usage', '${_storageUsageMb.toStringAsFixed(1)} MB', Icons.storage_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Installed Packs', '$_packCount', Icons.folder_zip_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('RAG Chunks', '$_chunkCount', Icons.data_array_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Installed Grades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_installedGrades.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No grades installed.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._installedGrades.map((grade) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0B6E4F),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.school_rounded),
                      ),
                      title: Text('Grade $grade'),
                      subtitle: Text('Installed subjects: ${_installedSubjects.join(", ")}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sync_rounded),
                            tooltip: 'Re-sync Grade',
                            onPressed: () => _resyncGrade(grade),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Remove Grade',
                            onPressed: () => _removeGrade(grade),
                          ),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _installGrade,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Install Additional Grade'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E4F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF0B6E4F)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
