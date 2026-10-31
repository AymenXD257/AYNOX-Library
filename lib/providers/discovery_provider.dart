import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/book.dart';
import '../services/sources/book_source.dart';
import '../services/sources/source_aggregator.dart';
import '../services/sources/arabic_heritage_source.dart';
import '../services/api/gutendex_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  final SourceAggregator _aggregator;

  List<Book> _discoveredBooks = [];
  List<Book> _featuredBooks = [];
  List<Book> _arabicClassics = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isOffline = false;
  bool _hasNextPage = true;
  String? _errorMessage;

  String _currentQuery = '';
  String _selectedCategory = 'All';
  String _selectedLanguage = 'All'; // 'All', 'Arabic', 'English', 'French'
  String _selectedFormat = 'All'; // 'All', 'PDF', 'EPUB', 'TXT', 'Physical'
  int _currentPage = 1;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Book> get discoveredBooks => _filterByFormat(_discoveredBooks);
  List<Book> get featuredBooks => _featuredBooks;
  List<Book> get arabicClassics => _arabicClassics;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isOffline => _isOffline;
  bool get hasNextPage => _hasNextPage;
  String? get errorMessage => _errorMessage;

  String get currentQuery => _currentQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedLanguage => _selectedLanguage;
  String get selectedFormat => _selectedFormat;
  int get currentPage => _currentPage;
  int get activeLibrariesCount => _aggregator.sources.length;
  Map<String, SourceDiagnostic> get sourceDiagnostics => _aggregator.diagnostics;

  DiscoveryProvider({SourceAggregator? aggregator})
      : _aggregator = aggregator ?? SourceAggregator() {
    _init();
  }

  Future<void> _init() async {
    _featuredBooks = GutendexService.getFeaturedClassics();
    _arabicClassics = ArabicHeritageSource.getFeaturedArabicBooks();

    // Check connectivity
    try {
      final results = await Connectivity().checkConnectivity();
      _isOffline = results.contains(ConnectivityResult.none);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final offline = results.contains(ConnectivityResult.none);
        if (_isOffline != offline) {
          _isOffline = offline;
          notifyListeners();
        }
      });
    } catch (_) {}

    await loadInitialCatalog();
  }

  List<Book> _filterByFormat(List<Book> books) {
    if (_selectedFormat == 'All') return books;
    if (_selectedFormat == 'Physical') {
      return books.where((b) => b.isPhysical).toList();
    }
    final target = _selectedFormat.toLowerCase();
    return books.where((b) => !b.isPhysical && b.availableFormats.contains(target)).toList();
  }

  Future<void> loadInitialCatalog() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    if (_isOffline) {
      _discoveredBooks = [..._arabicClassics, ..._featuredBooks];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final result = await _aggregator.search(
        query: '',
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        language: _selectedLanguage == 'All' ? null : _selectedLanguage,
        physicalOnly: _selectedFormat == 'Physical',
        page: 1,
      );

      _discoveredBooks = result.books;
      _hasNextPage = result.hasNextPage;
      if (_discoveredBooks.isEmpty) {
        // Only if catalog was completely unreachable, provide the curated offline titles
        _discoveredBooks = [..._arabicClassics, ..._featuredBooks];
      }
    } catch (e) {
      _errorMessage = 'Failed to load catalog: $e';
      _discoveredBooks = [..._arabicClassics, ..._featuredBooks];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _currentPage = 1;
    search(query: _currentQuery);
  }

  void setLanguage(String language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    _currentPage = 1;
    search(query: _currentQuery);
  }

  void setFormat(String format) {
    if (_selectedFormat == format) return;
    _selectedFormat = format;
    _currentPage = 1;
    search(query: _currentQuery);
  }

  Future<void> search({String? query}) async {
    if (query != null) {
      _currentQuery = query.trim();
    }
    _currentPage = 1;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isOffline) {
      _discoveredBooks = [..._arabicClassics, ..._featuredBooks].where((b) {
        final q = _currentQuery.toLowerCase();
        final matchesQuery = q.isEmpty ||
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);
        return matchesQuery;
      }).toList();
      _isLoading = false;
      _hasNextPage = false;
      notifyListeners();
      return;
    }

    try {
      final result = await _aggregator.search(
        query: _currentQuery,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        language: _selectedLanguage == 'All' ? null : _selectedLanguage,
        physicalOnly: _selectedFormat == 'Physical',
        page: 1,
      );

      // We do NOT replace empty search results with fake books!
      // Clean honest reporting as requested by spec.
      _discoveredBooks = result.books;
      _hasNextPage = result.hasNextPage;
    } catch (e) {
      _errorMessage = e.toString();
      _discoveredBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Real pagination / Load More
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNextPage || _isOffline) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;

    try {
      final result = await _aggregator.search(
        query: _currentQuery,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        language: _selectedLanguage == 'All' ? null : _selectedLanguage,
        physicalOnly: _selectedFormat == 'Physical',
        page: nextPage,
      );

      if (result.books.isNotEmpty) {
        _currentPage = nextPage;
        _discoveredBooks.addAll(result.books);
        _hasNextPage = result.hasNextPage;
      } else {
        _hasNextPage = false;
      }
    } catch (_) {
      _hasNextPage = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> testAllSources() async {
    await _aggregator.testAllSources();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
