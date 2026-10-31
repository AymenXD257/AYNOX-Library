import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage/file_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontSize = 17.0;
  double _lineSpacing = 1.6;
  String _readerTheme = 'dark'; // 'dark', 'light', 'sepia', 'book'
  String _pageTurnMode = 'curl'; // 'curl', 'slide', 'scroll'
  String _preferredFormat = 'epub'; // 'epub', 'pdf', 'txt'
  String _fontFamily = 'Amiri';
  bool _animationsEnabled = true;
  bool _reducedMotion = false;
  int _storageBytes = 0;
  int _cacheBytes = 0;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;
  String get readerTheme => _readerTheme;
  String get pageTurnMode => _pageTurnMode;
  String get preferredFormat => _preferredFormat;
  String get fontFamily => _fontFamily;
  bool get animationsEnabled => _animationsEnabled;
  bool get reducedMotion => _reducedMotion;
  int get storageBytes => _storageBytes;
  int get cacheBytes => _cacheBytes;

  String get storageFormatted => _formatBytes(_storageBytes);
  String get cacheFormatted => _formatBytes(_cacheBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final lang = prefs.getString(AppConstants.keyLocale) ?? 'en';
    _locale = Locale(lang);

    final themeStr = prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    _fontSize = prefs.getDouble(AppConstants.keyFontSize) ?? 17.0;
    _lineSpacing = prefs.getDouble(AppConstants.keyLineSpacing) ?? 1.6;
    _readerTheme = prefs.getString(AppConstants.keyReaderTheme) ?? 'dark';
    _pageTurnMode = prefs.getString(AppConstants.keyPageTurnMode) ?? 'curl';
    _preferredFormat = prefs.getString(AppConstants.keyPreferredFormat) ?? 'epub';
    _fontFamily = prefs.getString(AppConstants.keyFontFamily) ?? 'Amiri';
    _animationsEnabled = prefs.getBool(AppConstants.keyAnimationsEnabled) ?? true;
    _reducedMotion = prefs.getBool(AppConstants.keyReducedMotion) ?? false;

    await refreshStorageUsage();
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.system) val = 'system';
    await prefs.setString(AppConstants.keyThemeMode, val);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 32.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyFontSize, _fontSize);
    notifyListeners();
  }

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing.clamp(1.1, 2.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLineSpacing, _lineSpacing);
    notifyListeners();
  }

  Future<void> setReaderTheme(String theme) async {
    _readerTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyReaderTheme, theme);
    notifyListeners();
  }

  Future<void> setPageTurnMode(String mode) async {
    _pageTurnMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPageTurnMode, mode);
    notifyListeners();
  }

  Future<void> setPreferredFormat(String format) async {
    _preferredFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPreferredFormat, format);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFontFamily, family);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAnimationsEnabled, enabled);
    notifyListeners();
  }

  Future<void> setReducedMotion(bool reduced) async {
    _reducedMotion = reduced;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyReducedMotion, reduced);
    notifyListeners();
  }

  Future<void> refreshStorageUsage() async {
    _storageBytes = await FileStorageService.calculateTotalStorageUsage();
    _cacheBytes = await FileStorageService.calculateCacheUsage();
    notifyListeners();
  }

  /// Clears temporary cache only, never deletes user books
  Future<void> clearTemporaryCache() async {
    await FileStorageService.clearTemporaryCache();
    await refreshStorageUsage();
  }
}
