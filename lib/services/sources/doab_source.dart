import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import 'book_source.dart';

class DoabSource implements BookSource {
  final http.Client _client;

  DoabSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'doab';

  @override
  String get name => 'Directory of Open Access Books (DOAB)';

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
    final cleanQuery = query.trim().isNotEmpty ? query.trim() : 'science technology philosophy';
    final queryParams = <String, String>{
      'query': cleanQuery,
      'expand': 'metadata',
      'limit': '15',
      'offset': '${(page - 1) * 15}',
    };

    final uri = Uri.parse('https://directory.doabooks.org/rest/search').replace(queryParameters: queryParams);

    try {
      final res = await _client.get(uri, headers: {
        'User-Agent': 'AYNOX-Library/1.0.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        final books = <Book>[];

        for (final item in list) {
          final handle = item['handle']?.toString() ?? '';
          final metadata = item['metadata'] as List<dynamic>? ?? [];

          String title = 'Academic Publication';
          String author = 'Peer-reviewed Researcher';
          String desc = 'Open Access peer-reviewed academic monograph via DOAB.';
          String? publisher;
          String? isbn;
          int? year;
          String? pdfUrl;

          for (final m in metadata) {
            final key = m['key']?.toString();
            final value = m['value']?.toString() ?? '';
            if (key == 'dc.title') title = value;
            if (key == 'dc.contributor.author') author = value;
            if (key == 'dc.description.abstract') desc = value;
            if (key == 'dc.publisher') publisher = value;
            if (key == 'dc.identifier.isbn') isbn = value;
            if (key == 'dc.date.issued' && value.length >= 4) {
              year = int.tryParse(value.substring(0, 4));
            }
            if (key == 'dc.identifier.uri' && value.endsWith('.pdf')) {
              pdfUrl = value;
            }
          }

          final downloadUrls = <String, String>{};
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            downloadUrls['pdf'] = pdfUrl;
          }

          books.add(Book(
            id: 'doab_${handle.replaceAll('/', '_')}',
            title: title,
            author: author,
            description: desc.length > 250 ? '${desc.substring(0, 250)}...' : desc,
            language: language ?? 'en',
            source: 'DOAB (Open Access)',
            providerId: 'doab',
            downloadUrls: downloadUrls,
            format: 'pdf',
            isPhysical: false,
            isbn: isbn,
            publisher: publisher,
            publishYear: year,
            purchaseUrl: 'https://directory.doabooks.org/handle/$handle',
            rightsStatus: 'open_access',
          ));
        }

        return books;
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    return search(category ?? 'academic science', language: language, page: page);
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }
}
