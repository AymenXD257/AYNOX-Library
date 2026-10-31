import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';
import '../../models/collection.dart';
import '../../models/bookmark.dart';
import '../../core/constants/app_constants.dart';
import 'file_storage_service.dart';

class LocalLibraryService {
  static const String _libraryFileName = 'aynox_local_library.json';
  static const String _collectionsFileName = 'aynox_collections.json';
  static const String _firstRunKey = 'aynox_has_initialized_samples';

  static Future<File> _getLibraryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_libraryFileName');
  }

  static Future<File> _getCollectionsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_collectionsFileName');
  }

  /// Initialize default sample books on first app launch
  static Future<void> initializeSampleBooksIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInitialized = prefs.getBool(_firstRunKey) ?? false;
    if (hasInitialized) return;

    final booksDir = await FileStorageService.getBooksDirectory();
    final initialBooks = <Book>[];

    // 1. Copy sample EPUB: The Time Machine
    try {
      final epubData = await rootBundle.load('assets/sample/the_time_machine.epub');
      final epubFile = File('${booksDir.path}/the_time_machine.epub');
      await epubFile.writeAsBytes(epubData.buffer.asUint8List());

      initialBooks.add(Book(
        id: 'sample_time_machine',
        title: 'The Time Machine',
        author: 'H. G. Wells',
        description: 'An iconic science fiction novella recounting the traveler\'s journey into the far future.',
        language: 'en',
        source: 'AYNOX Bundled Classics',
        localFilePath: epubFile.path,
        isDownloaded: true,
        isImported: true,
        format: 'epub',
        addedAt: DateTime.now(),
      ));
    } catch (_) {}

    // 2. Copy sample Arabic TXT: Hayy Ibn Yaqzan
    try {
      final arData = await rootBundle.loadString('assets/sample/hayy_ibn_yaqzan_ar.txt');
      final arFile = File('${booksDir.path}/hayy_ibn_yaqzan.txt');
      await arFile.writeAsString(arData, encoding: utf8);

      initialBooks.add(Book(
        id: 'sample_hayy_ibn_yaqzan',
        title: 'حي بن يقظان',
        author: 'ابن طفيل الأندلسي',
        description: 'قصة فلسفية رمزية تتناول ارتقاء الفكر الإنساني وتأمل بديع خلق الكون بالفطرة السليمة.',
        language: 'ar',
        source: 'AYNOX Bundled Classics',
        localFilePath: arFile.path,
        isDownloaded: true,
        isImported: true,
        format: 'txt',
        addedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ));
    } catch (_) {}

    // 3. Copy sample English TXT: The Art of War
    try {
      final enData = await rootBundle.loadString('assets/sample/art_of_war_en.txt');
      final enFile = File('${booksDir.path}/art_of_war.txt');
      await enFile.writeAsString(enData, encoding: utf8);

      initialBooks.add(Book(
        id: 'sample_art_of_war',
        title: 'The Art of War',
        author: 'Sun Tzu',
        description: 'Ancient military treatise attributed to Sun Tzu, composed of 13 chapters devoted to strategy.',
        language: 'en',
        source: 'AYNOX Bundled Classics',
        localFilePath: enFile.path,
        isDownloaded: true,
        isImported: true,
        format: 'txt',
        addedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ));
    } catch (_) {}

    if (initialBooks.isNotEmpty) {
      await saveBooks(initialBooks);
    }
    await prefs.setBool(_firstRunKey, true);
  }

  /// Load all books currently stored in user's library
  static Future<List<Book>> loadBooks() async {
    try {
      final file = await _getLibraryFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final list = json.decode(content) as List<dynamic>;
      return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save books list to local library JSON
  static Future<void> saveBooks(List<Book> books) async {
    final file = await _getLibraryFile();
    final jsonString = json.encode(books.map((b) => b.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Load favorite book IDs
  static Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.keyFavorites) ?? [];
    return list.toSet();
  }

  /// Save favorite book IDs
  static Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyFavorites, ids.toList());
  }

  /// Load user custom collections
  static Future<List<BookCollection>> loadCollections() async {
    try {
      final file = await _getCollectionsFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final list = json.decode(content) as List<dynamic>;
      return list.map((e) => BookCollection.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save user custom collections
  static Future<void> saveCollections(List<BookCollection> collections) async {
    final file = await _getCollectionsFile();
    final jsonString = json.encode(collections.map((c) => c.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Bookmarks management per book
  static Future<List<Bookmark>> loadBookmarks(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.keyBookmarks}$bookId';
    final jsonList = prefs.getStringList(key) ?? [];
    return jsonList.map((e) => Bookmark.fromJson(json.decode(e))).toList();
  }

  static Future<void> saveBookmarks(String bookId, List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.keyBookmarks}$bookId';
    final jsonList = bookmarks.map((b) => json.encode(b.toJson())).toList();
    await prefs.setStringList(key, jsonList);
  }
}
