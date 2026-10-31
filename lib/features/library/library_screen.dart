import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../core/localization/app_localizations.dart';
import 'widgets/local_book_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = [
    'all',
    'downloaded',
    'imported',
    'favorites',
    'reading',
    'owned',
    'wishlist',
    'collections',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index < _tabs.length) {
        Provider.of<LibraryProvider>(context, listen: false)
            .setSelectedTab(_tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final libraryProv = Provider.of<LibraryProvider>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myLibrary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.allBooks),
            Tab(text: l10n.downloaded),
            Tab(text: l10n.imported),
            Tab(text: l10n.favorites),
            Tab(text: l10n.translate('recently_read')),
            Tab(text: l10n.translate('owned_physically')),
            Tab(text: l10n.translate('wishlist')),
            Tab(text: l10n.collections),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.importBook, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final newBook = await libraryProv.importBookFromFilePicker();
          if (context.mounted) {
            if (newBook != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translate('success_imported'))),
              );
            }
          }
        },
      ),
      body: Column(
        children: [
          // Search in library
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchBooks,
                prefixIcon: Icon(Icons.search, size: 20, color: primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          libraryProv.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                libraryProv.setSearchQuery(val);
              },
            ),
          ),

          // Content Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildBookList(libraryProv.books, l10n, libraryProv),
                _buildCollectionsTab(libraryProv, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List books, AppLocalizations l10n, LibraryProvider prov) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (prov.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 54, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 14),
              Text(
                l10n.translate('empty_library'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('empty_library_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final b = books[index];
        return LocalBookTile(
          book: b,
          onFavoriteToggle: () => prov.toggleFavorite(b.id),
          onDelete: () => prov.removeBook(b.id),
        );
      },
    );
  }

  Widget _buildCollectionsTab(LibraryProvider prov, AppLocalizations l10n) {
    final collections = prov.collections;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(l10n.translate('new_collection'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showCreateCollectionDialog(context, prov, l10n),
            ),
          ),
        ),
        Expanded(
          child: collections.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('no_results'),
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.folder, color: primary),
                        title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${col.bookIds.length} ${l10n.allBooks.toLowerCase()}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          onPressed: () => prov.deleteCollection(col.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreateCollectionDialog(BuildContext context, LibraryProvider prov, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final primary = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('create_collection')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.translate('collection_name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await prov.createCollection(nameController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(l10n.translate('create')),
          ),
        ],
      ),
    );
  }
}
