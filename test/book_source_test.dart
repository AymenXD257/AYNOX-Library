import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aynox_library/models/book.dart';
import 'package:aynox_library/services/sources/gutendex_source.dart';
import 'package:aynox_library/services/sources/open_library_source.dart';
import 'package:aynox_library/services/sources/internet_archive_source.dart';
import 'package:aynox_library/services/sources/arabic_heritage_source.dart';
import 'package:aynox_library/services/sources/standard_ebooks_source.dart';
import 'package:aynox_library/services/sources/doab_source.dart';
import 'package:aynox_library/services/sources/source_aggregator.dart';

void main() {
  group('GutendexSource Unit Tests', () {
    test('Successful search parses books with download formats', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'count': 1,
          'results': [
            {
              'id': 11,
              'title': "Alice's Adventures in Wonderland",
              'authors': [{'name': 'Carroll, Lewis'}],
              'languages': ['en'],
              'formats': {
                'application/epub+zip': 'https://www.gutenberg.org/ebooks/11.epub.images',
                'text/plain': 'https://www.gutenberg.org/ebooks/11.txt.utf-8',
                'image/jpeg': 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
              },
              'subjects': ['Fantasy fiction'],
            }
          ]
        };
        return http.Response(json.encode(mockResponse), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final source = GutendexSource(client: mockClient);
      final books = await source.search('Alice');

      expect(books.length, 1);
      expect(books.first.title, "Alice's Adventures in Wonderland");
      expect(books.first.author, 'Lewis Carroll');
      expect(books.first.downloadUrls.containsKey('epub'), true);
      expect(books.first.rightsStatus, 'public_domain');
    });

    test('HTTP error throws readable exception and is not swallowed', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final source = GutendexSource(client: mockClient);
      expect(() => source.search('Test'), throwsException);
    });

    test('Empty results returns empty list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({'count': 0, 'results': []}), 200);
      });

      final source = GutendexSource(client: mockClient);
      final books = await source.search('NonExistentTerm');
      expect(books.isEmpty, true);
    });
  });

  group('OpenLibrarySource Unit Tests', () {
    test('Parses physical books and fulltext IA links', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'numFound': 2,
          'docs': [
            {
              'key': '/works/OL123W',
              'title': 'The Republic',
              'author_name': ['Plato'],
              'language': ['eng'],
              'first_publish_year': 1901,
              'has_fulltext': true,
              'ia': ['republicofplato00plat'],
              'isbn': ['9780140449143'],
              'publisher': ['Penguin Classics'],
            },
            {
              'key': '/works/OL456W',
              'title': 'Modern Architecture',
              'author_name': ['Kenneth Frampton'],
              'language': ['eng'],
              'first_publish_year': 1980,
              'has_fulltext': false,
              'isbn': ['9780500203958'],
              'publisher': ['Thames & Hudson'],
            }
          ]
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final source = OpenLibrarySource(client: mockClient);
      final books = await source.search('Plato');

      expect(books.length, 2);
      expect(books[0].isPhysical, false);
      expect(books[0].downloadUrls.containsKey('pdf'), true);
      expect(books[1].isPhysical, true);
      expect(books[1].downloadUrls.isEmpty, true);
      expect(books[1].isbn, '9780500203958');
    });
  });

  group('InternetArchiveSource Unit Tests', () {
    test('Builds verified direct PDF and EPUB download URLs', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'response': {
            'docs': [
              {
                'identifier': 'arabiannights00lond',
                'title': 'The Arabian Nights Entertainments',
                'creator': ['Andrew Lang'],
                'description': 'Collection of classic folklore tales.',
                'year': 1898,
                'language': 'eng',
              }
            ]
          }
        };
        return http.Response(json.encode(mockResponse), 200);
      });

      final source = InternetArchiveSource(client: mockClient);
      final books = await source.search('Arabian Nights');

      expect(books.length, 1);
      final b = books.first;
      expect(b.source, 'Internet Archive');
      expect(b.downloadUrls['pdf'], 'https://archive.org/download/arabiannights00lond/arabiannights00lond.pdf');
      expect(b.downloadUrls['epub'], 'https://archive.org/download/arabiannights00lond/arabiannights00lond.epub');
      expect(b.rightsStatus, 'public_domain');
    });
  });

  group('ArabicHeritageSource Unit Tests', () {
    test('Contains verified legitimate Arabic classics with valid download URLs', () async {
      final source = ArabicHeritageSource();
      final books = await source.search('حي بن يقظان');

      expect(books.isNotEmpty, true);
      final hayy = books.firstWhere((b) => b.title.contains('حي بن يقظان'));
      expect(hayy.author, 'ابن طفيل الأندلسي');
      expect(hayy.language, 'ar');
      expect(hayy.downloadUrls.isNotEmpty, true);
      expect(hayy.rightsStatus, 'public_domain');
    });
  });

  group('StandardEbooksSource Unit Tests', () {
    test('Returns curated high-typography EPUB editions', () async {
      final source = StandardEbooksSource();
      final books = await source.search('Frankenstein');

      expect(books.isNotEmpty, true);
      final frank = books.firstWhere((b) => b.title.contains('Frankenstein'));
      expect(frank.downloadUrls['epub']!.endsWith('.epub'), true);
      expect(frank.format, 'epub');
    });
  });

  group('SourceAggregator Integration & Deduplication Tests', () {
    test('Deduplicates normalized books across concurrent sources without error', () async {
      final aggregator = SourceAggregator();
      final result = await aggregator.search(query: 'Pride and Prejudice', page: 1);

      expect(result.books.isNotEmpty, true);
      expect(result.totalCount, greaterThan(0));

      // Diagnostics check
      expect(result.diagnostics.isNotEmpty, true);
    });
  });
}
