import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'focusable_settings_tile.dart';

class AccessibilityPage extends StatefulWidget {
  static const String routeName = "accessibility";

  const AccessibilityPage({super.key});

  @override
  State<AccessibilityPage> createState() => _AccessibilityPageState();
}

class _AccessibilityPageState extends State<AccessibilityPage> {
  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final appsService = context.read<AppsService>();
    final launcherState = context.read<LauncherState>();
    await launcherState.refresh(appsService);
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    LauncherState launcherState = context.watch<LauncherState>();
    bool isDefault = launcherState.isDefaultLauncher;

    return Column(
      children: [
        Text(localizations.accessibility, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  leading: Icon(
                    isDefault ? Icons.check_circle : Icons.cancel,
                    color: isDefault ? Colors.green : Colors.redAccent,
                  ),
                  title: Text(
                    isDefault
                        ? localizations.defaultLauncherIsDefault
                        : localizations.defaultLauncherNotDefault,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: _refreshStatus,
                ),
                const SizedBox(height: 8),
                FocusableSettingsTile(
                  leading: const Icon(Icons.home),
                  title: Text(
                    localizations.setAsDefaultLauncher,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: () {
                    FLauncherChannel().openDefaultLauncherSettings();
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    localizations.defaultLauncherDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
