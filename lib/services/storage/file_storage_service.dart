import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DownloadCancellationException implements Exception {
  final String message;
  DownloadCancellationException([this.message = 'Download cancelled by user']);
  @override
  String toString() => message;
}

class FileStorageService {
  static const String userAgent = 'AYNOX-Library/1.0.0 (Multilingual Open Book Platform)';

  /// Permanent directory for user's downloaded and imported books
  static Future<Directory> getBooksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Temporary cache directory for downloads in progress (.part files) and cached covers
  static Future<Directory> getTempCacheDirectory() async {
    final appDir = await getTemporaryDirectory();
    final tempDir = Directory('${appDir.path}/aynox_cache');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// Copies an imported file into the application documents directory
  static Future<String> saveImportedFile(String sourceFilePath, String fileName) async {
    final booksDir = await getBooksDirectory();
    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destinationPath = '${booksDir.path}/${timestamp}_$sanitizedName';

    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  /// Validates format magic bytes/structure of a file on disk
  static Future<bool> validateBookFile(File file, String format) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 10) return false;

    final ext = format.toLowerCase().replaceAll('.', '');
    final headerBytes = await file.openRead(0, 1024).first;

    if (ext == 'pdf') {
      // PDF magic bytes: '%PDF-'
      final headerStr = String.fromCharCodes(headerBytes.take(10));
      return headerStr.contains('%PDF-');
    } else if (ext == 'epub') {
      // EPUB is a ZIP archive containing mimetype or META-INF/container.xml
      if (headerBytes.length < 4) return false;
      // ZIP magic bytes: PK\x03\x04 or PK\x05\x06
      final isZip = headerBytes[0] == 0x50 && headerBytes[1] == 0x4B;
      if (!isZip) return false;

      try {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final hasContainer = archive.any((f) =>
            f.name == 'META-INF/container.xml' || f.name.endsWith('.opf') || f.name == 'mimetype');
        return hasContainer;
      } catch (_) {
        return false;
      }
    } else if (ext == 'txt') {
      // TXT should not be an HTML error page or binary garbage
      final sampleStr = utf8.decode(headerBytes, allowMalformed: true).trim().toLowerCase();
      if (sampleStr.startsWith('<!doctype html') ||
          sampleStr.startsWith('<html') ||
          sampleStr.contains('<title>404') ||
          sampleStr.contains('<title>403')) {
        return false;
      }
      return true;
    }

    return length > 0;
  }

  /// Downloads a remote book file with .part temporary files, atomic rename, validation,
  /// redirects handling, exponential backoff retries, and cancellation tokens.
  static Future<String> downloadBookFile({
    required String url,
    required String bookId,
    required String format,
    void Function(double? progress)? onProgress,
    bool Function()? isCancelled,
    http.Client? clientOverride,
  }) async {
    final booksDir = await getBooksDirectory();
    final tempDir = await getTempCacheDirectory();
    final sanitizedId = bookId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final ext = format.toLowerCase().replaceAll('.', '');
    final finalFileName = '${sanitizedId}.$ext';
    final targetFile = File('${booksDir.path}/$finalFileName');

    // 1. Verify if an existing file is already complete and valid
    if (await targetFile.exists()) {
      final isValid = await validateBookFile(targetFile, ext);
      if (isValid) {
        onProgress?.call(1.0);
        return targetFile.path;
      } else {
        // Corrupted file leftover from previous failed run - delete it
        try {
          await targetFile.delete();
        } catch (_) {}
      }
    }

    final partFile = File('${tempDir.path}/${sanitizedId}_${DateTime.now().millisecondsSinceEpoch}.part');

    // Retry configuration: 3 attempts with exponential backoff
    const maxRetries = 3;
    Duration retryDelay = const Duration(seconds: 1);
    Object? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (isCancelled?.call() == true) {
        if (await partFile.exists()) await partFile.delete();
        throw DownloadCancellationException();
      }

      http.Client client = clientOverride ?? http.Client();
      IOSink? sink;
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['User-Agent'] = userAgent;
        request.headers['Accept'] = '*/*';

        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 25));

        // Follow manual redirect if 301/302/303/307/308
        http.StreamedResponse finalResponse = streamedResponse;
        if ([301, 302, 303, 307, 308].contains(streamedResponse.statusCode)) {
          final location = streamedResponse.headers['location'];
          if (location != null && location.isNotEmpty) {
            final redirectUri = Uri.parse(url).resolve(location);
            final redirectRequest = http.Request('GET', redirectUri);
            redirectRequest.headers['User-Agent'] = userAgent;
            redirectRequest.headers['Accept'] = '*/*';
            finalResponse = await client.send(redirectRequest).timeout(const Duration(seconds: 25));
          }
        }

        if (finalResponse.statusCode < 200 || finalResponse.statusCode >= 300) {
          throw HttpException('HTTP ${finalResponse.statusCode}: ${finalResponse.reasonPhrase}');
        }

        final contentLength = finalResponse.contentLength;
        int receivedBytes = 0;

        if (await partFile.exists()) {
          await partFile.delete();
        }
        sink = partFile.openWrite();

        await for (final chunk in finalResponse.stream) {
          if (isCancelled?.call() == true) {
            throw DownloadCancellationException();
          }

          sink.add(chunk);
          receivedBytes += chunk.length;

          if (contentLength != null && contentLength > 0) {
            onProgress?.call((receivedBytes / contentLength).clamp(0.0, 1.0));
          } else {
            // Indeterminate progress when Content-Length is unavailable
            onProgress?.call(null);
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;

        // 2. Validate file integrity and magic bytes
        final isValid = await validateBookFile(partFile, ext);
        if (!isValid) {
          throw const FormatException('Downloaded file failed format validation (invalid magic bytes or HTML error response).');
        }

        // 3. Atomically move / rename .part file to final destination
        try {
          await partFile.rename(targetFile.path);
        } catch (_) {
          // Fallback copy + delete for across-filesystem moves
          await partFile.copy(targetFile.path);
          await partFile.delete();
        }

        onProgress?.call(1.0);
        return targetFile.path;
      } catch (e) {
        lastError = e;
        if (sink != null) {
          try {
            await sink.close();
          } catch (_) {}
        }
        if (await partFile.exists()) {
          try {
            await partFile.delete();
          } catch (_) {}
        }

        if (e is DownloadCancellationException) {
          rethrow;
        }

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          retryDelay *= 2; // Exponential backoff (1s, 2s, 4s)
        }
      } finally {
        if (clientOverride == null) {
          client.close();
        }
      }
    }

    throw Exception('Download failed after $maxRetries attempts: $lastError');
  }

  /// Deletes a file from local storage safely
  static Future<bool> deleteLocalFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Calculates total bytes used by saved user books
  static Future<int> calculateTotalStorageUsage() async {
    try {
      final booksDir = await getBooksDirectory();
      if (!await booksDir.exists()) return 0;

      int total = 0;
      await for (final entity in booksDir.list(recursive: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Calculates temporary cache bytes (excluding user books)
  static Future<int> calculateCacheUsage() async {
    try {
      final tempDir = await getTempCacheDirectory();
      if (!await tempDir.exists()) return 0;

      int total = 0;
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Clears ONLY temporary cache files and in-progress part files.
  /// NEVER deletes user's saved or imported books!
  static Future<void> clearTemporaryCache() async {
    try {
      final tempDir = await getTempCacheDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create(recursive: true);
      }
    } catch (_) {}
  }
}
