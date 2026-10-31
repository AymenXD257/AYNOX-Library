import 'package:flutter/foundation.dart';
import '../../models/book.dart';
import '../../services/storage/file_storage_service.dart';
import 'library_provider.dart';

class DownloadTask {
  final Book book;
  final String format;
  final DateTime startedAt;
  double? progress;
  bool isCancelled;

  DownloadTask({
    required this.book,
    required this.format,
    this.progress = 0.05,
    this.isCancelled = false,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();
}

class DownloadProvider extends ChangeNotifier {
  final Map<String, DownloadTask> _activeTasks = {};
  final List<Book> _completedDownloads = [];
  final Map<String, String> _failedDownloads = {};

  Map<String, DownloadTask> get activeTasks => _activeTasks;
  Set<String> get activeDownloads => _activeTasks.keys.toSet();
  List<Book> get completedDownloads => _completedDownloads;
  Map<String, String> get failedDownloads => _failedDownloads;

  bool isDownloading(String bookId) => _activeTasks.containsKey(bookId);
  double getProgress(String bookId) => _activeTasks[bookId]?.progress ?? 0.0;
  String? getError(String bookId) => _failedDownloads[bookId];

  void cancelDownload(String bookId) {
    if (_activeTasks.containsKey(bookId)) {
      _activeTasks[bookId]!.isCancelled = true;
      _activeTasks.remove(bookId);
      _failedDownloads[bookId] = 'Download cancelled by user';
      notifyListeners();
    }
  }

  Future<bool> startDownload({
    required Book book,
    required LibraryProvider libraryProvider,
    String preferredFormat = 'epub',
  }) async {
    if (isDownloading(book.id)) return false;

    // Check if book has download URLs
    if (book.downloadUrls.isEmpty) {
      _failedDownloads[book.id] = 'No digital download available for this book (physical record).';
      notifyListeners();
      return false;
    }

    // Determine format order based on user preference: preferred -> alternatives
    final formatOrder = <String>[];
    if (book.downloadUrls.containsKey(preferredFormat)) {
      formatOrder.add(preferredFormat);
    }
    for (final fmt in ['pdf', 'epub', 'txt']) {
      if (!formatOrder.contains(fmt) && book.downloadUrls.containsKey(fmt)) {
        formatOrder.add(fmt);
      }
    }

    if (formatOrder.isEmpty) {
      _failedDownloads[book.id] = 'No supported format available.';
      notifyListeners();
      return false;
    }

    _failedDownloads.remove(book.id);
    final task = DownloadTask(book: book, format: formatOrder.first);
    _activeTasks[book.id] = task;
    notifyListeners();

    // Attempt download with fallback to alternative formats if one fails
    Object? finalException;
    for (final currentFormat in formatOrder) {
      if (task.isCancelled) {
        _activeTasks.remove(book.id);
        notifyListeners();
        return false;
      }

      final url = book.downloadUrls[currentFormat]!;
      try {
        final localPath = await FileStorageService.downloadBookFile(
          url: url,
          bookId: book.id,
          format: currentFormat,
          isCancelled: () => task.isCancelled,
          onProgress: (p) {
            task.progress = p ?? 0.0;
            notifyListeners();
          },
        );

        // Register in user's library
        await libraryProvider.addDownloadedBook(book, localPath, currentFormat);

        _completedDownloads.add(book);
        _activeTasks.remove(book.id);
        _failedDownloads.remove(book.id);
        notifyListeners();
        return true;
      } catch (e) {
        finalException = e;
        if (e is DownloadCancellationException || task.isCancelled) {
          _activeTasks.remove(book.id);
          _failedDownloads[book.id] = 'Cancelled';
          notifyListeners();
          return false;
        }
        // Fallback to next format in loop...
      }
    }

    // If all formats failed
    _activeTasks.remove(book.id);
    _failedDownloads[book.id] = 'Download failed: $finalException';
    notifyListeners();
    return false;
  }
}
