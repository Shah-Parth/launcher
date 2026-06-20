import 'package:collection/collection.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black54, // Dim background
      body: Stack(
        children: [
          // Tap outside to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
          SidePanelDialog(
            width: 400,
            isRightSide: false,
            child: Consumer2<NotificationsService, AppsService>(
              builder: (context, notificationsService, appsService, _) {
                final List<NotificationItem> notifications = notificationsService.notifications;
                final bool hasClearable = notifications.any((n) => n.isClearable);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notifications",
                            style: theme.textTheme.titleLarge,
                          ),
                          if (hasClearable)
                            TextButton.icon(
                              onPressed: () async {
                                await notificationsService.dismissAll();
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text("Clear All"),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 64,
                                    color: theme.hintColor.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "All caught up!",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                final app = appsService.applications.firstWhereOrNull(
                                  (a) => a.packageName == notification.packageName,
                                );
                                final appName = app?.name ?? notification.packageName;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                  child: Material(
                                    color: theme.cardColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    clipBehavior: Clip.antiAlias,
                                    child: FocusableSettingsTile(
                                      autofocus: index == 0,
                                      leading: FutureBuilder<dynamic>(
                                        future: appsService.getAppIcon(notification.packageName),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.memory(
                                                snapshot.data,
                                                width: 36,
                                                height: 36,
                                              ),
                                            );
                                          }
                                          return const Icon(Icons.android, size: 36);
                                        },
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appName,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (notification.title.isNotEmpty)
                                            Text(
                                              notification.title,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          if (notification.text.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2.0),
                                              child: Text(
                                                notification.text,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.hintColor,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: notification.isClearable
                                          ? _DismissButton(
                                              onPressed: () async {
                                                await notificationsService.dismiss(notification.key);
                                              },
                                            )
                                          : null,
                                      onPressed: () {
                                        if (app != null) {
                                          Navigator.of(context).pop();
                                          appsService.launchApp(app);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (notifications.isNotEmpty && hasClearable) ...[
                      const SizedBox(height: 8),
                      _FocusableClearAllButton(
                        onPressed: () async {
                          await notificationsService.dismissAll();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _DismissButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<_DismissButton> createState() => _DismissButtonState();
}

class _DismissButtonState extends State<_DismissButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onPressed,
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      borderRadius: BorderRadius.circular(8),
      focusColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          color: _focused ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
        ),
        child: const Icon(
          Icons.close,
          size: 18,
        ),
      ),
    );
  }
}

class _FocusableClearAllButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _FocusableClearAllButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  State<_FocusableClearAllButton> createState() => _FocusableClearAllButtonState();
}

class _FocusableClearAllButtonState extends State<_FocusableClearAllButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: widget.onPressed,
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        borderRadius: BorderRadius.circular(12),
        focusColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            color: _focused
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.cardColor.withOpacity(0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.clear_all,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Clear All",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
