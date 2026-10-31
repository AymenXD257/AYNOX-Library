import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aynox_library/services/storage/file_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileStorageService Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aynox_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('validateBookFile rejects corrupt or incomplete files', () async {
      final corruptFile = File('${tempDir.path}/corrupt.pdf');
      await corruptFile.writeAsString('HTML Error 404 Not Found');

      final isValid = await FileStorageService.validateBookFile(corruptFile, 'pdf');
      expect(isValid, false);
    });

    test('validateBookFile approves valid PDF with magic bytes %PDF-', () async {
      final validPdf = File('${tempDir.path}/valid.pdf');
      await validPdf.writeAsString('%PDF-1.4\n%âãÏÓ\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF');

      final isValid = await FileStorageService.validateBookFile(validPdf, 'pdf');
      expect(isValid, true);
    });

    test('validateBookFile detects HTML error pages mistakenly saved as TXT', () async {
      final htmlErrorFile = File('${tempDir.path}/error.txt');
      await htmlErrorFile.writeAsString('<!DOCTYPE html><html><head><title>404 Not Found</title></head></html>');

      final isValid = await FileStorageService.validateBookFile(htmlErrorFile, 'txt');
      expect(isValid, false);
    });

    test('validateBookFile approves genuine text content', () async {
      final validTxt = File('${tempDir.path}/book.txt');
      await validTxt.writeAsString('Chapter 1: In the beginning of the journey across the mountains...');

      final isValid = await FileStorageService.validateBookFile(validTxt, 'txt');
      expect(isValid, true);
    });
  });
}
