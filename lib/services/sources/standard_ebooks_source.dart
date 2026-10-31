import 'package:http/http.dart' as http;
import '../../models/book.dart';
import 'book_source.dart';

class StandardEbooksSource implements BookSource {
  final http.Client _client;

  StandardEbooksSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'standard_ebooks';

  @override
  String get name => 'Standard Ebooks';

  @override
  bool get supportsPhysical => false;

  @override
  bool get supportsArabic => false;

  // High-standard, verified public domain EPUB editions with impeccable typography
  static final List<Book> _curatedStandardEbooks = [
    Book(
      id: 'se_pride_and_prejudice',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      description: 'The romantic clash between Elizabeth Bennet and the enigmatic Fitzwilliam Darcy in Regency England.',
      language: 'en',
      source: 'Standard Ebooks',
      providerId: 'standard_ebooks',
      coverUrl: 'https://standardebooks.org/ebooks/jane-austen/pride-and-prejudice/downloads/cover-thumbnail.jpg',
      downloadUrls: {
        'epub': 'https://standardebooks.org/ebooks/jane-austen/pride-and-prejudice/downloads/jane-austen_pride-and-prejudice.epub',
      },
      format: 'epub',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'se_frankenstein',
      title: 'Frankenstein; or, The Modern Prometheus',
      author: 'Mary Wollstonecraft Shelley',
      description: 'The seminal gothic masterpiece exploring creation, ambition, and humanity through Victor Frankenstein and his monster.',
      language: 'en',
      source: 'Standard Ebooks',
      providerId: 'standard_ebooks',
      coverUrl: 'https://standardebooks.org/ebooks/mary-shelley/frankenstein/downloads/cover-thumbnail.jpg',
      downloadUrls: {
        'epub': 'https://standardebooks.org/ebooks/mary-shelley/frankenstein/downloads/mary-shelley_frankenstein.epub',
      },
      format: 'epub',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'se_the_great_gatsby',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      description: 'A portrait of the Jazz Age through the mysterious, self-made millionaire Jay Gatsby and his obsession with Daisy Buchanan.',
      language: 'en',
      source: 'Standard Ebooks',
      providerId: 'standard_ebooks',
      coverUrl: 'https://standardebooks.org/ebooks/f-scott-fitzgerald/the-great-gatsby/downloads/cover-thumbnail.jpg',
      downloadUrls: {
        'epub': 'https://standardebooks.org/ebooks/f-scott-fitzgerald/the-great-gatsby/downloads/f-scott-fitzgerald_the-great-gatsby.epub',
      },
      format: 'epub',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'se_dracula',
      title: 'Dracula',
      author: 'Bram Stoker',
      description: 'The epistolary gothic novel introducing Count Dracula and the battle of professor Van Helsing to thwart the vampire.',
      language: 'en',
      source: 'Standard Ebooks',
      providerId: 'standard_ebooks',
      coverUrl: 'https://standardebooks.org/ebooks/bram-stoker/dracula/downloads/cover-thumbnail.jpg',
      downloadUrls: {
        'epub': 'https://standardebooks.org/ebooks/bram-stoker/dracula/downloads/bram-stoker_dracula.epub',
      },
      format: 'epub',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'se_the_metamorphosis',
      title: 'The Metamorphosis',
      author: 'Franz Kafka',
      description: 'Gregor Samsa wakes one morning to find himself transformed into a monstrous vermin.',
      language: 'en',
      source: 'Standard Ebooks',
      providerId: 'standard_ebooks',
      coverUrl: 'https://standardebooks.org/ebooks/franz-kafka/the-metamorphosis/david-wyllie/downloads/cover-thumbnail.jpg',
      downloadUrls: {
        'epub': 'https://standardebooks.org/ebooks/franz-kafka/the-metamorphosis/david-wyllie/downloads/franz-kafka_the-metamorphosis_david-wyllie.epub',
      },
      format: 'epub',
      rightsStatus: 'public_domain',
    ),
  ];

  @override
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _curatedStandardEbooks;

    return _curatedStandardEbooks.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    return _curatedStandardEbooks;
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }
}
