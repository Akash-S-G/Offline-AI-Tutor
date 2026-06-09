import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/idp_colors.dart';
import '../domain/challenge.dart';
import 'widgets/challenge_card.dart';
import 'widgets/concept_card.dart';
import 'widgets/observation_panel.dart';

class StatisticsLabScreen extends StatefulWidget {
  final MathChallenge? challenge;

  const StatisticsLabScreen({super.key, this.challenge});

  @override
  State<StatisticsLabScreen> createState() => _StatisticsLabScreenState();
}

class _StatisticsLabScreenState extends State<StatisticsLabScreen> {
  final TextEditingController _dataController = TextEditingController(text: '1, 4, 7, 9, 10, 4, 6, 7, 7');
  final TextEditingController _notesController = TextEditingController();
  
  List<double> _data = [];
  String? _error;

  double _mean = 0;
  double _median = 0;
  List<double> _modes = [];
  double _range = 0;

  @override
  void initState() {
    super.initState();
    _dataController.addListener(_processData);
    _processData();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _processData() {
    final raw = _dataController.text.split(',');
    List<double> parsed = [];
    
    for (final s in raw) {
      final val = double.tryParse(s.trim());
      if (val != null) {
        parsed.add(val);
      }
    }

    if (parsed.isEmpty) {
      setState(() {
        _data = [];
        _error = "Please enter valid comma-separated numbers.";
      });
      return;
    }

    parsed.sort();

    // Calculate Mean
    double sum = parsed.fold(0, (a, b) => a + b);
    final mean = sum / parsed.length;

    // Calculate Median
    double median;
    int mid = parsed.length ~/ 2;
    if (parsed.length % 2 == 0) {
      median = (parsed[mid - 1] + parsed[mid]) / 2.0;
    } else {
      median = parsed[mid];
    }

    // Calculate Mode
    Map<double, int> counts = {};
    for (final v in parsed) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    
    int maxCount = 0;
    for (final c in counts.values) {
      if (c > maxCount) maxCount = c;
    }
    
    List<double> modes = [];
    if (maxCount > 1) {
      counts.forEach((k, v) {
        if (v == maxCount) modes.add(k);
      });
    }

    // Calculate Range
    final range = parsed.last - parsed.first;

    setState(() {
      _data = parsed;
      _mean = mean;
      _median = median;
      _modes = modes;
      _range = range;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IDPColors.background,
      appBar: AppBar(
        title: const Text('Statistics Workspace'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.challenge != null)
              ChallengeCard(
                challenge: widget.challenge!,
                isCompleted: widget.challenge!.verifier({
                  'mean': _mean,
                  'modes': _modes,
                  'median': _median,
                  'range': _range,
                }),
              ),
            const ConceptCard(
              title: 'Central Tendency',
              description: 'Mean, Median, and Mode are measures of central tendency, representing the center or typical value of a dataset.',
              example: 'A teacher wants to know the average score of a test. She calculates the mean. If one student scored very low (an outlier), she might use the median instead to get a better representation of the typical score.',
              icon: Icons.auto_graph_rounded,
              color: Color(0xFFDC2626),
            ),
            _buildInputSection(),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            if (_data.isNotEmpty) ...[
              _buildStatsGrid(),
              _buildCharts(),
            ],
            ObservationPanel(controller: _notesController),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IDPColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Set (Comma Separated)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _dataController,
            decoration: InputDecoration(
              hintText: 'e.g. 1, 4, 7, 9, 10',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Count: ${_data.length}', style: const TextStyle(color: IDPColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('Mean', _mean.toStringAsFixed(2)),
        _buildStatCard('Median', _median.toStringAsFixed(2)),
        _buildStatCard('Mode', _modes.isEmpty ? 'None' : _modes.map((e) => e.toStringAsFixed(1)).join(', ')),
        _buildStatCard('Range', _range.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      children: [
        const Text('Histogram (Frequency)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: IDPColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: CustomPaint(
              painter: _HistogramPainter(_data),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<double> data;

  _HistogramPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    Map<double, int> counts = {};
    for (final v in data) {
      counts[v] = (counts[v] ?? 0) + 1;
    }

    final uniqueVals = counts.keys.toList()..sort();
    final maxCount = counts.values.reduce(math.max);

    final barWidth = size.width / uniqueVals.length;
    final paint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < uniqueVals.length; i++) {
      final val = uniqueVals[i];
      final count = counts[val]!;
      
      final barHeight = (count / maxCount) * (size.height - 30); // leave room for labels
      
      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - barHeight - 20,
        barWidth,
        barHeight,
      );
      
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Value label
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(0),
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      tp.paint(canvas, Offset(i * barWidth + barWidth / 2 - tp.width / 2, size.height - 15));
      
      // Count label
      final countTp = TextPainter(
        text: TextSpan(
          text: count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      countTp.paint(canvas, Offset(i * barWidth + barWidth / 2 - countTp.width / 2, rect.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) => true;
}
