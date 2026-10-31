import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

enum EpubBlockType { heading, paragraph, image, quote }

class EpubContentBlock {
  final EpubBlockType type;
  final String text;
  final Uint8List? imageBytes;
  final String? imagePath;
  final int headingLevel;

  EpubContentBlock({
    required this.type,
    this.text = '',
    this.imageBytes,
    this.imagePath,
    this.headingLevel = 1,
  });
}

class EpubChapter {
  final String id;
  final String title;
  final List<EpubContentBlock> blocks;
  final String plainText;

  EpubChapter({
    required this.id,
    required this.title,
    required this.blocks,
    required this.plainText,
  });
}

class EpubTocItem {
  final String title;
  final String contentHref;
  final int chapterIndex;

  EpubTocItem({
    required this.title,
    required this.contentHref,
    required this.chapterIndex,
  });
}

class EpubBookData {
  final String title;
  final String author;
  final List<EpubChapter> chapters;
  final List<EpubTocItem> tableOfContents;
  final Map<String, Uint8List> images;

  EpubBookData({
    required this.title,
    required this.author,
    required this.chapters,
    this.tableOfContents = const [],
    this.images = const {},
  });
}

class EpubParser {
  /// Parses an EPUB file into structured chapters, formatting blocks, table of contents, and embedded images
  static Future<EpubBookData> parseEpubFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('EPUB file not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Locate container.xml to find the OPF package path
    String opfPath = 'OEBPS/content.opf';
    for (final f in archive) {
      if (f.name == 'META-INF/container.xml') {
        try {
          final xmlStr = utf8.decode(f.content as List<int>);
          final doc = XmlDocument.parse(xmlStr);
          final rootfile = doc.findAllElements('rootfile').firstOrNull;
          if (rootfile != null) {
            opfPath = rootfile.getAttribute('full-path') ?? opfPath;
          }
        } catch (_) {}
        break;
      }
    }

    // 2. Parse OPF
    ArchiveFile? opfFile;
    for (final f in archive) {
      if (f.name == opfPath || f.name.endsWith('.opf')) {
        opfFile = f;
        break;
      }
    }

    String bookTitle = 'EPUB Book';
    String bookAuthor = 'Unknown Author';
    final manifestHrefById = <String, String>{};
    final manifestMediaTypeById = <String, String>{};
    final spineItemIds = <String>[];
    String? ncxPath;

    final opfDir = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/'))
        : '';

    if (opfFile != null) {
      try {
        final opfXml = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
        final doc = XmlDocument.parse(opfXml);

        bookTitle = doc.findAllElements('dc:title').firstOrNull?.innerText.trim() ??
            doc.findAllElements('title').firstOrNull?.innerText.trim() ??
            bookTitle;

        bookAuthor = doc.findAllElements('dc:creator').firstOrNull?.innerText.trim() ??
            doc.findAllElements('creator').firstOrNull?.innerText.trim() ??
            bookAuthor;

        for (final item in doc.findAllElements('item')) {
          final id = item.getAttribute('id');
          final href = item.getAttribute('href');
          final mediaType = item.getAttribute('media-type');
          if (id != null && href != null) {
            final fullHref = opfDir.isEmpty ? href : '$opfDir/$href';
            manifestHrefById[id] = fullHref;
            if (mediaType != null) {
              manifestMediaTypeById[id] = mediaType;
              if (mediaType == 'application/x-dtbncx+xml') {
                ncxPath = fullHref;
              }
            }
          }
        }

        for (final itemref in doc.findAllElements('itemref')) {
          final idref = itemref.getAttribute('idref');
          if (idref != null) {
            spineItemIds.add(idref);
          }
        }
      } catch (_) {}
    }

    // 3. Extract embedded images
    final extractedImages = <String, Uint8List>{};
    for (final f in archive) {
      final nameLower = f.name.toLowerCase();
      if (nameLower.endsWith('.jpg') ||
          nameLower.endsWith('.jpeg') ||
          nameLower.endsWith('.png') ||
          nameLower.endsWith('.gif') ||
          nameLower.endsWith('.webp')) {
        try {
          final content = f.content as List<int>;
          extractedImages[f.name] = Uint8List.fromList(content);
          // Also map basename for relative references in HTML
          final base = f.name.split('/').last;
          extractedImages[base] = Uint8List.fromList(content);
        } catch (_) {}
      }
    }

    // 4. Parse chapters in spine order
    final chapters = <EpubChapter>[];

    for (int i = 0; i < spineItemIds.length; i++) {
      final id = spineItemIds[i];
      final href = manifestHrefById[id];
      if (href == null) continue;

      ArchiveFile? chapterFile;
      for (final f in archive) {
        if (f.name == href || f.name.endsWith(href) || href.endsWith(f.name)) {
          chapterFile = f;
          break;
        }
      }

      if (chapterFile != null) {
        try {
          final rawContent = utf8.decode(chapterFile.content as List<int>, allowMalformed: true);
          final parsedChapter = _parseHtmlChapter(id, rawContent, i + 1, extractedImages);
          if (parsedChapter.blocks.isNotEmpty || parsedChapter.plainText.trim().isNotEmpty) {
            chapters.add(parsedChapter);
          }
        } catch (_) {}
      }
    }

    // Fallback: If spine items were missing or empty, parse all HTML/XHTML files
    if (chapters.isEmpty) {
      int count = 1;
      for (final f in archive) {
        final name = f.name.toLowerCase();
        if ((name.endsWith('.html') || name.endsWith('.xhtml')) && !name.contains('nav')) {
          try {
            final raw = utf8.decode(f.content as List<int>, allowMalformed: true);
            final c = _parseHtmlChapter(f.name, raw, count, extractedImages);
            if (c.blocks.isNotEmpty) {
              chapters.add(c);
              count++;
            }
          } catch (_) {}
        }
      }
    }

    // 5. Build Table of Contents
    final tocList = <EpubTocItem>[];
    if (ncxPath != null) {
      for (final f in archive) {
        if (f.name == ncxPath || f.name.endsWith('.ncx')) {
          try {
            final ncxXml = utf8.decode(f.content as List<int>, allowMalformed: true);
            final doc = XmlDocument.parse(ncxXml);
            for (final navPoint in doc.findAllElements('navPoint')) {
              final text = navPoint.findAllElements('text').firstOrNull?.innerText.trim();
              final src = navPoint.findAllElements('content').firstOrNull?.getAttribute('src');
              if (text != null && text.isNotEmpty) {
                // Find matching chapter index
                int chIdx = 0;
                if (src != null) {
                  final baseSrc = src.split('#').first;
                  final match = chapters.indexWhere((c) => c.id.contains(baseSrc) || baseSrc.contains(c.id));
                  if (match >= 0) chIdx = match;
                }
                tocList.add(EpubTocItem(title: text, contentHref: src ?? '', chapterIndex: chIdx));
              }
            }
          } catch (_) {}
          break;
        }
      }
    }

    // If TOC is empty, build from parsed chapters
    if (tocList.isEmpty) {
      for (int i = 0; i < chapters.length; i++) {
        tocList.add(EpubTocItem(
          title: chapters[i].title,
          contentHref: chapters[i].id,
          chapterIndex: i,
        ));
      }
    }

    if (chapters.isEmpty) {
      chapters.add(EpubChapter(
        id: 'default',
        title: 'Full Document',
        blocks: [EpubContentBlock(type: EpubBlockType.paragraph, text: 'No text content could be extracted from this document.')],
        plainText: 'No text content could be extracted.',
      ));
    }

    return EpubBookData(
      title: bookTitle,
      author: bookAuthor,
      chapters: chapters,
      tableOfContents: tocList,
      images: extractedImages,
    );
  }

