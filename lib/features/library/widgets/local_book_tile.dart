import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../reader/reader_screen.dart';
import '../../details/book_details_screen.dart';
import '../../../core/localization/app_localizations.dart';

class LocalBookTile extends StatelessWidget {
  final Book book;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const LocalBookTile({
    super.key,
    required this.book,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final progressPct = (book.readingProgress * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (book.isPhysical) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover thumbnail with Hero animation
              Container(
                width: 62,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Hero(
                  tag: 'book_cover_${book.id}',
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildThumbPlaceholder(primary),
                        )
                      : _buildThumbPlaceholder(primary),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.isPhysical ? 'PHYSICAL' : book.format.toUpperCase(),
                            style: TextStyle(
                              color: primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          book.isImported
                              ? l10n.imported
                              : (book.isPhysical ? l10n.translate('owned_physically') : l10n.downloaded),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar for digital books
                    if (!book.isPhysical) ...[
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: book.readingProgress,
                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              color: primary,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progressPct%',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        book.publisher ?? 'Independent',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions Popup
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                onSelected: (val) {
                  if (val == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailsScreen(book: book),
                      ),
                    );
                  } else if (val == 'fav') {
                    onFavoriteToggle();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.translate('book_details')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'fav',
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.translate('add_to_fav')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          l10n.translate('remove_book'),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder(Color primary) {
    return Container(
      child: Center(
        child: Icon(Icons.menu_book, color: primary, size: 24),
      ),
    );
  }
}
