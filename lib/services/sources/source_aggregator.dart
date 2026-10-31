import 'dart:async';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import 'book_source.dart';
import 'gutendex_source.dart';
import 'open_library_source.dart';
import 'internet_archive_source.dart';
import 'arabic_heritage_source.dart';
import 'standard_ebooks_source.dart';
import 'doab_source.dart';

class AggregateSearchResult {
  final List<Book> books;
  final Map<String, SourceDiagnostic> diagnostics;
  final int totalCount;
  final bool hasNextPage;

  AggregateSearchResult({
    required this.books,
    required this.diagnostics,
    required this.totalCount,
    this.hasNextPage = true,
  });
}

class SourceAggregator {
  final List<BookSource> _sources;
  final Map<String, SourceDiagnostic> _diagnostics = {};

  List<BookSource> get sources => List.unmodifiable(_sources);
  Map<String, SourceDiagnostic> get diagnostics => Map.unmodifiable(_diagnostics);

  SourceAggregator({List<BookSource>? sources, http.Client? client})
      : _sources = sources ??
            [
              GutendexSource(client: client),
              OpenLibrarySource(client: client),
              InternetArchiveSource(client: client),
              ArabicHeritageSource(client: client),
              StandardEbooksSource(client: client),
              DoabSource(client: client),
            ];

  /// Tests connectivity and latency of all registered sources
  Future<Map<String, SourceDiagnostic>> testAllSources() async {
    final futures = _sources.map((source) => _testSource(source));
    await Future.wait(futures);
    return _diagnostics;
  }

  Future<void> _testSource(BookSource source) async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await source.browse(page: 1).timeout(const Duration(seconds: 8));
      stopwatch.stop();

      final health = stopwatch.elapsedMilliseconds < 2500 ? SourceHealth.online : SourceHealth.slow;
      _diagnostics[source.id] = SourceDiagnostic(
        id: source.id,
        name: source.name,
        health: health,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        totalResultsFound: results.length,
      );
    } catch (e) {
      stopwatch.stop();
      _diagnostics[source.id] = SourceDiagnostic(
        id: source.id,
        name: source.name,
        health: SourceHealth.error,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        lastError: e.toString(),
      );
    }
  }

  /// Concurrently queries all eligible providers, isolates failures, records response times,
  /// and deduplicates normalized books without hiding separate editions.
  Future<AggregateSearchResult> search({
    required String query,
    String? language,
    String? category,
    bool physicalOnly = false,
    int page = 1,
  }) async {
    final cleanQuery = query.trim();
    final stopwatch = Stopwatch()..start();

    // Select which sources to run
    final activeSources = _sources.where((source) {
      if (physicalOnly) return source.supportsPhysical;
      // If user selected Arabic language, only query sources supporting Arabic
      if (language == 'Arabic' || language == 'ar') {
        return source.supportsArabic;
      }
      return true;
    }).toList();

    // Query providers concurrently with independent timeouts
    final queryFutures = activeSources.map((source) async {
      final sWatch = Stopwatch()..start();
      try {
        final List<Book> books;
        if (cleanQuery.isEmpty) {
          books = await source.browse(category: category, language: language, page: page)
              .timeout(const Duration(seconds: 10));
        } else {
          books = await source.search(cleanQuery, category: category, language: language, page: page)
              .timeout(const Duration(seconds: 10));
        }
        sWatch.stop();

        _diagnostics[source.id] = SourceDiagnostic(
          id: source.id,
          name: source.name,
          health: sWatch.elapsedMilliseconds < 3000 ? SourceHealth.online : SourceHealth.slow,
          responseTimeMs: sWatch.elapsedMilliseconds,
          totalResultsFound: books.length,
        );

        return books;
      } catch (e) {
        sWatch.stop();
        _diagnostics[source.id] = SourceDiagnostic(
          id: source.id,
          name: source.name,
          health: SourceHealth.error,
          responseTimeMs: sWatch.elapsedMilliseconds,
          lastError: e.toString(),
        );
        return <Book>[];
      }
    });

    final resultsList = await Future.wait(queryFutures);
    stopwatch.stop();

    // Interleave and deduplicate results
    final combined = <Book>[];
    final seenNormalizedKeys = <String>{};

    int maxLen = 0;
    for (var list in resultsList) {
      if (list.length > maxLen) maxLen = list.length;
    }

    // Round-robin interleaving to balance providers
    for (int i = 0; i < maxLen; i++) {
      for (var list in resultsList) {
        if (i < list.length) {
          final book = list[i];
          final normKey = _normalizeKey(book.title, book.author, book.source);
          if (!seenNormalizedKeys.contains(normKey)) {
            seenNormalizedKeys.add(normKey);
            combined.add(book);
          }
        }
      }
    }

    return AggregateSearchResult(
      books: combined,
      diagnostics: _diagnostics,
      totalCount: combined.length,
      hasNextPage: combined.isNotEmpty && combined.length >= 10,
    );
  }

  String _normalizeKey(String title, String author, String source) {
    final cleanT = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '');
    final cleanA = author.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '');
    return '${source}_${cleanT}_$cleanA';
  }
}
