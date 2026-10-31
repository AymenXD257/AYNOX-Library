import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../core/constants/app_constants.dart';
import 'book_source.dart';

class OpenLibrarySource implements BookSource {
  final http.Client _client;

  OpenLibrarySource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'open_library';

  @override
  String get name => 'Open Library';

  @override
  bool get supportsPhysical => true;

  @override
  bool get supportsArabic => true;

  @override
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  }) async {
    final effectiveQuery = query.trim().isNotEmpty
        ? query.trim()
        : (category != null && category != 'All' ? category : 'classic literature');

    final queryParams = <String, String>{
      'q': effectiveQuery,
      'page': page.toString(),
      'limit': '15',
    };

    if (language != null && language.isNotEmpty && language != 'All') {
      final lang3 = language == 'Arabic' || language == 'ar'
          ? 'ara'
          : (language == 'French' || language == 'fr' ? 'fre' : 'eng');
      queryParams['language'] = lang3;
    }

    final uri = Uri.parse(AppConstants.openLibrarySearchUrl).replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: {
      'User-Agent': 'AYNOX-Library/1.0.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Open Library returned HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>? ?? [];

    return docs
        .map((item) => Book.fromOpenLibrary(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    final cat = (category != null && category != 'All') ? category : 'classics';
    return search(cat, language: language, page: page);
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }
}
