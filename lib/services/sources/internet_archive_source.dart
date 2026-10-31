import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../core/constants/app_constants.dart';
import 'book_source.dart';

class InternetArchiveSource implements BookSource {
  final http.Client _client;

  InternetArchiveSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'internet_archive';

  @override
  String get name => 'Internet Archive';

  @override
  bool get supportsPhysical => false;

  @override
  bool get supportsArabic => true;

  @override
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  }) async {
    final cleanQuery = query.trim().isNotEmpty
        ? query.trim().replaceAll('"', '')
        : (category != null && category != 'All' ? category : 'classic literature');

    // Filter to public domain texts
    String archiveQuery = '($cleanQuery) AND mediatype:(texts) AND (language:eng OR language:ara OR language:fre)';
    if (language != null && language.isNotEmpty && language != 'All') {
      final langCode = language == 'Arabic' || language == 'ar'
          ? 'ara'
          : (language == 'French' || language == 'fr' ? 'fre' : 'eng');
      archiveQuery = '($cleanQuery) AND mediatype:(texts) AND language:$langCode';
    }

    final queryParams = <String, String>{
      'q': archiveQuery,
      'fl[]': 'identifier,title,creator,description,year,language,publicdate',
      'sort[]': 'downloads desc',
      'rows': '15',
      'page': page.toString(),
      'output': 'json',
    };

    final uri = Uri.parse(AppConstants.internetArchiveSearchUrl).replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: {
      'User-Agent': 'AYNOX-Library/1.0.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Internet Archive returned HTTP ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final docs = (data['response']?['docs'] as List<dynamic>?) ?? [];

    return docs.map((item) {
      final id = item['identifier'] as String? ?? '';
      final title = item['title'] as String? ?? 'Untitled Archive Text';
      final creator = item['creator'] is List
          ? (item['creator'] as List).join(', ')
          : (item['creator'] as String? ?? 'Unknown Author');
      final desc = item['description'] is List
          ? (item['description'] as List).join(' ')
          : (item['description'] as String? ?? 'Public domain scanned document from Internet Archive.');
      final lang = item['language'] is List
          ? (item['language'] as List).firstOrNull?.toString() ?? 'en'
          : (item['language'] as String? ?? 'en');
      final yearStr = item['year']?.toString();
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      final downloadUrls = <String, String>{
        'pdf': 'https://archive.org/download/$id/$id.pdf',
        'epub': 'https://archive.org/download/$id/$id.epub',
        'txt': 'https://archive.org/download/$id/${id}_djvu.txt',
      };

      return Book(
        id: 'ia_$id',
        title: title,
        author: creator,
        description: desc.length > 250 ? '${desc.substring(0, 250)}...' : desc,
        language: lang,
        coverUrl: 'https://archive.org/services/img/$id',
        source: 'Internet Archive',
        providerId: 'internet_archive',
        downloadUrls: downloadUrls,
        format: 'pdf', // Scanned PDF is primary for Internet Archive
        publishYear: year,
        rightsStatus: 'public_domain',
      );
    }).where((b) => b.id != 'ia_').toList();
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    final cat = (category != null && category != 'All') ? category : 'classic literature';
    return search(cat, language: language, page: page);
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }
}
