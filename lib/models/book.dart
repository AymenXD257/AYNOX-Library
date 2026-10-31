class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String language;
  final String? coverUrl;
  final String source; // 'Project Gutenberg', 'Open Library', 'Internet Archive', etc.
  final String providerId;
  final Map<String, String> downloadUrls; // {'epub': url, 'txt': url, 'pdf': url}
  final Map<String, List<String>> fallbackDownloadUrls;
  final String? localFilePath;
  final bool isDownloaded;
  final bool isImported;
  final String format; // 'pdf', 'epub', 'txt'
  final double readingProgress; // 0.0 to 1.0
  final int lastPosition; // page or chapter or scroll offset
  final int totalUnits; // total pages or chapters
  final DateTime addedAt;
  final DateTime? lastReadAt;

  // Physical book metadata
  final bool isPhysical;
  final String? isbn;
  final String? publisher;
  final int? publishYear;
  final String? edition;
  final int? pageCount;
  final String? price;
  final String? purchaseUrl;
  final bool isOwnedPhysically;
  final bool isWishlisted;

  // Rights status: 'public_domain', 'open_access', 'free_to_read', 'borrowable', 'preview_only', 'physical'
  final String rightsStatus;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = '',
    this.language = 'en',
    this.coverUrl,
    required this.source,
    this.providerId = '',
    this.downloadUrls = const {},
    this.fallbackDownloadUrls = const {},
    this.localFilePath,
    this.isDownloaded = false,
    this.isImported = false,
    this.format = 'epub',
    this.readingProgress = 0.0,
    this.lastPosition = 0,
    this.totalUnits = 1,
    DateTime? addedAt,
    this.lastReadAt,
    this.isPhysical = false,
    this.isbn,
    this.publisher,
    this.publishYear,
    this.edition,
    this.pageCount,
    this.price,
    this.purchaseUrl,
    this.isOwnedPhysically = false,
    this.isWishlisted = false,
    this.rightsStatus = 'public_domain',
  }) : addedAt = addedAt ?? DateTime.now();

  bool get isLocal => localFilePath != null && localFilePath!.isNotEmpty;

  List<String> get availableFormats {
    final list = <String>[];
    if (downloadUrls.containsKey('pdf')) list.add('pdf');
    if (downloadUrls.containsKey('epub')) list.add('epub');
    if (downloadUrls.containsKey('txt')) list.add('txt');
    if (list.isEmpty && !isPhysical) list.add(format);
    return list;
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? language,
    String? coverUrl,
    String? source,
    String? providerId,
    Map<String, String>? downloadUrls,
    Map<String, List<String>>? fallbackDownloadUrls,
    String? localFilePath,
    bool? isDownloaded,
    bool? isImported,
    String? format,
    double? readingProgress,
    int? lastPosition,
    int? totalUnits,
    DateTime? addedAt,
    DateTime? lastReadAt,
    bool? isPhysical,
    String? isbn,
    String? publisher,
    int? publishYear,
    String? edition,
    int? pageCount,
    String? price,
    String? purchaseUrl,
    bool? isOwnedPhysically,
    bool? isWishlisted,
    String? rightsStatus,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      language: language ?? this.language,
      coverUrl: coverUrl ?? this.coverUrl,
      source: source ?? this.source,
      providerId: providerId ?? this.providerId,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      fallbackDownloadUrls: fallbackDownloadUrls ?? this.fallbackDownloadUrls,
      localFilePath: localFilePath ?? this.localFilePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isImported: isImported ?? this.isImported,
      format: format ?? this.format,
      readingProgress: readingProgress ?? this.readingProgress,
      lastPosition: lastPosition ?? this.lastPosition,
      totalUnits: totalUnits ?? this.totalUnits,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isPhysical: isPhysical ?? this.isPhysical,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      edition: edition ?? this.edition,
      pageCount: pageCount ?? this.pageCount,
      price: price ?? this.price,
      purchaseUrl: purchaseUrl ?? this.purchaseUrl,
      isOwnedPhysically: isOwnedPhysically ?? this.isOwnedPhysically,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      rightsStatus: rightsStatus ?? this.rightsStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'language': language,
      'coverUrl': coverUrl,
      'source': source,
      'providerId': providerId,
      'downloadUrls': downloadUrls,
      'fallbackDownloadUrls': fallbackDownloadUrls,
      'localFilePath': localFilePath,
      'isDownloaded': isDownloaded,
      'isImported': isImported,
      'format': format,
      'readingProgress': readingProgress,
      'lastPosition': lastPosition,
      'totalUnits': totalUnits,
      'addedAt': addedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'isPhysical': isPhysical,
      'isbn': isbn,
      'publisher': publisher,
      'publishYear': publishYear,
      'edition': edition,
      'pageCount': pageCount,
      'price': price,
      'purchaseUrl': purchaseUrl,
      'isOwnedPhysically': isOwnedPhysically,
      'isWishlisted': isWishlisted,
      'rightsStatus': rightsStatus,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String? ?? 'Unknown Author',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      coverUrl: json['coverUrl'] as String?,
      source: json['source'] as String? ?? 'Local Storage',
      providerId: json['providerId'] as String? ?? '',
      downloadUrls: (json['downloadUrls'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      fallbackDownloadUrls: (json['fallbackDownloadUrls'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e.toString()).toList()),
          ) ??
          {},
      localFilePath: json['localFilePath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isImported: json['isImported'] as bool? ?? false,
      format: json['format'] as String? ?? 'epub',
      readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0.0,
      lastPosition: (json['lastPosition'] as num?)?.toInt() ?? 0,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 1,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'] as String)
          : null,
      isPhysical: json['isPhysical'] as bool? ?? false,
      isbn: json['isbn'] as String?,
      publisher: json['publisher'] as String?,
      publishYear: (json['publishYear'] as num?)?.toInt(),
      edition: json['edition'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      price: json['price'] as String?,
      purchaseUrl: json['purchaseUrl'] as String?,
      isOwnedPhysically: json['isOwnedPhysically'] as bool? ?? false,
      isWishlisted: json['isWishlisted'] as bool? ?? false,
      rightsStatus: json['rightsStatus'] as String? ?? 'public_domain',
    );
  }

  // Factory for Gutendex API JSON
  factory Book.fromGutendex(Map<String, dynamic> json) {
    final authorsList = json['authors'] as List<dynamic>?;
    final authorName = (authorsList != null && authorsList.isNotEmpty)
        ? (authorsList[0]['name'] as String? ?? 'Unknown')
        : 'Unknown Author';

    final formats = json['formats'] as Map<String, dynamic>? ?? {};
    final downloadUrls = <String, String>{};
    final fallbackUrls = <String, List<String>>{};

    // Clean Gutenberg author format (e.g. "Austen, Jane" -> "Jane Austen")
    String cleanedAuthor = authorName;
    if (cleanedAuthor.contains(',')) {
      final parts = cleanedAuthor.split(',');
      if (parts.length == 2) {
        cleanedAuthor = '${parts[1].trim()} ${parts[0].trim()}';
      }
    }

    // Direct and fallback URLs
    for (final entry in formats.entries) {
      final key = entry.key.toLowerCase();
      final url = entry.value.toString();
      if (key.contains('application/epub+zip')) {
        downloadUrls['epub'] = url;
      } else if (key.contains('epub3')) {
        fallbackUrls.putIfAbsent('epub', () => []).add(url);
      } else if (key.contains('pdf')) {
        downloadUrls['pdf'] = url;
      } else if (key.contains('text/plain') && !key.contains('zip')) {
        downloadUrls['txt'] = url;
      }
    }

    String detectedFormat = 'epub';
    if (downloadUrls.containsKey('pdf')) {
      detectedFormat = 'pdf';
    } else if (downloadUrls.containsKey('epub')) {
      detectedFormat = 'epub';
    } else if (downloadUrls.containsKey('txt')) {
      detectedFormat = 'txt';
    }

    final rawCover = formats['image/jpeg'] as String?;
    final languages = json['languages'] as List<dynamic>?;
    final language = (languages != null && languages.isNotEmpty)
        ? languages[0].toString()
        : 'en';

    final subjects = json['subjects'] as List<dynamic>?;
    final description = subjects != null && subjects.isNotEmpty
        ? subjects.take(4).join(' • ')
        : 'Public domain book from Project Gutenberg.';

    return Book(
      id: 'gutendex_${json['id']}',
      title: json['title'] as String? ?? 'Untitled',
      author: cleanedAuthor,
      description: description,
      language: language,
      coverUrl: rawCover,
      source: 'Project Gutenberg',
      providerId: 'gutendex',
      downloadUrls: downloadUrls,
      fallbackDownloadUrls: fallbackUrls,
      format: detectedFormat,
      rightsStatus: 'public_domain',
    );
  }

  // Factory for Open Library API JSON
  factory Book.fromOpenLibrary(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Untitled';
    final authorNames = json['author_name'] as List<dynamic>?;
    final author = (authorNames != null && authorNames.isNotEmpty)
        ? authorNames[0].toString()
        : 'Unknown Author';

    final coverId = json['cover_i'];
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;

    final languages = json['language'] as List<dynamic>?;
    final language = (languages != null && languages.isNotEmpty)
        ? languages[0].toString()
        : 'en';

    final key = json['key'] as String? ?? title.hashCode.toString();
    final firstPublishYear = json['first_publish_year'] as num?;
    final publishers = json['publisher'] as List<dynamic>?;
    final publisher = (publishers != null && publishers.isNotEmpty) ? publishers[0].toString() : null;

    final isbns = json['isbn'] as List<dynamic>?;
    final isbn = (isbns != null && isbns.isNotEmpty) ? isbns[0].toString() : null;

    // Check Open Library / Internet Archive public-domain availability
    final hasFulltext = json['has_fulltext'] as bool? ?? false;
    final ia = json['ia'] as List<dynamic>?;
    final Map<String, String> downloadUrls = {};

    String rights = 'physical';
    if (hasFulltext && ia != null && ia.isNotEmpty) {
      final iaId = ia[0].toString();
      downloadUrls['pdf'] = 'https://archive.org/download/$iaId/$iaId.pdf';
      downloadUrls['epub'] = 'https://archive.org/download/$iaId/$iaId.epub';
      downloadUrls['txt'] = 'https://archive.org/download/$iaId/${iaId}_djvu.txt';
      rights = 'open_access';
    }

    final desc = firstPublishYear != null
        ? 'First published in $firstPublishYear. Publisher: ${publisher ?? "Independent"}. Open catalog record via Open Library.'
        : 'Open Library public catalog record.';

    return Book(
      id: 'openlib_${key.replaceAll('/', '_')}',
      title: title,
      author: author,
      description: desc,
      language: language,
      coverUrl: coverUrl,
      source: 'Open Library',
      providerId: 'open_library',
      downloadUrls: downloadUrls,
      format: downloadUrls.containsKey('pdf') ? 'pdf' : (downloadUrls.containsKey('epub') ? 'epub' : 'txt'),
      isPhysical: downloadUrls.isEmpty,
      isbn: isbn,
      publisher: publisher,
      publishYear: firstPublishYear?.toInt(),
      purchaseUrl: isbn != null ? 'https://openlibrary.org/isbn/$isbn' : 'https://openlibrary.org$key',
      rightsStatus: rights,
    );
  }
}
