import 'package:flutter/material.dart';
import '../../content_packs/data/local/content_pack_repository.dart';
import '../../onboarding/presentation/grade_selection_screen.dart';
import '../../onboarding/presentation/grade_sync_screen.dart';
import '../../course/data/local/app_database.dart';
import '../../../core/theme/idp_colors.dart';
import '../../../core/widgets/idp_core_widgets.dart';
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
        title: const Text('Remove Grade', style: IDPTypography.titleSmall),
        content: Text('Remove all downloaded content for Grade $grade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: IDPColors.error),
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
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Manage Offline Content', style: IDPTypography.titleMedium),
        backgroundColor: IDPColors.surface,
        foregroundColor: IDPColors.onSurface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IDPColors.primary))
          : ListView(
              padding: const EdgeInsets.all(IDPSpacing.md),
              children: [
                _buildStatCard('Storage Usage', '${_storageUsageMb.toStringAsFixed(1)} MB', Icons.storage_rounded),
                const SizedBox(height: IDPSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Installed Packs', '$_packCount', Icons.folder_zip_rounded)),
                    const SizedBox(width: IDPSpacing.sm),
                    Expanded(child: _buildStatCard('RAG Chunks', '$_chunkCount', Icons.data_array_rounded)),
                  ],
                ),
                const SizedBox(height: IDPSpacing.lg),
                const IDPSectionHeader(
                  title: 'Installed Grades',
                  subtitle: 'Offline content packs stored on this device',
                ),
                const SizedBox(height: IDPSpacing.sm),
                if (_installedGrades.isEmpty)
                  IDPCard(
                    child: Padding(
                      padding: const EdgeInsets.all(IDPSpacing.md),
                      child: Center(
                        child: Text('No grades installed.', style: IDPTypography.bodyMedium.copyWith(color: IDPColors.textSecondary)),
                      ),
                    ),
                  )
                else
                  ..._installedGrades.map((grade) => Padding(
                    padding: const EdgeInsets.only(bottom: IDPSpacing.xs),
                    child: IDPCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: IDPColors.primaryContainer,
                          foregroundColor: IDPColors.onPrimaryContainer,
                          child: const Icon(Icons.school_rounded),
                        ),
                        title: Text('Grade $grade', style: IDPTypography.titleSmall),
                        subtitle: Text('Installed subjects: ${_installedSubjects.join(", ")}', style: IDPTypography.bodySmall),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sync_rounded, color: IDPColors.primary),
                              tooltip: 'Re-sync Grade',
                              onPressed: () => _resyncGrade(grade),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: IDPColors.error),
                              tooltip: 'Remove Grade',
                              onPressed: () => _removeGrade(grade),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                const SizedBox(height: IDPSpacing.lg),
                FilledButton.icon(
                  onPressed: _installGrade,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Install Additional Grade'),
                  style: FilledButton.styleFrom(
                    backgroundColor: IDPColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: IDPSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.defaultRadius)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return IDPCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: IDPColors.primary),
          const SizedBox(height: IDPSpacing.xs),
          Text(value, style: IDPTypography.headlineSmall.copyWith(color: IDPColors.textPrimary)),
          const SizedBox(height: IDPSpacing.xs / 2),
          Text(title, style: IDPTypography.bodySmall.copyWith(color: IDPColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