  static EpubChapter _parseHtmlChapter(
    String id,
    String html,
    int chapterIndex,
    Map<String, Uint8List> images,
  ) {
    String title = 'Chapter $chapterIndex';
    final blocks = <EpubContentBlock>[];
    final plainTextBuffer = StringBuffer();

    // Extract title from <title>, <h1>, <h2>, or <h3>
    final titleMatch = RegExp(r'<title[^>]*>(.*?)<\/title>', caseSensitive: false).firstMatch(html) ??
        RegExp(r'<h[1-3][^>]*>(.*?)<\/h[1-3]>', caseSensitive: false).firstMatch(html);
    if (titleMatch != null) {
      final t = _stripTags(titleMatch.group(1) ?? '').trim();
      if (t.isNotEmpty && t.length < 80) {
        title = t;
      }
    }

    // Clean scripts, styles, XML headers
    final cleaned = html
        .replaceAll(RegExp(r'<\?xml[^>]*\?>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '');

    // Match HTML tags of interest: headings, paragraphs, images, blockquotes
    final elementRegex = RegExp(
      r'<(h[1-6]|p|blockquote|img|image)([^>]*)>(.*?)(?:<\/\1>)?',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = elementRegex.allMatches(cleaned);
    for (final m in matches) {
      final tag = m.group(1)?.toLowerCase() ?? '';
      final attrs = m.group(2) ?? '';
      final inner = m.group(3) ?? '';

      if (tag.startsWith('h')) {
        final level = int.tryParse(tag.substring(1)) ?? 1;
        final text = _decodeEntities(_stripTags(inner)).trim();
        if (text.isNotEmpty) {
          blocks.add(EpubContentBlock(type: EpubBlockType.heading, text: text, headingLevel: level));
          plainTextBuffer.writeln('\n$text\n');
        }
      } else if (tag == 'p') {
        final text = _decodeEntities(_stripTags(inner)).trim();
        if (text.isNotEmpty) {
          blocks.add(EpubContentBlock(type: EpubBlockType.paragraph, text: text));
          plainTextBuffer.writeln('$text\n');
        }
      } else if (tag == 'blockquote') {
        final text = _decodeEntities(_stripTags(inner)).trim();
        if (text.isNotEmpty) {
          blocks.add(EpubContentBlock(type: EpubBlockType.quote, text: text));
          plainTextBuffer.writeln('> $text\n');
        }
      } else if (tag == 'img' || tag == 'image') {
        final srcMatch = RegExp(r'(?:src|href)=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(attrs);
        if (srcMatch != null) {
          final src = srcMatch.group(1) ?? '';
          final baseName = src.split('/').last;
          final imgBytes = images[src] ?? images[baseName];
          if (imgBytes != null) {
            blocks.add(EpubContentBlock(type: EpubBlockType.image, imageBytes: imgBytes, imagePath: src));
          }
        }
      }
    }

    // Fallback if no matching blocks found: extract stripped paragraphs
    if (blocks.isEmpty) {
      final rawText = _stripTags(cleaned);
      final paragraphs = rawText.split(RegExp(r'\n{2,}'));
      for (final p in paragraphs) {
        final t = _decodeEntities(p).trim();
        if (t.isNotEmpty) {
          blocks.add(EpubContentBlock(type: EpubBlockType.paragraph, text: t));
          plainTextBuffer.writeln('$t\n');
        }
      }
    }

    return EpubChapter(
      id: id,
      title: title,
      blocks: blocks,
      plainText: plainTextBuffer.toString(),
    );
  }

  static String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<\/p>|<\/div>|<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static String _decodeEntities(String str) {
    return str
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
