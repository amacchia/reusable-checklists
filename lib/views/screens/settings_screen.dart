import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../viewmodels/checklist_list_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.theme,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Consumer<ThemeViewModel>(
                  builder: (context, vm, _) {
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(AppStrings.themeSystem),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(AppStrings.themeLight),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(AppStrings.themeDark),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {vm.themeMode},
                      onSelectionChanged: (selected) {
                        unawaited(vm.setThemeMode(selected.first));
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AppStrings.data,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text(AppStrings.exportJson),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text(AppStrings.importJson),
            onTap: () => _import(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text(AppStrings.sourceCode),
            onTap: () async {
              final uri = Uri.parse(AppStrings.sourceCodeUrl);
              final messenger = ScaffoldMessenger.of(context);
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not open $uri')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final vm = context.read<ChecklistListViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    if (vm.checklists.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.nothingToExport)),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: vm.exportAsJson()));
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.exportCopied)),
    );
  }

  Future<void> _import(BuildContext context) async {
    final vm = context.read<ChecklistListViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim();
    if (text == null || text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.clipboardEmpty)),
      );
      return;
    }
    try {
      final count = await vm.importFromJson(text);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.importSucceeded.replaceFirst('{count}', '$count'),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.importFailed.replaceFirst('{reason}', e.toString()),
          ),
        ),
      );
    }
  }
}
