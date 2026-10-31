import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/library_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/download_provider.dart';

import 'features/home/home_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/library/library_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AynoxLibraryApp());
}

class AynoxLibraryApp extends StatelessWidget {
  const AynoxLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'AYNOX Library',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const MainNavigationShell(),
          );
        },
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final downloadProv = Provider.of<DownloadProvider>(context);
    final activeDownloads = downloadProv.activeDownloads.length;

    final settings = Provider.of<SettingsProvider>(context);
    final animationsEnabled = settings.animationsEnabled && !settings.reducedMotion;

    final screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const DiscoverScreen(),
      const LibraryScreen(),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: animationsEnabled
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: screens[_currentIndex],
              ),
            )
          : IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: l10n.discover,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: l10n.myLibrary,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: activeDownloads > 0,
              label: Text('$activeDownloads'),
              child: const Icon(Icons.download_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: activeDownloads > 0,
              label: Text('$activeDownloads'),
              child: const Icon(Icons.download),
            ),
            label: l10n.downloads,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
