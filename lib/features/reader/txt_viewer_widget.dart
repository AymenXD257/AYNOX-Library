import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/book_page_layout.dart';
import 'widgets/book_page_turn_view.dart';

class TxtViewerWidget extends StatefulWidget {
  final String filePath;
  final int initialPosition;
  final double fontSize;
  final double lineSpacing;
  final String readerTheme; // 'dark', 'light', 'sepia', 'book'
  final String pageTurnMode; // 'curl', 'slide', 'scroll'
  final String fontFamily;
  final Function(int position, int total, double progress) onProgressChanged;

  const TxtViewerWidget({
    super.key,
    required this.filePath,
    this.initialPosition = 0,
    required this.fontSize,
    required this.lineSpacing,
    required this.readerTheme,
    this.pageTurnMode = 'curl',
    this.fontFamily = 'Amiri',
    required this.onProgressChanged,
  });

  @override
  State<TxtViewerWidget> createState() => TxtViewerWidgetState();
}

class TxtViewerWidgetState extends State<TxtViewerWidget> {
  final GlobalKey<BookPageTurnViewState> _turnViewKey = GlobalKey<BookPageTurnViewState>();
  List<String> _pages = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  String _bookTitle = 'Document';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPosition;
    _loadText();
  }

  @override
  void didUpdateWidget(covariant TxtViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineSpacing != widget.lineSpacing) {
      _recalculatePages();
    }
  }

  String _rawText = '';

  Future<void> _loadText() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('Text document not found at: ${widget.filePath}');
      }

      final fileName = file.uri.pathSegments.last;
      _bookTitle = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');

      final bytes = await file.readAsBytes();
      String text;
      try {
        text = utf8.decode(bytes);
      } catch (_) {
        text = latin1.decode(bytes);
      }

      _rawText = text;
      _paginateText(_rawText);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final safePage = _currentPage.clamp(0, _pages.isEmpty ? 0 : _pages.length - 1);
        final progress = _pages.isNotEmpty ? safePage / _pages.length : 0.0;
        widget.onProgressChanged(safePage, _pages.length, progress);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _recalculatePages() {
    if (_rawText.isEmpty) return;
    final oldProgress = _pages.isNotEmpty ? _currentPage / _pages.length : 0.0;
    _paginateText(_rawText);
    _currentPage = (_pages.length * oldProgress).toInt().clamp(0, _pages.length - 1);
    setState(() {});
  }

  void _paginateText(String text) {
    // Character density scaling based on font size: ~20sp -> 900 chars/page, ~14sp -> 1600 chars/page
    final targetCharsPerPage = (18000 / (widget.fontSize * widget.lineSpacing)).toInt().clamp(600, 2500);

    final paragraphs = text.split(RegExp(r'\r?\n\r?\n'));
    final pagesList = <String>[];
    final currentBuffer = StringBuffer();

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      if (currentBuffer.length + trimmed.length > targetCharsPerPage) {
        if (currentBuffer.isNotEmpty) {
          pagesList.add(currentBuffer.toString().trim());
          currentBuffer.clear();
        }

        // If a single paragraph is larger than targetCharsPerPage, split into sentences
        if (trimmed.length > targetCharsPerPage) {
          final words = trimmed.split(' ');
          for (final w in words) {
            if (currentBuffer.length + w.length > targetCharsPerPage) {
              pagesList.add(currentBuffer.toString().trim());
              currentBuffer.clear();
            }
            currentBuffer.write('$w ');
          }
        } else {
          currentBuffer.writeln(trimmed);
          currentBuffer.writeln();
        }
      } else {
        currentBuffer.writeln(trimmed);
        currentBuffer.writeln();
      }
    }

    if (currentBuffer.isNotEmpty) {
      pagesList.add(currentBuffer.toString().trim());
    }

    if (pagesList.isEmpty) {
      pagesList.add('Empty document.');
    }

    _pages = pagesList;
  }

  void jumpToPage(int page) {
    _turnViewKey.currentState?.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load document:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final theme = BookPageThemeData.getTheme(widget.readerTheme);
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_rawText.substring(0, _rawText.length.clamp(0, 300)));

    return BookPageTurnView(
      key: _turnViewKey,
      itemCount: _pages.length,
      initialPage: _currentPage,
      mode: widget.pageTurnMode,
      isRtl: isArabic,
      onPageChanged: (pageIndex) {
        setState(() {
          _currentPage = pageIndex;
        });
        final total = _pages.length;
        final progress = total > 0 ? (pageIndex / total).clamp(0.0, 1.0) : 0.0;
        widget.onProgressChanged(pageIndex, total, progress);
      },
      pageBuilder: (context, pageIndex) {
        final content = _pages[pageIndex];

        return BookPageFrame(
          bookTitle: _bookTitle,
          chapterTitle: 'Section ${pageIndex + 1}',
          currentPage: pageIndex + 1,
          totalPages: _pages.length,
          readerTheme: widget.readerTheme,
          isRtl: isArabic,
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SelectableText(
                content,
                style: TextStyle(
                  color: theme.text,
                  fontSize: widget.fontSize,
                  height: widget.lineSpacing,
                  fontFamily: widget.fontFamily,
                  letterSpacing: isArabic ? 0.0 : 0.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
