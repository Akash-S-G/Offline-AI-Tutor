import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/experiment_lab_report.dart';

class ReportExporter {
  String exportJson(ExperimentLabReport report) {
    return const JsonEncoder.withIndent('  ').convert(report.toJson());
  }

  Uint8List exportPdf(ExperimentLabReport report) {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    var y = 24.0;
    y = _draw(graphics, report.title, titleFont, y);
    y = _draw(
      graphics,
      'Date: ${report.generatedAt.toIso8601String()}',
      bodyFont,
      y,
    );
    if (report.mission != null) {
      y = _draw(graphics, 'Mission: ${report.mission!.title}', bodyFont, y);
      y = _draw(
        graphics,
        'Objective: ${report.mission!.objective}',
        bodyFont,
        y,
      );
    }
    y = _draw(graphics, 'Trials: ${report.trials.length}', bodyFont, y);
    y = _draw(
      graphics,
      'Observations: ${report.observations.length}',
      bodyFont,
      y,
    );
    y = _draw(
      graphics,
      'Comparisons: ${report.comparisons.length}',
      bodyFont,
      y,
    );
    y = _draw(graphics, 'Conclusion: ${report.conclusion}', bodyFont, y);
    final result = report.assessmentResult;
    if (result != null) {
      y = _draw(
        graphics,
        'Score: ${result.score.toStringAsFixed(1)}% (${result.passed ? 'Pass' : 'Needs Review'})',
        bodyFont,
        y,
      );
    }
    for (final outcome in report.learningOutcomes) {
      y = _draw(
        graphics,
        'Outcome ${outcome.outcomeId}: ${outcome.status.name}',
        bodyFont,
        y,
      );
    }
    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  double _draw(PdfGraphics graphics, String text, PdfFont font, double y) {
    graphics.drawString(text, font, bounds: Rect.fromLTWH(24, y, 500, 36));
    return y + 24;
  }
}
