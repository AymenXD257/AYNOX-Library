import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../core/constants/app_constants.dart';
import 'book_source.dart';

class GutendexSource implements BookSource {
  final http.Client _client;

  GutendexSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'gutendex';

  @override
  String get name => 'Project Gutenberg';

  @override
  bool get supportsPhysical => false;

  @override
  bool get supportsArabic => false;

  @override
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  }) async {
    return _fetch(query: query, category: category, language: language, page: page);
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    return _fetch(category: category, language: language, page: page);
  }

  Future<List<Book>> _fetch({
    String? query,
    String? category,
    String? language,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    if (category != null && category != 'All' && category != 'Arabic Literature') {
      queryParams['topic'] = category.trim();
    }

    if (language != null && language.isNotEmpty && language != 'All') {
      // Gutenberg language filter (en, fr, etc.)
      final code = language == 'Arabic' ? 'ar' : (language == 'French' ? 'fr' : (language == 'English' ? 'en' : language));
      if (code != 'ar') { // Gutenberg has virtually no Arabic texts; don't break queries
        queryParams['languages'] = code;
      }
    }

    final uri = Uri.parse(AppConstants.gutendexBaseUrl).replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: {
      'User-Agent': 'AYNOX-Library/1.0.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gutendex returned HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => Book.fromGutendex(item as Map<String, dynamic>))
        .where((b) => b.downloadUrls.isNotEmpty)
        .toList();
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }
}
