import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/discovery_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import 'widgets/book_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final discovery = Provider.of<DiscoveryProvider>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discover),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.hub, size: 14, color: primary),
                const SizedBox(width: 6),
                Text(
                  '${discovery.activeLibrariesCount} Legal Open Libraries Active',
                  style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Offline Notice
          if (discovery.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.offlineBanner,
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchBooks,
                prefixIcon: Icon(Icons.search, color: primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          discovery.search(query: '');
                        },
                      )
                    : null,
              ),
              onSubmitted: (val) {
                discovery.search(query: val);
              },
            ),
          ),

          // Format Filter Tabs (All, PDF, EPUB, TXT, Physical)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFormatChip(discovery, 'All', l10n.translate('all_formats')),
                const SizedBox(width: 8),
                _buildFormatChip(discovery, 'PDF', 'PDF'),
                const SizedBox(width: 8),
                _buildFormatChip(discovery, 'EPUB', 'EPUB'),
                const SizedBox(width: 8),
                _buildFormatChip(discovery, 'TXT', 'TXT'),
                const SizedBox(width: 8),
                _buildFormatChip(discovery, 'Physical', l10n.physicalBooks),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Language Filter Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildLangChip(discovery, 'All', l10n.translate('all_languages')),
                const SizedBox(width: 8),
                _buildLangChip(discovery, 'Arabic', l10n.translate('arabic_lang')),
                const SizedBox(width: 8),
                _buildLangChip(discovery, 'English', l10n.translate('english_lang')),
                const SizedBox(width: 8),
                _buildLangChip(discovery, 'French', l10n.translate('french_lang')),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Category Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: AppConstants.bookCategories.map((cat) {
                final isSelected = discovery.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => discovery.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Books Grid View + Load More
          Expanded(
            child: discovery.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('libraries_searched'),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  )
                : discovery.discoveredBooks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.translate('no_results'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                onPressed: () => discovery.loadInitialCatalog(),
                                child: Text(l10n.translate('retry')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: () => discovery.search(query: discovery.currentQuery),
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.64,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final book = discovery.discoveredBooks[index];
                                    return BookCard(book: book);
                                  },
                                  childCount: discovery.discoveredBooks.length,
                                ),
                              ),
                            ),
                            // Real Pagination: Load More Button / Progress
                            if (discovery.hasNextPage)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                  child: Center(
                                    child: discovery.isLoadingMore
                                        ? CircularProgressIndicator(color: primary)
                                        : ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                              foregroundColor: primary,
                                              side: BorderSide(color: primary.withValues(alpha: 0.3)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            icon: const Icon(Icons.expand_more),
                                            label: Text(l10n.loadMore, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            onPressed: () => discovery.loadMore(),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(DiscoveryProvider discovery, String formatKey, String label) {
    final isSelected = discovery.selectedFormat == formatKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => discovery.setFormat(formatKey),
    );
  }

  Widget _buildLangChip(DiscoveryProvider discovery, String langKey, String label) {
    final isSelected = discovery.selectedLanguage == langKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => discovery.setLanguage(langKey),
    );
  }
}
