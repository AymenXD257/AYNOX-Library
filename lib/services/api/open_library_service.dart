import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../core/constants/app_constants.dart';

import '../sources/arabic_heritage_source.dart';

class OpenLibraryService {
  final http.Client _client;

  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();

  /// Search Open Library public records
  Future<List<Book>> searchBooks({
    required String query,
    String? language,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) return [];

    final queryParams = <String, String>{
      'q': query.trim(),
      'page': page.toString(),
      'limit': '15',
    };

    if (language != null && language.isNotEmpty) {
      // Open Library 3-letter language code mapping
      final lang3 = language == 'ar' ? 'ara' : (language == 'fr' ? 'fre' : 'eng');
      queryParams['language'] = lang3;
    }

    final uri = Uri.parse(AppConstants.openLibrarySearchUrl)
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];

      return docs
          .map((item) => Book.fromOpenLibrary(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Open Library HTTP ${response.statusCode}');
    }
  }

  /// Curated classic Arabic public-domain books for immediate discovery with verified downloads
  static List<Book> getCuratedArabicClassics() {
    return ArabicHeritageSource.getFeaturedArabicBooks();
  }
}
