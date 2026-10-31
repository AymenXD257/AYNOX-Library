import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/book.dart';
import '../details/book_details_screen.dart';
import '../reader/reader_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final libraryProv = Provider.of<LibraryProvider>(context);
    final discoveryProv = Provider.of<DiscoveryProvider>(context);
    final recentlyRead = libraryProv.recentlyReadBooks;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.auto_stories, size: 20, color: primary),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.discover,
            onPressed: () => onNavigateTab(1),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async {
          await libraryProv.init();
          await discoveryProv.loadInitialCatalog();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Hero Card
              _buildHeroBanner(context, l10n),
              const SizedBox(height: 24),

              // Recently Read / Continue Reading Section
              if (recentlyRead.isNotEmpty) ...[
                _buildSectionHeader(
                  context: context,
                  title: l10n.recentlyRead,
                  actionText: l10n.translate('view_all'),
                  onAction: () => onNavigateTab(2),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentlyRead.length,
                    itemBuilder: (context, i) {
                      final b = recentlyRead[i];
                      return _buildRecentBookCard(context, b);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Popular Categories
              _buildSectionHeader(context: context, title: l10n.popularCategories),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryBadge(context, 'Arabic Heritage', Icons.menu_book, () {
                      discoveryProv.setLanguage('Arabic');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, 'Philosophy', Icons.psychology, () {
                      discoveryProv.setCategory('Philosophy');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, 'Science', Icons.science, () {
                      discoveryProv.setCategory('Science');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, 'Fiction', Icons.auto_stories, () {
                      discoveryProv.setCategory('Fiction');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, 'History', Icons.history_edu, () {
                      discoveryProv.setCategory('History');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, 'Academic', Icons.school, () {
                      discoveryProv.setCategory('Academic');
                      onNavigateTab(1);
                    }),
                    _buildCategoryBadge(context, l10n.physicalBooks, Icons.book, () {
                      discoveryProv.setFormat('Physical');
                      onNavigateTab(1);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Featured World Classics (Project Gutenberg & Standard Ebooks)
              _buildSectionHeader(
                context: context,
                title: l10n.featuredClassics,
                actionText: l10n.translate('discover_more'),
                onAction: () => onNavigateTab(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 235,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: discoveryProv.featuredBooks.length,
                  itemBuilder: (context, i) {
                    final b = discoveryProv.featuredBooks[i];
                    return _buildDiscoveryBookCard(context, b);
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Arabic Heritage & Classics (Verified Legitimate Sources)
              _buildSectionHeader(
                context: context,
                title: l10n.translate('source_arabic_heritage'),
                actionText: l10n.translate('view_all'),
                onAction: () {
                  discoveryProv.setLanguage('Arabic');
                  onNavigateTab(1);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 235,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: discoveryProv.arabicClassics.length,
                  itemBuilder: (context, i) {
                    final b = discoveryProv.arabicClassics[i];
                    return _buildDiscoveryBookCard(context, b);
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Physical Books Discovery Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      primary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Color(0xFFF59E0B), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.physicalBooks,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover printed editions, track ISBNs, manage your home bookshelf and purchase wishlists.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LEGITIMATE OPEN LIBRARIES',
                  style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              const Icon(Icons.offline_pin, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              const Text('Offline Ready', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Explore Public-Domain Classics & Printed Books Without Limits',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover Project Gutenberg, Open Library, Internet Archive, Standard Ebooks, and Arabic Heritage with paper-like realistic reading.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.explore, size: 16),
                label: Text(l10n.discover, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => onNavigateTab(1),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(l10n.myLibrary),
                onPressed: () => onNavigateTab(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText,
                style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookCard(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.menu_book, color: primary),
                          )
                        : Icon(Icons.menu_book, color: primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: book.readingProgress,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  color: primary,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryBookCard(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.auto_stories, color: primary, size: 28)),
                        )
                      : Center(child: Icon(Icons.auto_stories, color: primary, size: 28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
