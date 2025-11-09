import 'package:flutter/material.dart';
import 'package:notiveapp/pages/category_management_page.dart';

class SettingsTab extends StatelessWidget {
  // Theme functions
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final void Function(int) onChangeSeed;

  // Backup functions
  final VoidCallback doExport;
  final VoidCallback doImport;

  const SettingsTab({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onChangeSeed,
    required this.doExport,
    required this.doImport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final _colorSeeds = [
      Colors.deepPurple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.cyan,
      Colors.amber,
      Colors.red,
      Colors.blueGrey,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            value: isDarkMode,
            onChanged: (_) => onToggleTheme(),
            title: const Text('Dark mode'),
            subtitle: const Text('Toggle light / dark theme'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Quick color seeds'),
            subtitle: const Text('Pick a theme accent color'),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'System',
                  onPressed: () => onChangeSeed(Colors.deepPurple.value),
                  icon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 12,
                    child: Icon(
                      Icons.phone_android,
                      size: 20,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Teal',
                  onPressed: () => onChangeSeed(Colors.teal.value),
                  icon: CircleAvatar(backgroundColor: Colors.teal, radius: 12),
                ),
                IconButton(
                  tooltip: 'Indigo',
                  onPressed: () => onChangeSeed(Colors.indigo.value),
                  icon: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    radius: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Customize Categories'),
            subtitle: const Text('Add, edit, or remove task categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryManagementPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Backup (Export)'),
            subtitle: const Text('Save tasks to JSON'),
            trailing: FilledButton.tonal(
              onPressed: doExport,
              child: const Text('Export'),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import (Restore)'),
            subtitle: const Text('Pick a backup JSON file'),
            trailing: FilledButton.tonal(
              onPressed: doImport,
              child: const Text('Import'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text('Notive • Raahim Alavi • ${DateTime.now().year}'),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
