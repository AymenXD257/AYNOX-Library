# AYNOX Library 📚

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)

**AYNOX Library** is a professional, multilingual digital and physical book platform for discovering, reading, downloading, and managing books from legitimate, verified open libraries worldwide, with realistic paper-like offline reading.

Designed and engineered by **Aymen (AYNOX)** — Computer Science @ USTO, Algeria.

---

## 🌟 Key Features

### 1. Legitimate Multi-Provider Book Discovery
- **Unified Search:** Concurrently queries multiple legal open libraries using `Future.wait` with independent timeouts and deduplication.
- **Project Gutenberg / Gutendex:** Access to over 70,000 public domain classics.
- **Internet Archive:** Millions of scanned historical texts with original scanned PDF views.
- **Open Library:** Extensive bibliographic catalog with physical book records and digital full-text access.
- **Standard Ebooks:** High-typography, beautifully formatted public-domain EPUB editions.
- **Arabic Heritage Collections:** Legitimate public domain Arabic masterpieces with verified downloads.
- **Directory of Open Access Books (DOAB):** Peer-reviewed open-access academic monographs and research papers.
- **Physical Book Discovery:** Search printed books by title, author, and ISBN; manage your home bookshelf and purchase wishlist.

### 2. Realistic Paper-like Reading Engine
- **3 Selectable Page-Turn Modes:**
  - 📖 **Page Curl:** Interactive realistic 3D page curl simulation.
  - ↔️ **Slide:** Horizontal page-by-page transition.
  - ↕️ **Scroll:** Traditional continuous reading with running headers and page markers.
- **4 Paper Textures / Backgrounds:**
  - *Midnight Dark* (for night reading)
  - *Pristine White* (high contrast daylight)
  - *Sepia Warm* (warm paper tone)
  - *Classic Book Paper* (parchment feel)
- **Scanned PDF Viewer:** High-fidelity original scanned pages, zoom & pan, thumbnail navigation, go-to-page, and persistent reading position.
- **EPUB Engine:** Structured rendering preserving chapter headings, paragraphs, blockquotes, and embedded illustrations from the EPUB package.
- **Paginated TXT Viewer:** Clean text layout with balanced margins, headers, footers, and scalable character density based on font size.
- **Full RTL & Arabic Typography:** Natural Arabic reading direction, balanced line heights, and bookmark support.

### 3. Bulletproof Download Manager
- **Integrity Verification:** Uses `.part` temporary files and atomic renaming.
- **Magic Byte Validation:** Validates `%PDF-` for PDFs, EPUB ZIP structures, and verifies TXT encoding to prevent HTML error pages from being treated as books.
- **Automatic Fallback:** If preferred format fails, automatically attempts valid alternative formats (EPUB → PDF → TXT).
- **Exponential Backoff:** Up to 3 retries with delay backoff and cancel support.
- **Safe Cache Management:** "Clear Cache" only removes temporary files without touching saved or imported books.

### 4. Multilingual & RTL/LTR Support
- **Complete 3-Language Support:** Arabic (العربية), English, and French (Français).
- Dynamic RTL/LTR layout switching across all screens, dialogs, directional icons, and drawers.
- Zero hardcoded English strings.

---

## 🚀 Setup & Build Instructions

### Prerequisites
- **Flutter SDK:** 3.7.0 or higher
- **Dart SDK:** ^3.7.0
- **Android SDK:** API 21+ (compileSdk: 35)
- **Java Development Kit:** JDK 17

### Installation
```bash
# Clone the repository
git clone https://github.com/aynox/aynox-library.git
cd aynox-library

# Fetch dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run automated tests
flutter test

# Launch on connected Android device or emulator
flutter run
```

---

## 🔑 Production Release Signing

To build a release-signed APK:

1. Generate a keystore if you do not already have one:
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aynox-upload
```

2. Copy `android/key.properties.example` to `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=aynox-upload
storeFile=upload-keystore.jks
```

3. Build the release APK:
```bash
flutter build apk --release
```
The output APK will be placed in `build/app/outputs/flutter-apk/app-release.apk`.

> **Note:** If `android/key.properties` is absent, the Gradle build will automatically fallback to the debug keystore for local development, preventing build crashes while ensuring production passwords are never committed.

---

## 📁 Architecture Overview

```text
lib/
  core/
    constants/        # App constants, category mappings, storage keys
    localization/     # Multilingual translations (Arabic RTL, English, French)
    theme/            # Light & Dark color schemes and theme tokens
  models/
    book.dart         # Digital & physical book domain model
    bookmark.dart     # Page bookmarks and reading snippets
    collection.dart   # User-created custom shelves
  providers/
    discovery_provider.dart  # Multi-source search, pagination, format filters
    download_provider.dart   # Resilient download tasks, fallback, cancellation
    library_provider.dart    # Local library, collections, wishlist, physical shelf
    settings_provider.dart   # Persisted themes, paper styles, page turn modes
  services/
    sources/          # Scalable BookSource abstraction
      book_source.dart
      source_aggregator.dart
      gutendex_source.dart
      open_library_source.dart
      internet_archive_source.dart
      standard_ebooks_source.dart
      arabic_heritage_source.dart
      doab_source.dart
    storage/          # Atomic .part download handling and local database
      file_storage_service.dart
      local_library_service.dart
    reader/           # Pure Dart EPUB parser & block extractor
      epub_parser.dart
  features/
    home/             # Brand dashboard, continue reading, discovery preview
    discover/         # Unified search, library counts, pagination, format chips
    details/          # Digital downloads & physical book discovery actions
    library/          # Custom collections, imported books, wishlist, ownership
    downloads/        # Active tasks, progress, storage usage
    reader/           # Scanned PDF, paginated EPUB/TXT with Page Curl & Slide
    settings/         # Theme, RTL, diagnostics, paper style, backups
```

---

## ⚖️ Legal & Copyright Compliance

AYNOX Library strictly adheres to copyright and digital intellectual property laws:
- **No Piracy Services:** Does not interface with pirate databases (LibGen, Z-Library).
- **Public Domain & Open Access Only:** Downloads are restricted to legally open, public domain, or Creative Commons licensed books.
- **Respect for Digital Lending:** Books subject to controlled digital lending (Open Library / IA Lending) are presented for physical or catalog discovery without DRM circumvention.

---

## 🤝 Adding a New Book Source

To add a new verified legal library:
1. Implement the `BookSource` interface in `lib/services/sources/`:
```dart
class MyNewSource implements BookSource {
  @override String get id => 'my_source';
  @override String get name => 'My Source Name';
  @override bool get supportsPhysical => false;
  @override bool get supportsArabic => false;

  @override
  Future<List<Book>> search(String query, {String? language, String? category, int page = 1}) async { ... }

  @override
  Future<List<Book>> browse({String? category, String? language, int page = 1}) async { ... }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async { ... }
}
```
2. Register the source instance in `SourceAggregator` constructor. It will automatically participate in concurrent searches, error isolation, pagination, and provider diagnostics!

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
