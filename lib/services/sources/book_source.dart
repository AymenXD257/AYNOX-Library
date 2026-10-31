import '../../models/book.dart';

enum SourceHealth { online, slow, error, unknown }

class SourceDiagnostic {
  final String id;
  final String name;
  final SourceHealth health;
  final int responseTimeMs;
  final int totalResultsFound;
  final String? lastError;
  final DateTime lastChecked;

  SourceDiagnostic({
    required this.id,
    required this.name,
    required this.health,
    required this.responseTimeMs,
    this.totalResultsFound = 0,
    this.lastError,
    DateTime? lastChecked,
  }) : lastChecked = lastChecked ?? DateTime.now();
}

abstract class BookSource {
  String get id;
  String get name;
  bool get supportsPhysical;
  bool get supportsArabic;

  /// Searches the provider for books matching query
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  });

  /// Browses featured, curated, or categorized books
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  });

  /// Resolves download URLs for a book if they need an extra lookup
  Future<Map<String, String>> resolveDownloadUrls(Book book);
}
