import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import '../../core/constants/app_constants.dart';

class GutendexService {
  final http.Client _client;

  GutendexService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches popular books or search results from Project Gutenberg via Gutendex
  Future<List<Book>> fetchBooks({
    String? query,
    String? topic,
    String? language,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['search'] = query.trim();
    }

    if (topic != null && topic != 'All' && topic.trim().isNotEmpty) {
      queryParams['topic'] = topic.trim();
    }

    if (language != null && language.isNotEmpty) {
      queryParams['languages'] = language;
    }

    final uri = Uri.parse(AppConstants.gutendexBaseUrl)
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((item) => Book.fromGutendex(item as Map<String, dynamic>))
          .where((book) => book.downloadUrls.isNotEmpty)
          .toList();
    } else {
      throw Exception('Gutendex API returned HTTP ${response.statusCode}');
    }
  }

  /// Curated classic books from Gutenberg for immediate showcase
  static List<Book> getFeaturedClassics() {
    return [
      Book(
        id: 'gutenberg_11',
        title: "Alice's Adventures in Wonderland",
        author: 'Lewis Carroll',
        description: 'A timeless tale of Alice falling through a rabbit hole into a fantastical world.',
        language: 'en',
        source: 'Project Gutenberg',
        format: 'epub',
        coverUrl: 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
        downloadUrls: {
          'epub': 'https://www.gutenberg.org/ebooks/11.epub3.images',
          'txt': 'https://www.gutenberg.org/ebooks/11.txt.utf-8',
        },
      ),
      Book(
        id: 'gutenberg_84',
        title: 'Frankenstein',
        author: 'Mary Wollstonecraft Shelley',
        description: 'A scientist creates a sapient creature in an unorthodox scientific experiment.',
        language: 'en',
        source: 'Project Gutenberg',
        format: 'epub',
        coverUrl: 'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
        downloadUrls: {
          'epub': 'https://www.gutenberg.org/ebooks/84.epub3.images',
          'txt': 'https://www.gutenberg.org/ebooks/84.txt.utf-8',
        },
      ),
      Book(
        id: 'gutenberg_1342',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        description: 'A turbulent relationship between Elizabeth Bennet and Fitzwilliam Darcy.',
        language: 'en',
        source: 'Project Gutenberg',
        format: 'epub',
        coverUrl: 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
        downloadUrls: {
          'epub': 'https://www.gutenberg.org/ebooks/1342.epub3.images',
          'txt': 'https://www.gutenberg.org/ebooks/1342.txt.utf-8',
        },
      ),
      Book(
        id: 'gutenberg_1661',
        title: 'The Adventures of Sherlock Holmes',
        author: 'Arthur Conan Doyle',
        description: 'Twelve famous detective stories featuring master sleuth Sherlock Holmes and Dr. Watson.',
        language: 'en',
        source: 'Project Gutenberg',
        format: 'epub',
        coverUrl: 'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
        downloadUrls: {
          'epub': 'https://www.gutenberg.org/ebooks/1661.epub3.images',
          'txt': 'https://www.gutenberg.org/ebooks/1661.txt.utf-8',
        },
      ),
      Book(
        id: 'gutenberg_2701',
        title: 'Moby Dick; Or, The Whale',
        author: 'Herman Melville',
        description: 'The sailor Ishmael narrates the obsessive quest of Captain Ahab for revenge on Moby Dick.',
        language: 'en',
        source: 'Project Gutenberg',
        format: 'epub',
        coverUrl: 'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
        downloadUrls: {
          'epub': 'https://www.gutenberg.org/ebooks/2701.epub3.images',
          'txt': 'https://www.gutenberg.org/ebooks/2701.txt.utf-8',
        },
      ),
    ];
  }
}
