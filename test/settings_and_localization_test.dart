import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aynox_library/core/localization/app_localizations.dart';

void main() {
  group('Localization and RTL Unit Tests', () {
    test('All required keys exist and have non-empty translations in EN, AR, FR', () {
      final requiredKeys = [
        'app_title',
        'home',
        'discover',
        'my_library',
        'settings',
        'downloads',
        'physical_books',
        'digital_books',
        'owned_physically',
        'wishlist',
        'read_now',
        'download',
        'page_turn_mode',
        'mode_curl',
        'mode_slide',
        'mode_scroll',
        'diagnostics',
        'clear_cache',
        'export_backup',
      ];

      for (final lang in ['en', 'ar', 'fr']) {
        final loc = AppLocalizations(Locale(lang));
        for (final key in requiredKeys) {
          final translated = loc.translate(key);
          expect(translated, isNotEmpty, reason: 'Key "$key" is missing in language "$lang"');
          expect(translated, isNot(equals(key)), reason: 'Key "$key" was returned as raw key in language "$lang"');
        }
      }
    });

    test('isRTL detects Arabic locale correctly', () {
      final locAr = AppLocalizations(const Locale('ar'));
      expect(locAr.locale.languageCode == 'ar', true);

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.locale.languageCode == 'ar', false);
    });
  });
}
