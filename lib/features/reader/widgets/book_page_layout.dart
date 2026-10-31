import 'package:flutter/material.dart';

class BookPageThemeData {
  final Color background;
  final Color text;
  final Color textMuted;
  final Color spineShadow;
  final Color edgeHighlight;

  const BookPageThemeData({
    required this.background,
    required this.text,
    required this.textMuted,
    required this.spineShadow,
    required this.edgeHighlight,
  });

  static BookPageThemeData getTheme(String themeKey) {
    switch (themeKey) {
      case 'light':
        return const BookPageThemeData(
          background: Color(0xFFFAFAFA),
          text: Color(0xFF1E293B),
          textMuted: Color(0xFF94A3B8),
          spineShadow: Color(0x12000000),
          edgeHighlight: Color(0x08000000),
        );
      case 'sepia':
        return const BookPageThemeData(
          background: Color(0xFFF4ECD8),
          text: Color(0xFF3E2D1D),
          textMuted: Color(0xFF8C7561),
          spineShadow: Color(0x1F3E2D1D),
          edgeHighlight: Color(0x0F3E2D1D),
        );
      case 'book':
        return const BookPageThemeData(
          background: Color(0xFFF6F0E4),
          text: Color(0xFF2C241B),
          textMuted: Color(0xFF7A6C5D),
          spineShadow: Color(0x242C241B),
          edgeHighlight: Color(0x122C241B),
        );
      case 'dark':
      default:
        return const BookPageThemeData(
          background: Color(0xFF0C101A),
          text: Color(0xFFE2E8F0),
          textMuted: Color(0xFF64748B),
          spineShadow: Color(0x52000000),
          edgeHighlight: Color(0x1A00E5FF),
        );
    }
  }
}

class BookPageFrame extends StatelessWidget {
  final String bookTitle;
  final String chapterTitle;
  final int currentPage;
  final int totalPages;
  final String readerTheme;
  final bool isRtl;
  final Widget child;

  const BookPageFrame({
    super.key,
    required this.bookTitle,
    required this.chapterTitle,
    required this.currentPage,
    required this.totalPages,
    required this.readerTheme,
    this.isRtl = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = BookPageThemeData.getTheme(readerTheme);

    return Container(
      color: theme.background,
      child: Stack(
        children: [
          // Paper-like subtle spine shadow on inner edge
          Positioned(
            top: 0,
            bottom: 0,
            left: isRtl ? null : 0,
            right: isRtl ? 0 : null,
            width: 14,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    theme.spineShadow,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main page layout with running header and footer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Running Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chapterTitle.isNotEmpty ? chapterTitle : bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentPage / $totalPages',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: theme.textMuted.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),

                  // Page Content
                  Expanded(child: child),

                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: theme.textMuted.withValues(alpha: 0.2),
                  ),

                  // Running Footer with subtle progress
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textMuted.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          totalPages > 0
                              ? '${((currentPage / totalPages) * 100).toInt()}%'
                              : '0%',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
