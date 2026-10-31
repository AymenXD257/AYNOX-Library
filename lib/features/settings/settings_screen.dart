import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/library_provider.dart';
import '../../services/sources/book_source.dart';
import '../../core/localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final discovery = Provider.of<DiscoveryProvider>(context);
    final library = Provider.of<LibraryProvider>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Language
          _buildSectionTitle(context, l10n.translate('language_selection')),
          Card(
            child: Column(
              children: [
                _buildRadioTile(
                  context: context,
                  title: 'English',
                  subtitle: 'English interface (LTR)',
                  value: 'en',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale('en'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildRadioTile(
                  context: context,
                  title: 'العربية',
                  subtitle: 'واجهة باللغة العربية مع دعم كامل لاتجاه اليمين إلى اليسار (RTL)',
                  value: 'ar',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale('ar'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildRadioTile(
                  context: context,
                  title: 'Français',
                  subtitle: 'Interface en Français (LTR)',
                  value: 'fr',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale('fr'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Theme Mode
          _buildSectionTitle(context, l10n.translate('theme_mode')),
          Card(
            child: Column(
              children: [
                _buildThemeRadioTile(
                  context: context,
                  title: l10n.translate('dark_mode'),
                  icon: Icons.dark_mode_outlined,
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(ThemeMode.dark),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildThemeRadioTile(
                  context: context,
                  title: l10n.translate('light_mode'),
                  icon: Icons.light_mode_outlined,
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildThemeRadioTile(
                  context: context,
                  title: l10n.translate('system_mode'),
                  icon: Icons.brightness_auto_outlined,
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Reader Defaults
          _buildSectionTitle(context, l10n.translate('reader_settings')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page turn style
                  Text(l10n.translate('page_turn_mode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChipOption(context, 'curl', l10n.translate('mode_curl'), settings.pageTurnMode, (v) => settings.setPageTurnMode('curl')),
                      const SizedBox(width: 8),
                      _buildChipOption(context, 'slide', l10n.translate('mode_slide'), settings.pageTurnMode, (v) => settings.setPageTurnMode('slide')),
                      const SizedBox(width: 8),
                      _buildChipOption(context, 'scroll', l10n.translate('mode_scroll'), settings.pageTurnMode, (v) => settings.setPageTurnMode('scroll')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.translate('font_size')),
                      Text('${settings.fontSize.toInt()} sp', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.fontSize,
                    min: 12.0,
                    max: 30.0,
                    divisions: 9,
                    activeColor: primary,
                    onChanged: (val) => settings.setFontSize(val),
                  ),
                  const SizedBox(height: 10),

                  // Line Spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.translate('line_spacing')),
                      Text('${settings.lineSpacing.toStringAsFixed(1)}x', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.lineSpacing,
                    min: 1.2,
                    max: 2.2,
                    divisions: 5,
                    activeColor: primary,
                    onChanged: (val) => settings.setLineSpacing(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Downloads & Format Preferences
          _buildSectionTitle(context, l10n.translate('downloads')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.translate('preferred_format'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChipOption(context, 'epub', 'EPUB', settings.preferredFormat, (v) => settings.setPreferredFormat('epub')),
                      const SizedBox(width: 8),
                      _buildChipOption(context, 'pdf', 'PDF', settings.preferredFormat, (v) => settings.setPreferredFormat('pdf')),
                      const SizedBox(width: 8),
                      _buildChipOption(context, 'txt', 'TXT', settings.preferredFormat, (v) => settings.setPreferredFormat('txt')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.storage, color: primary),
                    title: Text(l10n.translate('storage_info')),
                    subtitle: Text('Books: ${settings.storageFormatted} • Temp Cache: ${settings.cacheFormatted}'),
                    trailing: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.cleaning_services, size: 18),
                      label: Text(l10n.translate('clear_cache')),
                      onPressed: () async {
                        await settings.clearTemporaryCache();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.translate('cache_cleared'))),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Animations & Reduced Motion
          _buildSectionTitle(context, 'Animations & Motion'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.animation, color: primary),
                  title: Text(l10n.translate('enable_animations')),
                  value: settings.animationsEnabled,
                  onChanged: (val) => settings.setAnimationsEnabled(val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: Icon(Icons.motion_photos_off, color: primary),
                  title: Text(l10n.translate('reduced_motion')),
                  value: settings.reducedMotion,
                  onChanged: (val) => settings.setReducedMotion(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Provider Diagnostics
          _buildSectionTitle(context, l10n.translate('diagnostics')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${discovery.activeLibrariesCount} Registered Libraries',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.network_check, size: 16),
                        label: Text(l10n.translate('test_all_sources')),
                        onPressed: () async {
                          await discovery.testAllSources();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  ...discovery.sourceDiagnostics.values.map((diag) {
                    final isOnline = diag.health == SourceHealth.online;
                    final isSlow = diag.health == SourceHealth.slow;
                    final color = isOnline ? const Color(0xFF10B981) : (isSlow ? const Color(0xFFF59E0B) : Colors.redAccent);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(diag.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          Text('${diag.responseTimeMs} ms', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOnline ? l10n.translate('status_online') : (isSlow ? 'Slow' : l10n.translate('status_error')),
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Library Backup & Export
          _buildSectionTitle(context, 'Backup & Storage'),
          Card(
            child: ListTile(
              leading: Icon(Icons.backup, color: primary),
              title: Text(l10n.translate('export_backup')),
              subtitle: const Text('Save your bookshelf metadata, collections, and bookmarks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final jsonStr = library.exportLibraryJson();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup ready (${jsonStr.length} bytes).')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section: About AYNOX
          _buildSectionTitle(context, l10n.translate('about_aynox')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.auto_stories, color: primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AYNOX Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Version 1.0.0 — Ultimate Production Edition', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('about_desc'),
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.75), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Text(
                    'Architected and engineered by Aymen (AYNOX) — Computer Science @ USTO, Algeria.\nLicensed under MIT / Open Source.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChipOption(BuildContext context, String key, String label, String currentVal, ValueChanged<String> onSelect) {
    final isSelected = key == currentVal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(key),
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
      value: value,
      groupValue: groupValue,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildThemeRadioTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return RadioListTile<ThemeMode>(
      secondary: Icon(icon, color: primary, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      groupValue: groupValue,
      activeColor: primary,
      onChanged: onChanged,
    );
  }
}
