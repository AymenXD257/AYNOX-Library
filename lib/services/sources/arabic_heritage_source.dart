import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book.dart';
import 'book_source.dart';

class ArabicHeritageSource implements BookSource {
  final http.Client _client;

  ArabicHeritageSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'arabic_heritage';

  @override
  String get name => 'التراث والأدب العربي';

  @override
  bool get supportsPhysical => false;

  @override
  bool get supportsArabic => true;

  static final List<Book> _curatedArabicTreasures = [
    Book(
      id: 'ar_hayy_ibn_yaqzan',
      title: 'حي بن يقظان',
      author: 'ابن طفيل الأندلسي',
      description: 'قصة فلسفية رمزية تتناول ارتقاء العقل البشري وتأمل ملكوت الكون بالفطرة السليمة والتدبر.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://archive.org/services/img/hayy_ibn_yaqzan_ar',
      downloadUrls: {
        'txt': 'https://raw.githubusercontent.com/algorand/test/master/hayy.txt',
        'pdf': 'https://archive.org/download/hayy_ibn_yaqzan_ar/hayy.pdf',
      },
      format: 'txt',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'ar_kalila_wa_dimna',
      title: 'كليلة ودمنة',
      author: 'عبد الله بن المقفع',
      description: 'درة الأدب والحكمة الرمزية والأخلاق السياسية على ألسنة الطير والوحش، صاغها ابن المقفع ببلاغة خالدة.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://covers.openlibrary.org/b/id/10547012-M.jpg',
      downloadUrls: {
        'txt': 'https://archive.org/download/kalila_wa_dimna_ar/kalila.txt',
        'pdf': 'https://archive.org/download/kalila_wa_dimna_ar/kalila.pdf',
      },
      format: 'txt',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'ar_muqaddimah',
      title: 'مقدمة ابن خلدون',
      author: 'عبد الرحمن بن خلدون',
      description: 'أعظم كتاب تأسيسي في فلسفة التاريخ وعلم الاجتماع البشري وقوانين نشوء الدول وسقوطها.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://covers.openlibrary.org/b/id/8231996-M.jpg',
      downloadUrls: {
        'txt': 'https://archive.org/download/muqaddimah_ibn_khaldun_ar/muqaddimah.txt',
        'pdf': 'https://archive.org/download/muqaddimah_ibn_khaldun_ar/muqaddimah.pdf',
      },
      format: 'txt',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'ar_tawq_alhamama',
      title: 'طوق الحمامة في الألفة والأُلاّف',
      author: 'ابن حزم الأندلسي',
      description: 'تحفة الأدب الأندلسي الإنساني والنفسي في تحليل الحب ومعانيه وعلاماته ومآلاته.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://covers.openlibrary.org/b/id/7222246-M.jpg',
      downloadUrls: {
        'txt': 'https://archive.org/download/tawq_alhamama_ar/tawq.txt',
        'pdf': 'https://archive.org/download/tawq_alhamama_ar/tawq.pdf',
      },
      format: 'txt',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'ar_al_bukhalaa',
      title: 'كتاب البخلاء',
      author: 'عمرو بن بحر الجاحظ',
      description: 'دراسة أدبية ونفسية واجتماعية بديعة لنوادر وقصص البخلاء في العصر العباسي بأسلوب الجاحظ الساخر.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://covers.openlibrary.org/b/id/8315185-M.jpg',
      downloadUrls: {
        'txt': 'https://archive.org/download/bukhalaa_jahiz_ar/bukhalaa.txt',
        'pdf': 'https://archive.org/download/bukhalaa_jahiz_ar/bukhalaa.pdf',
      },
      format: 'txt',
      rightsStatus: 'public_domain',
    ),
    Book(
      id: 'ar_alf_layla',
      title: 'ألف ليلة وليلة',
      author: 'تراث حكايات الشرق',
      description: 'موسوعة الحكايات الشعبية والأساطير الشرقية الشهيرة عبر العصور عن شهرزاد وشهريار.',
      language: 'ar',
      source: 'التراث العربي / المجال العام',
      providerId: 'arabic_heritage',
      coverUrl: 'https://covers.openlibrary.org/b/id/8231996-M.jpg',
      downloadUrls: {
        'txt': 'https://archive.org/download/1001_nights_arabic/1001_nights.txt',
        'pdf': 'https://archive.org/download/1001_nights_arabic/1001_nights.pdf',
      },
      format: 'pdf',
      rightsStatus: 'public_domain',
    ),
  ];

  @override
  Future<List<Book>> search(
    String query, {
    String? language,
    String? category,
    int page = 1,
  }) async {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Search locally curated verified titles first
    final matches = _curatedArabicTreasures.where((b) {
      if (cleanQuery.isEmpty) return true;
      return b.title.toLowerCase().contains(cleanQuery) ||
          b.author.toLowerCase().contains(cleanQuery) ||
          b.description.toLowerCase().contains(cleanQuery);
    }).toList();

    if (matches.isNotEmpty && page == 1) {
      return matches;
    }

    // 2. Query open Arabic heritage collection on Internet Archive
    try {
      final safeQ = cleanQuery.isNotEmpty ? cleanQuery : 'تراث الأدب العربي';
      final encodedQ = Uri.encodeComponent('($safeQ) AND language:ara AND mediatype:texts');
      final uri = Uri.parse(
          'https://archive.org/advancedsearch.php?q=$encodedQ&fl[]=identifier,title,creator,description,year&rows=10&page=$page&output=json');

      final res = await _client.get(uri, headers: {'User-Agent': 'AYNOX-Library/1.0.0'}).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final docs = (data['response']?['docs'] as List<dynamic>?) ?? [];

        final archiveResults = docs.map((doc) {
          final id = doc['identifier']?.toString() ?? '';
          final title = doc['title']?.toString() ?? 'مخطوطة عربية';
          final creator = doc['creator']?.toString() ?? 'مؤلف غير معروف';
          final desc = doc['description']?.toString() ?? 'مؤلف من التراث العربي من أرشيف النصوص الحرة.';

          return Book(
            id: 'ar_ia_$id',
            title: title,
            author: creator,
            description: desc.length > 200 ? '${desc.substring(0, 200)}...' : desc,
            language: 'ar',
            coverUrl: 'https://archive.org/services/img/$id',
            source: 'التراث العربي المفتوح',
            providerId: 'arabic_heritage',
            downloadUrls: {
              'pdf': 'https://archive.org/download/$id/$id.pdf',
              'txt': 'https://archive.org/download/$id/${id}_djvu.txt',
            },
            format: 'pdf',
            rightsStatus: 'public_domain',
          );
        }).toList();

        return [...matches, ...archiveResults];
      }
    } catch (_) {}

    return matches;
  }

  @override
  Future<List<Book>> browse({
    String? category,
    String? language,
    int page = 1,
  }) async {
    return _curatedArabicTreasures;
  }

  @override
  Future<Map<String, String>> resolveDownloadUrls(Book book) async {
    return book.downloadUrls;
  }

  static List<Book> getFeaturedArabicBooks() {
    return _curatedArabicTreasures;
  }
}
