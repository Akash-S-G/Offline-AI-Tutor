import 'package:flutter/material.dart';
import '../../network/application/pi_hub_discovery_coordinator.dart';
import '../../network/application/connectivity_controller.dart';
import '../../rag/data/local/rag_repository.dart';
import '../../course/data/local/app_database.dart';
import '../../educational/data/educational_database.dart';
import 'package:sqflite/sqflite.dart';

/// Hidden diagnostics page for rapid field debugging.
///
/// Access: Long-press the settings icon or navigate to /diagnostics.
/// Displays installed packs, chunk counts, FTS status, backend URL, etc.
class DatabaseDiagnosticsScreen extends StatefulWidget {
  const DatabaseDiagnosticsScreen({super.key});

  @override
  State<DatabaseDiagnosticsScreen> createState() => _DatabaseDiagnosticsScreenState();
}

class _DatabaseDiagnosticsScreenState extends State<DatabaseDiagnosticsScreen> {
  bool _loading = true;
  final Map<String, dynamic> _diagnostics = {};

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);

    try {
      // RAG chunk counts
      final ragRepo = RagRepository();
      final appDb = await AppDatabase.instance.database;

      final ragCount = Sqflite.firstIntValue(
        await appDb.rawQuery('SELECT COUNT(*) FROM rag_chunks'),
      ) ?? 0;

      // FTS availability
      bool ftsAvailable = false;
      int ftsCount = 0;
      try {
        final ftsRows = await appDb.rawQuery('SELECT COUNT(*) FROM rag_chunks_fts');
        ftsAvailable = true;
        ftsCount = Sqflite.firstIntValue(ftsRows) ?? 0;
      } catch (_) {
        ftsAvailable = false;
      }

      // Educational database counts
      final eduDb = await EducationalDatabase.database;
      int conceptCount = 0, flashcardCount = 0, chapterCount = 0, quizCount = 0;
      try {
        conceptCount = Sqflite.firstIntValue(await eduDb.rawQuery('SELECT COUNT(*) FROM concepts')) ?? 0;
        flashcardCount = Sqflite.firstIntValue(await eduDb.rawQuery('SELECT COUNT(*) FROM flashcards')) ?? 0;
        chapterCount = Sqflite.firstIntValue(await eduDb.rawQuery('SELECT COUNT(*) FROM chapters')) ?? 0;
        quizCount = Sqflite.firstIntValue(await eduDb.rawQuery('SELECT COUNT(*) FROM quizzes')) ?? 0;
      } catch (_) {}

      // Educational FTS
      bool eduFtsAvailable = EducationalDatabase.isFullTextSearchAvailable;

      // Discovery
      final discovery = PiHubDiscoveryCoordinator();
      final connectivity = ConnectivityController();

      // SQLite version
      String sqliteVersion = 'unknown';
      try {
        final vRows = await appDb.rawQuery('SELECT sqlite_version()');
        sqliteVersion = vRows.first.values.first.toString();
      } catch (_) {}

      setState(() {
        _diagnostics['SQLite Version'] = sqliteVersion;
        _diagnostics['RAG Chunk Count'] = ragCount;
        _diagnostics['FTS Available'] = ftsAvailable ? 'YES ✓' : 'NO ✗';
        _diagnostics['FTS Row Count'] = ftsAvailable ? ftsCount : 'N/A';
        _diagnostics['Concepts'] = conceptCount;
        _diagnostics['Flashcards'] = flashcardCount;
        _diagnostics['Chapters'] = chapterCount;
        _diagnostics['Quizzes'] = quizCount;
        _diagnostics['Educational FTS'] = eduFtsAvailable ? 'YES ✓' : 'NO ✗';
        _diagnostics['Discovery Nodes'] = discovery.currentNodes.length;
        _diagnostics['Best Node'] = discovery.bestNode?.baseUrl ?? 'None';
        _diagnostics['Connectivity Mode'] = connectivity.mode.name;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _diagnostics['Error'] = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('System Diagnostics'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('Database', [
                  'SQLite Version',
                  'RAG Chunk Count',
                  'FTS Available',
                  'FTS Row Count',
                ]),
                const SizedBox(height: 16),
                _buildSection('Educational Content', [
                  'Concepts',
                  'Flashcards',
                  'Chapters',
                  'Quizzes',
                  'Educational FTS',
                ]),
                const SizedBox(height: 16),
                _buildSection('Network', [
                  'Discovery Nodes',
                  'Best Node',
                  'Connectivity Mode',
                ]),
                if (_diagnostics.containsKey('Error')) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Error: ${_diagnostics['Error']}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<String> keys) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...keys.where((k) => _diagnostics.containsKey(k)).map((key) => _buildRow(key, _diagnostics[key])),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    final valueStr = value.toString();
    final isPositive = valueStr.contains('✓') || valueStr == 'online';
    final isNegative = valueStr.contains('✗') || valueStr == 'offline' || valueStr == 'None';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            valueStr,
            style: TextStyle(
              color: isPositive
                  ? Colors.greenAccent
                  : isNegative
                      ? Colors.redAccent
                      : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
