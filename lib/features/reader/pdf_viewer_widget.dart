import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerWidget extends StatefulWidget {
  final String filePath;
  final int initialPage;
  final bool isDarkMode;
  final Function(int page, int total) onPageChanged;

  const PdfViewerWidget({
    super.key,
    required this.filePath,
    this.initialPage = 0,
    this.isDarkMode = false,
    required this.onPageChanged,
  });

  @override
  State<PdfViewerWidget> createState() => PdfViewerWidgetState();
}

class PdfViewerWidgetState extends State<PdfViewerWidget> {
  PDFViewController? _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';

  int get totalPages => _totalPages;
  int get currentPage => _currentPage;

  void jumpToPage(int page) {
    if (_pdfViewController != null && page >= 0 && page < _totalPages) {
      _pdfViewController!.setPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PDFView(
          filePath: widget.filePath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: widget.initialPage,
          fitPolicy: FitPolicy.BOTH,
          nightMode: widget.isDarkMode,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 1;
              _isReady = true;
            });
            widget.onPageChanged(widget.initialPage, _totalPages);
          },
          onError: (error) {
            setState(() {
              _errorMessage = error.toString();
            });
          },
          onPageError: (page, error) {
            setState(() {
              _errorMessage = 'Page $page error: ${error.toString()}';
            });
          },
          onViewCreated: (PDFViewController controller) {
            _pdfViewController = controller;
          },
          onPageChanged: (int? page, int? total) {
            final p = page ?? 0;
            final t = total ?? 1;
            setState(() {
              _currentPage = p;
              _totalPages = t;
            });
            widget.onPageChanged(p, t);
          },
        ),
        if (!_isReady && _errorMessage.isEmpty)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00E5FF)),
                SizedBox(height: 16),
                Text('Rendering document pages...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        if (_errorMessage.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading document:\n$_errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
