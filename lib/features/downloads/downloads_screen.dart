import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../library/widgets/local_book_tile.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final libraryProv = Provider.of<LibraryProvider>(context);
    final downloadProv = Provider.of<DownloadProvider>(context);
    final settingsProv = Provider.of<SettingsProvider>(context);
    final primary = theme.colorScheme.primary;

    final downloadedBooks = libraryProv.allBooksRaw.where((b) => b.isDownloaded).toList();
    final activeTasks = downloadProv.activeTasks;
    final failedDownloads = downloadProv.failedDownloads;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloads),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sd_storage, color: primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('storage_info'),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settingsProv.storageFormatted,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${downloadedBooks.length} ${l10n.translate("downloaded")}',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: primary),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    onPressed: () => settingsProv.refreshStorageUsage(),
                  ),
                ],
              ),
            ),

            // Active Downloads
            if (activeTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${l10n.translate("active_downloads")} (${activeTasks.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...activeTasks.entries.map((entry) {
                final id = entry.key;
                final task = entry.value;
                final pct = ((task.progress ?? 0.0) * 100).toInt();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Text('$pct%', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => downloadProv.cancelDownload(id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: task.progress != null && task.progress! > 0 ? task.progress : null,
                        color: primary,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Failed Downloads (with Retry & explanation)
            if (failedDownloads.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${l10n.translate("failed_downloads")} (${failedDownloads.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
              ...failedDownloads.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Downloaded Books List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${l10n.translate("completed_downloads")} (${downloadedBooks.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (downloadedBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_download_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.translate('no_active_downloads'),
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Browse Discover to find classics to download and read offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...downloadedBooks.map((b) => LocalBookTile(
                    book: b,
                    onFavoriteToggle: () => libraryProv.toggleFavorite(b.id),
                    onDelete: () async {
                      await libraryProv.removeBook(b.id);
                      await settingsProv.refreshStorageUsage();
                    },
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
