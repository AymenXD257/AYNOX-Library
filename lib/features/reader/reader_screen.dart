import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/bookmark.dart';
import '../../providers/library_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/storage/local_library_service.dart';
import '../../core/localization/app_localizations.dart';
import 'pdf_viewer_widget.dart';
import 'epub_viewer_widget.dart';
import 'txt_viewer_widget.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<EpubViewerWidgetState> _epubKey = GlobalKey<EpubViewerWidgetState>();
  final GlobalKey<TxtViewerWidgetState> _txtKey = GlobalKey<TxtViewerWidgetState>();
  final GlobalKey<PdfViewerWidgetState> _pdfKey = GlobalKey<PdfViewerWidgetState>();

  bool _isFullScreen = false;
  int _currentPosition = 0;
  int _totalUnits = 1;
  double _progress = 0.0;
  String _currentChapterTitle = '';
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.book.lastPosition;
    _progress = widget.book.readingProgress;
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final list = await LocalLibraryService.loadBookmarks(widget.book.id);
    if (mounted) {
      setState(() {
        _bookmarks = list;
      });
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _saveProgress() {
    final libraryProv = Provider.of<LibraryProvider>(context, listen: false);
    libraryProv.updateReadingProgress(
      bookId: widget.book.id,
      progress: _progress,
      position: _currentPosition,
      totalUnits: _totalUnits,
    );
  }

  Future<void> _addBookmark() async {
    final l10n = AppLocalizations.of(context);
    final title = _currentChapterTitle.isNotEmpty
        ? _currentChapterTitle
        : '${l10n.translate("page")} ${_currentPosition + 1}';

    final newBm = Bookmark(
      id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
      bookId: widget.book.id,
      title: title,
      location: _currentPosition,
      snippet: '${l10n.translate("reading_progress")}: ${(_progress * 100).toInt()}%',
    );

    setState(() {
      _bookmarks.add(newBm);
    });
    await LocalLibraryService.saveBookmarks(widget.book.id, _bookmarks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate("bookmarks")}: $title'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showTableOfContents() {
    final epubState = _epubKey.currentState;
    final toc = epubState?.bookData?.tableOfContents ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? const Color(0xFF141A29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('table_of_contents'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              if (toc.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.translate('no_results'),
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: toc.length,
                    itemBuilder: (context, i) {
                      final item = toc[i];
                      final isCurrent = item.chapterIndex == _currentPosition;
                      return ListTile(
                        leading: Icon(
                          Icons.menu_book,
                          size: 18,
                          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          epubState?.jumpToChapter(item.chapterIndex);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsModal() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? const Color(0xFF141A29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<SettingsProvider>(
              builder: (context, prov, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.translate('reader_settings'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Background & Paper Style: Dark, Light, Sepia, Book Paper
                      Text(
                        l10n.translate('paper_style'),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _themeOption('dark', l10n.translate('paper_dark'), const Color(0xFF0C101A), const Color(0xFFE2E8F0), prov),
                          const SizedBox(width: 8),
                          _themeOption('light', l10n.translate('paper_light'), const Color(0xFFFAFAFA), const Color(0xFF1E293B), prov),
                          const SizedBox(width: 8),
                          _themeOption('sepia', l10n.translate('paper_sepia'), const Color(0xFFF4ECD8), const Color(0xFF3E2D1D), prov),
                          const SizedBox(width: 8),
                          _themeOption('book', l10n.translate('paper_book'), const Color(0xFFF6F0E4), const Color(0xFF2C241B), prov),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Page Turn Mode: Curl, Slide, Scroll
                      Text(
                        l10n.translate('page_turn_mode'),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _turnOption('curl', l10n.translate('mode_curl'), Icons.auto_stories, prov),
                          const SizedBox(width: 8),
                          _turnOption('slide', l10n.translate('mode_slide'), Icons.swipe, prov),
                          const SizedBox(width: 8),
                          _turnOption('scroll', l10n.translate('mode_scroll'), Icons.swap_vert, prov),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Font size slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.translate('font_size')),
                          Text('${prov.fontSize.toInt()} sp', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: prov.fontSize,
                        min: 12.0,
                        max: 30.0,
                        divisions: 9,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                          prov.setFontSize(val);
                          setModalState(() {});
                        },
                      ),

                      // Line spacing slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.translate('line_spacing')),
                          Text('${prov.lineSpacing.toStringAsFixed(1)}x', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: prov.lineSpacing,
                        min: 1.2,
                        max: 2.2,
                        divisions: 5,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                          prov.setLineSpacing(val);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _themeOption(String themeKey, String label, Color bg, Color textColor, SettingsProvider prov) {
    final isSelected = prov.readerTheme == themeKey;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => prov.setReaderTheme(themeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primary : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label.split(' ').first,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _turnOption(String modeKey, String label, IconData icon, SettingsProvider prov) {
    final isSelected = prov.pageTurnMode == modeKey;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? primary.withValues(alpha: 0.15) : null,
          side: BorderSide(color: isSelected ? primary : Colors.grey.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => prov.setPageTurnMode(modeKey),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? primary : null),
            const SizedBox(height: 4),
            Text(
              label.split(' ').first,
              style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksModal() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? const Color(0xFF141A29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('bookmarks'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              if (_bookmarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      l10n.translate('no_results'),
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, i) {
                      final bm = _bookmarks[i];
                      return ListTile(
                        leading: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
                        title: Text(bm.title),
                        subtitle: Text(bm.snippet, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(ctx);
                          if (widget.book.format == 'epub') {
                            _epubKey.currentState?.jumpToChapter(bm.location);
                          } else if (widget.book.format == 'txt') {
                            _txtKey.currentState?.jumpToPage(bm.location);
                          } else if (widget.book.format == 'pdf') {
                            _pdfKey.currentState?.jumpToPage(bm.location);
                          }
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            setState(() {
                              _bookmarks.removeAt(i);
                            });
                            await LocalLibraryService.saveBookmarks(widget.book.id, _bookmarks);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final filePath = widget.book.localFilePath ?? '';
    final format = widget.book.format.toLowerCase();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _saveProgress();
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _isFullScreen
            ? null
            : AppBar(
                title: Text(
                  widget.book.title,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (format == 'epub')
                    IconButton(
                      icon: const Icon(Icons.list_alt),
                      tooltip: 'Table of Contents',
                      onPressed: _showTableOfContents,
                    ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: 'Add Bookmark',
                    onPressed: _addBookmark,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmarks_outlined),
                    tooltip: 'View Bookmarks',
                    onPressed: _showBookmarksModal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Reader Customization',
                    onPressed: _showSettingsModal,
                  ),
                  IconButton(
                    icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                    tooltip: 'Full Screen',
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
        body: GestureDetector(
          onDoubleTap: _toggleFullScreen,
          child: Column(
            children: [
              Expanded(
                child: _buildReaderBody(filePath, format, settings),
              ),
              if (!_isFullScreen) _buildBottomStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderBody(String filePath, String format, SettingsProvider settings) {
    if (format == 'pdf') {
      return PdfViewerWidget(
        key: _pdfKey,
        filePath: filePath,
        initialPage: _currentPosition,
        isDarkMode: settings.readerTheme == 'dark',
        onPageChanged: (page, total) {
          setState(() {
            _currentPosition = page;
            _totalUnits = total;
            _progress = total > 0 ? (page / total).clamp(0.0, 1.0) : 0.0;
          });
        },
      );
    } else if (format == 'epub') {
      return EpubViewerWidget(
        key: _epubKey,
        scaffoldKey: _scaffoldKey,
        filePath: filePath,
        initialChapterIndex: _currentPosition,
        fontSize: settings.fontSize,
        lineSpacing: settings.lineSpacing,
        readerTheme: settings.readerTheme,
        pageTurnMode: settings.pageTurnMode,
        fontFamily: settings.fontFamily,
        onChapterChanged: (chapterIdx, totalChapters, title) {
          setState(() {
            _currentPosition = chapterIdx;
            _totalUnits = totalChapters;
            _currentChapterTitle = title;
            _progress = totalChapters > 0 ? (chapterIdx / totalChapters).clamp(0.0, 1.0) : 0.0;
          });
        },
      );
    } else {
      // Default to TXT viewer
      return TxtViewerWidget(
        key: _txtKey,
        filePath: filePath,
        initialPosition: _currentPosition,
        fontSize: settings.fontSize,
        lineSpacing: settings.lineSpacing,
        readerTheme: settings.readerTheme,
        pageTurnMode: settings.pageTurnMode,
        fontFamily: settings.fontFamily,
        onProgressChanged: (pos, total, progress) {
          setState(() {
            _currentPosition = pos;
            _totalUnits = total;
            _progress = progress;
          });
        },
      );
    }
  }

  Widget _buildBottomStatusBar() {
    final pct = (_progress * 100).toInt();
    final format = widget.book.format.toUpperCase();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                format,
                style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                color: primary,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$pct%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
