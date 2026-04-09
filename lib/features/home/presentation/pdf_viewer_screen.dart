import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    required this.filePath,
    required this.title,
    super.key,
  });

  final String filePath;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _validateFile();
  }

  Future<void> _validateFile() async {
    final exists = await File(widget.filePath).exists();
    if (!mounted) {
      return;
    }

    if (!exists) {
      setState(() {
        _error = 'File not found: ${widget.filePath}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF0B6E4F),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
          else
            PDFView(
              filePath: widget.filePath,
              autoSpacing: true,
              enableSwipe: true,
              swipeHorizontal: false,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _totalPages = pages ?? 0;
                  _isLoading = false;
                });
              },
              onPageChanged: (page, total) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _currentPage = (page ?? 0) + 1;
                  _totalPages = total ?? _totalPages;
                });
              },
              onError: (error) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _error = 'PDF render error: $error';
                  _isLoading = false;
                });
              },
              onPageError: (page, error) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  final pageNumber = (page ?? 0) + 1;
                  _error = 'Page $pageNumber error: $error';
                  _isLoading = false;
                });
              },
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (!_isLoading && _error == null && _totalPages > 0)
            Positioned(
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '$_currentPage/$_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
