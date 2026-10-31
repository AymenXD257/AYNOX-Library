import 'package:flutter/material.dart';
import '../../services/reader/epub_parser.dart';
import 'widgets/book_page_layout.dart';
import 'widgets/book_page_turn_view.dart';

class EpubViewerWidget extends StatefulWidget {
  final String filePath;
  final int initialChapterIndex;
  final double fontSize;
  final double lineSpacing;
  final String readerTheme; // 'dark', 'light', 'sepia', 'book'
  final String pageTurnMode; // 'curl', 'slide', 'scroll'
  final String fontFamily;
  final Function(int chapterIndex, int totalChapters, String chapterTitle) onChapterChanged;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const EpubViewerWidget({
    super.key,
    required this.filePath,
    this.initialChapterIndex = 0,
    required this.fontSize,
    required this.lineSpacing,
    required this.readerTheme,
    this.pageTurnMode = 'curl',
    this.fontFamily = 'Amiri',
    required this.onChapterChanged,
    required this.scaffoldKey,
  });

  @override
  State<EpubViewerWidget> createState() => EpubViewerWidgetState();
}

class EpubViewerWidgetState extends State<EpubViewerWidget> {
  final GlobalKey<BookPageTurnViewState> _turnViewKey = GlobalKey<BookPageTurnViewState>();
  EpubBookData? _bookData;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentChapterIndex = 0;

  EpubBookData? get bookData => _bookData;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      final data = await EpubParser.parseEpubFile(widget.filePath);
      if (mounted) {
        setState(() {
          _bookData = data;
          _isLoading = false;
        });

        if (data.chapters.isNotEmpty) {
          final safeIndex = _currentChapterIndex.clamp(0, data.chapters.length - 1);
          widget.onChapterChanged(
            safeIndex,
            data.chapters.length,
            data.chapters[safeIndex].title,
          );
        }
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

  void jumpToChapter(int index) {
    if (_bookData == null || index < 0 || index >= _bookData!.chapters.length) return;
    _turnViewKey.currentState?.jumpToPage(index);
    setState(() {
      _currentChapterIndex = index;
    });
    widget.onChapterChanged(
      index,
      _bookData!.chapters.length,
      _bookData!.chapters[index].title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            const Text(
              'Parsing EPUB typography & assets...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _bookData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to open EPUB:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final chapters = _bookData!.chapters;
    final theme = BookPageThemeData.getTheme(widget.readerTheme);

    return BookPageTurnView(
      key: _turnViewKey,
      itemCount: chapters.length,
      initialPage: _currentChapterIndex,
      mode: widget.pageTurnMode,
      onPageChanged: (idx) {
        setState(() {
          _currentChapterIndex = idx;
        });
        widget.onChapterChanged(idx, chapters.length, chapters[idx].title);
      },
      pageBuilder: (context, chapterIdx) {
        final chapter = chapters[chapterIdx];
        final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(chapter.plainText.substring(0, chapter.plainText.length.clamp(0, 300)));

        return BookPageFrame(
          bookTitle: _bookData!.title,
          chapterTitle: chapter.title,
          currentPage: chapterIdx + 1,
          totalPages: chapters.length,
          readerTheme: widget.readerTheme,
          isRtl: isArabic,
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chapter Headline
                  Text(
                    chapter.title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: widget.fontSize + 6,
                      fontWeight: FontWeight.bold,
                      fontFamily: widget.fontFamily,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.textMuted.withValues(alpha: 0.2)),
                  const SizedBox(height: 14),

                  // Structured blocks
                  ...chapter.blocks.map((block) {
                    if (block.type == EpubBlockType.heading) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          block.text,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: widget.fontSize + 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: widget.fontFamily,
                          ),
                        ),
                      );
                    } else if (block.type == EpubBlockType.image && block.imageBytes != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              block.imageBytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      );
                    } else if (block.type == EpubBlockType.quote) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            left: isArabic ? BorderSide.none : BorderSide(color: theme.textMuted, width: 3),
                            right: isArabic ? BorderSide(color: theme.textMuted, width: 3) : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          block.text,
                          style: TextStyle(
                            color: theme.text.withValues(alpha: 0.85),
                            fontSize: widget.fontSize - 1,
                            fontStyle: FontStyle.italic,
                            fontFamily: widget.fontFamily,
                            height: widget.lineSpacing,
                          ),
                        ),
                      );
                    } else {
                      // Paragraph
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SelectableText(
                          block.text,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: widget.fontSize,
                            height: widget.lineSpacing,
                            fontFamily: widget.fontFamily,
                            letterSpacing: isArabic ? 0.0 : 0.15,
                          ),
                        ),
                      );
                    }
                  }),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
