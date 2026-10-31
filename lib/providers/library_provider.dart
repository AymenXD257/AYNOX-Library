import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../models/collection.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage/local_library_service.dart';
import '../../services/storage/file_storage_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<Book> _books = [];
  Set<String> _favoriteIds = {};
  Set<String> _ownedIds = {};
  Set<String> _wishlistIds = {};
  List<BookCollection> _collections = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'all'; // 'all', 'imported', 'downloaded', 'favorites', 'reading', 'owned', 'wishlist', 'collections'

  List<Book> get books => _filterBooks();
  List<Book> get allBooksRaw => _books;
  Set<String> get favoriteIds => _favoriteIds;
  Set<String> get ownedIds => _ownedIds;
  Set<String> get wishlistIds => _wishlistIds;
  List<BookCollection> get collections => _collections;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;

  List<Book> get recentlyReadBooks {
    final list = _books.where((b) => b.lastReadAt != null).toList();
    list.sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    return list.take(8).toList();
  }

  LibraryProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await LocalLibraryService.initializeSampleBooksIfNeeded();
    _books = await LocalLibraryService.loadBooks();
    _favoriteIds = await LocalLibraryService.loadFavoriteIds();
    _collections = await LocalLibraryService.loadCollections();

    // Load physical ownership and wishlist IDs
    final prefs = await SharedPreferences.getInstance();
    _ownedIds = (prefs.getStringList(AppConstants.keyOwnedBooks) ?? []).toSet();
    _wishlistIds = (prefs.getStringList(AppConstants.keyWishlistBooks) ?? []).toSet();

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Book> _filterBooks() {
    List<Book> list = _books;

    if (_selectedTab == 'imported') {
      list = list.where((b) => b.isImported).toList();
    } else if (_selectedTab == 'downloaded') {
      list = list.where((b) => b.isDownloaded).toList();
    } else if (_selectedTab == 'favorites') {
      list = list.where((b) => _favoriteIds.contains(b.id)).toList();
    } else if (_selectedTab == 'reading') {
      list = list.where((b) => b.readingProgress > 0 && b.readingProgress < 0.98).toList();
    } else if (_selectedTab == 'owned') {
      list = list.where((b) => _ownedIds.contains(b.id) || b.isOwnedPhysically).toList();
    } else if (_selectedTab == 'wishlist') {
      list = list.where((b) => _wishlistIds.contains(b.id) || b.isWishlisted).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) =>
          b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  bool isFavorite(String bookId) => _favoriteIds.contains(bookId);
  bool isOwned(String bookId) => _ownedIds.contains(bookId);
  bool isWishlisted(String bookId) => _wishlistIds.contains(bookId);

  Future<void> toggleFavorite(String bookId) async {
    if (_favoriteIds.contains(bookId)) {
      _favoriteIds.remove(bookId);
    } else {
      _favoriteIds.add(bookId);
    }
    await LocalLibraryService.saveFavoriteIds(_favoriteIds);
    notifyListeners();
  }

  Future<void> toggleOwnedPhysically(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    if (_ownedIds.contains(book.id)) {
      _ownedIds.remove(book.id);
    } else {
      _ownedIds.add(book.id);
      // Ensure the book exists in the bookshelf
      if (!_books.any((b) => b.id == book.id)) {
        _books.insert(0, book.copyWith(isOwnedPhysically: true));
        await LocalLibraryService.saveBooks(_books);
      }
    }
    await prefs.setStringList(AppConstants.keyOwnedBooks, _ownedIds.toList());
    notifyListeners();
  }

  Future<void> toggleWishlist(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    if (_wishlistIds.contains(book.id)) {
      _wishlistIds.remove(book.id);
    } else {
      _wishlistIds.add(book.id);
      if (!_books.any((b) => b.id == book.id)) {
        _books.insert(0, book.copyWith(isWishlisted: true));
        await LocalLibraryService.saveBooks(_books);
      }
    }
    await prefs.setStringList(AppConstants.keyWishlistBooks, _wishlistIds.toList());
    notifyListeners();
  }

  /// Imports a book from device storage using FilePicker
  Future<Book?> importBookFromFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt'],
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFile = result.files.first;
      final originalPath = pickedFile.path;
      if (originalPath == null) return null;

      final ext = pickedFile.extension?.toLowerCase() ?? 'txt';
      final nameWithoutExt = pickedFile.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

      // Save into app documents
      final destinationPath = await FileStorageService.saveImportedFile(originalPath, pickedFile.name);

      final newBook = Book(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        title: nameWithoutExt.replaceAll('_', ' '),
        author: 'Imported File',
        description: 'Locally imported $ext document.',
        language: 'en',
        source: 'Local Storage',
        localFilePath: destinationPath,
        isDownloaded: true,
        isImported: true,
        format: ext,
        addedAt: DateTime.now(),
      );

      _books.insert(0, newBook);
      await LocalLibraryService.saveBooks(_books);
      notifyListeners();
      return newBook;
    } catch (e) {
      debugPrint('Error importing book: $e');
      return null;
    }
  }

  /// Adds a downloaded book to local library
  Future<void> addDownloadedBook(Book book, String localPath, String format) async {
    final existingIndex = _books.indexWhere((b) => b.id == book.id);
    final updatedBook = book.copyWith(
      localFilePath: localPath,
      isDownloaded: true,
      format: format,
      addedAt: DateTime.now(),
    );

    if (existingIndex >= 0) {
      _books[existingIndex] = updatedBook;
    } else {
      _books.insert(0, updatedBook);
    }

    await LocalLibraryService.saveBooks(_books);
    notifyListeners();
  }

  /// Updates reading progress
  Future<void> updateReadingProgress({
    required String bookId,
    required double progress,
    required int position,
    int? totalUnits,
  }) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      _books[index] = _books[index].copyWith(
        readingProgress: progress.clamp(0.0, 1.0),
        lastPosition: position,
        totalUnits: totalUnits ?? _books[index].totalUnits,
        lastReadAt: DateTime.now(),
      );
      await LocalLibraryService.saveBooks(_books);
      notifyListeners();
    }
  }

  /// Removes a book from library and disk
  Future<void> removeBook(String bookId) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final book = _books[index];
      if (book.localFilePath != null) {
        await FileStorageService.deleteLocalFile(book.localFilePath);
      }
      _books.removeAt(index);
      _favoriteIds.remove(bookId);
      _ownedIds.remove(bookId);
      _wishlistIds.remove(bookId);

      for (var col in _collections) {
        col.bookIds.remove(bookId);
      }

      await LocalLibraryService.saveBooks(_books);
      await LocalLibraryService.saveFavoriteIds(_favoriteIds);
      await LocalLibraryService.saveCollections(_collections);
      notifyListeners();
    }
  }

  /// Collection management
  Future<void> createCollection(String name) async {
    if (name.trim().isEmpty) return;
    final newCol = BookCollection(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
    );
    _collections.add(newCol);
    await LocalLibraryService.saveCollections(_collections);
    notifyListeners();
  }

  Future<void> deleteCollection(String collectionId) async {
    _collections.removeWhere((c) => c.id == collectionId);
    await LocalLibraryService.saveCollections(_collections);
    notifyListeners();
  }

  Future<void> toggleBookInCollection(String collectionId, String bookId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx >= 0) {
      final col = _collections[idx];
      final newBookIds = List<String>.from(col.bookIds);
      if (newBookIds.contains(bookId)) {
        newBookIds.remove(bookId);
      } else {
        newBookIds.add(bookId);
      }
      _collections[idx] = col.copyWith(bookIds: newBookIds);
      await LocalLibraryService.saveCollections(_collections);
      notifyListeners();
    }
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Exports library metadata to JSON string for backup
  String exportLibraryJson() {
    final data = {
      'books': _books.map((b) => b.toJson()).toList(),
      'favorites': _favoriteIds.toList(),
      'owned': _ownedIds.toList(),
      'wishlist': _wishlistIds.toList(),
      'collections': _collections.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return json.encode(data);
  }

  /// Imports library backup from JSON string
  Future<bool> importLibraryJson(String jsonString) async {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      if (map.containsKey('books')) {
        final booksList = (map['books'] as List<dynamic>)
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
        _books = booksList;
        await LocalLibraryService.saveBooks(_books);
      }
      if (map.containsKey('favorites')) {
        _favoriteIds = (map['favorites'] as List<dynamic>).map((e) => e.toString()).toSet();
        await LocalLibraryService.saveFavoriteIds(_favoriteIds);
      }
      if (map.containsKey('collections')) {
        _collections = (map['collections'] as List<dynamic>)
            .map((e) => BookCollection.fromJson(e as Map<String, dynamic>))
            .toList();
        await LocalLibraryService.saveCollections(_collections);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
