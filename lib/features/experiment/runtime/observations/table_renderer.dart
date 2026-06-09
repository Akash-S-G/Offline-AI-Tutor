import 'package:flutter/material.dart';

import '../objects/renderers/runtime_object_renderer.dart';
import 'table_behavior.dart';

class TableRenderer extends PlaceholderRuntimeObjectRenderer {
  TableState tableState = const TableState.empty();

  void updateTableState(TableState state) {
    tableState = state;
  }

  @override
  void render(Canvas canvas, Size size) {
    if (shouldSkipRender()) return;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      Paint()
        ..color = Colors.blueGrey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (tableState.rowCount == 0 || tableState.columns.isEmpty) {
      _paintText(
        canvas,
        'No Observations',
        Offset.zero,
        const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        maxWidth: size.width,
        y: size.height / 2 - 10,
        align: TextAlign.center,
      );
      markRendered();
      return;
    }

    _renderTable(canvas, size);
    markRendered();
  }

  void _renderTable(Canvas canvas, Size size) {
    const left = 10.0;
    const top = 10.0;
    const rowHeight = 22.0;
    final columns = tableState.columns.take(5).toList(growable: false);
    final columnWidth = (size.width - left * 2) / columns.length;
    final headerPaint = Paint()..color = Colors.blueGrey.shade50;
    canvas.drawRect(
      Rect.fromLTWH(left, top, size.width - left * 2, rowHeight),
      headerPaint,
    );

    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      _paintText(
        canvas,
        columns[columnIndex],
        Offset(left + columnWidth * columnIndex + 4, top + 4),
        const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        maxWidth: columnWidth - 8,
      );
    }

    final maxRows = ((size.height - top - rowHeight - 8) / rowHeight)
        .floor()
        .clamp(0, tableState.rows.length);
    final rows = tableState.rows
        .skip(
          tableState.rows.length > maxRows
              ? tableState.rows.length - maxRows
              : 0,
        )
        .toList(growable: false);
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final y = top + rowHeight * (rowIndex + 1);
      if (rowIndex.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(left, y, size.width - left * 2, rowHeight),
          Paint()..color = Colors.grey.shade50,
        );
      }
      final row = rows[rowIndex];
      for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
        final column = columns[columnIndex];
        _paintText(
          canvas,
          _formatCell(row[column]),
          Offset(left + columnWidth * columnIndex + 4, y + 4),
          const TextStyle(color: Colors.black87, fontSize: 12),
          maxWidth: columnWidth - 8,
        );
      }
    }
  }

  String _formatCell(dynamic value) {
    if (value == null) return '';
    if (value is double) return value.toStringAsFixed(1);
    return value.toString();
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
    double? y,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    final x = align == TextAlign.center
        ? offset.dx + (maxWidth - painter.width) / 2
        : offset.dx;
    painter.paint(canvas, Offset(x, y ?? offset.dy));
  }
}
