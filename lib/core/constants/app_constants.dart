class AppConstants {
  static const String appName = 'AYNOX Library';
  static const String appVersion = '1.0.0';

  // Legitimate Public Domain & Open Library APIs
  static const String gutendexBaseUrl = 'https://gutendex.com/books';
  static const String openLibrarySearchUrl = 'https://openlibrary.org/search.json';
  static const String openLibraryCoverBaseUrl = 'https://covers.openlibrary.org/b/id';
  static const String internetArchiveSearchUrl = 'https://archive.org/advancedsearch.php';
  static const String standardEbooksBaseUrl = 'https://standardebooks.org/opds/all';
  static const String doabSearchUrl = 'https://directory.doabooks.org/rest/search';

  // Supported Local Formats
  static const List<String> supportedExtensions = ['pdf', 'epub', 'txt'];

  // Categories for browsing
  static const List<String> bookCategories = [
    'All',
    'Fiction',
    'Philosophy',
    'Science',
    'History',
    'Poetry',
    'Adventure',
    'Mystery',
    'Academic',
  ];

  // Language Filters
  static const Map<String, String> languageCodes = {
    'All': '',
    'Arabic': 'ar',
    'English': 'en',
    'French': 'fr',
  };

  // Storage Keys
  static const String keyRecentBooks = 'aynox_recent_books';
  static const String keyFavorites = 'aynox_favorites';
  static const String keyCollections = 'aynox_collections';
  static const String keyReadingProgress = 'aynox_reading_progress_';
  static const String keyBookmarks = 'aynox_bookmarks_';
  static const String keyThemeMode = 'aynox_theme_mode';
  static const String keyLocale = 'aynox_locale';
  static const String keyFontSize = 'aynox_reader_font_size';
  static const String keyLineSpacing = 'aynox_reader_line_spacing';
  static const String keyReaderTheme = 'aynox_reader_theme';
  static const String keyPageTurnMode = 'aynox_page_turn_mode'; // 'curl', 'slide', 'scroll'
  static const String keyPreferredFormat = 'aynox_preferred_format'; // 'pdf', 'epub', 'txt'
  static const String keyAnimationsEnabled = 'aynox_animations_enabled';
  static const String keyReducedMotion = 'aynox_reduced_motion';
  static const String keyFontFamily = 'aynox_font_family';
  static const String keyOwnedBooks = 'aynox_owned_books';
  static const String keyWishlistBooks = 'aynox_wishlist_books';
}
