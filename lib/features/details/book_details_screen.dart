import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../reader/reader_screen.dart';

class BookDetailsScreen extends StatelessWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final libraryProv = Provider.of<LibraryProvider>(context);
    final downloadProv = Provider.of<DownloadProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final primary = theme.colorScheme.primary;

    // Look up book in library to see if it was downloaded or imported
    final localBook = libraryProv.getBookById(book.id) ?? book;
    final isLocal = localBook.isLocal;
    final isFav = libraryProv.isFavorite(book.id);
    final isOwned = libraryProv.isOwned(book.id) || localBook.isOwnedPhysically;
    final isWishlisted = libraryProv.isWishlisted(book.id) || localBook.isWishlisted;
    final isDownloading = downloadProv.isDownloading(book.id);
    final downloadProgress = downloadProv.getProgress(book.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('book_details')),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? const Color(0xFFEF4444) : null,
            ),
            tooltip: isFav ? l10n.translate('remove_fav') : l10n.translate('add_to_fav'),
            onPressed: () {
              libraryProv.toggleFavorite(book.id);
            },
          ),
          if (isLocal)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.translate('remove_book'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.translate('remove_book')),
                    content: Text('Are you sure you want to remove "${book.title}" from your library?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.translate('delete_file'), style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await libraryProv.removeBook(book.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cover & Title Card with Hero
            Center(
              child: Container(
                width: 165,
                height: 235,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Hero(
                  tag: 'book_cover_${book.id}',
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackCover(context, book),
                        )
                      : _buildFallbackCover(context, book),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title & Author
            Center(
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                book.author,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Chips Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoBadge(context, Icons.source_outlined, book.source),
                _buildInfoBadge(context, Icons.language, book.language.toUpperCase()),
                _buildInfoBadge(
                  context,
                  book.isPhysical ? Icons.book : Icons.description_outlined,
                  book.isPhysical ? 'PHYSICAL' : book.format.toUpperCase(),
                ),
                _buildInfoBadge(
                  context,
                  Icons.verified_outlined,
                  book.rightsStatus == 'open_access'
                      ? l10n.translate('open_access')
                      : (book.isPhysical ? l10n.translate('physical_books') : l10n.translate('public_domain')),
                  color: const Color(0xFF10B981),
                ),
                if (book.publishYear != null)
                  _buildInfoBadge(context, Icons.calendar_today, '${book.publishYear}'),
                if (book.isbn != null)
                  _buildInfoBadge(context, Icons.qr_code, 'ISBN: ${book.isbn}'),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons: DIGITAL vs PHYSICAL distinction
            if (book.isPhysical) ...[
              // Physical book actions (never presented as downloadable!)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwned ? const Color(0xFF10B981) : primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(isOwned ? Icons.check_circle : Icons.home),
                      label: Text(
                        isOwned ? l10n.translate('owned_physically') : l10n.translate('mark_owned'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        libraryProv.toggleOwnedPhysically(localBook);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    icon: Icon(isWishlisted ? Icons.bookmark_added : Icons.bookmark_add_outlined),
                    tooltip: isWishlisted ? l10n.translate('remove_from_wishlist') : l10n.translate('add_to_wishlist'),
                    onPressed: () {
                      libraryProv.toggleWishlist(localBook);
                    },
                  ),
                ],
              ),
            ] else if (isLocal) ...[
              // Local downloaded or imported digital book
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.menu_book),
                  label: Text(
                    l10n.readNow,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(book: localBook),
                      ),
                    );
                  },
                ),
              ),
              if (localBook.readingProgress > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('reading_progress'), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                    Text('${(localBook.readingProgress * 100).toInt()}%', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: localBook.readingProgress,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  color: primary,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ] else ...[
              // Remote digital book ready to download
              SizedBox(
                width: double.infinity,
                height: 48,
                child: isDownloading
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: downloadProgress > 0 ? downloadProgress : null,
                                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                color: primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(downloadProgress * 100).toInt()}%',
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => downloadProv.cancelDownload(book.id),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.download),
                        label: Text(
                          l10n.download,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () async {
                          final success = await downloadProv.startDownload(
                            book: book,
                            libraryProvider: libraryProv,
                            preferredFormat: settingsProv.preferredFormat,
                          );
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${book.title} downloaded to library!')),
                            );
                          }
                        },
                      ),
              ),
            ],
            const SizedBox(height: 28),

            // Description Section
            Text(
              l10n.translate('description'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                book.description.isNotEmpty ? book.description : l10n.translate('no_description'),
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.6, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Add to Collection button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: Text(l10n.translate('collections')),
              onPressed: () => _showAddToCollectionDialog(context, libraryProv, book),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(book.isPhysical ? Icons.book : Icons.auto_stories, color: primary, size: 36),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(BuildContext context, IconData icon, String label, {Color? color}) {
    final primary = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionDialog(BuildContext context, LibraryProvider prov, Book book) {
    final collections = prov.collections;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('collections'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (collections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        l10n.translate('no_results'),
                        style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    )
                  else
                    ...collections.map((col) {
                      final hasBook = col.bookIds.contains(book.id);
                      return CheckboxListTile(
                        title: Text(col.name),
                        value: hasBook,
                        activeColor: Theme.of(ctx).colorScheme.primary,
                        onChanged: (val) async {
                          await prov.toggleBookInCollection(col.id, book.id);
                          setModalState(() {});
                        },
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
