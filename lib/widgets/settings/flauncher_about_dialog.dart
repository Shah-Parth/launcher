/*
 * FLauncher
 * Copyright (C) 2024 LeanBitLab
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/providers/settings_service.dart';

class LTvLauncherAboutDialog extends StatelessWidget {
  final PackageInfo packageInfo;

  const LTvLauncherAboutDialog({
    Key? key,
    required this.packageInfo,
  }) : super(key: key);

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final accentColor = _hexToColor(settingsService.accentColorHex);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced App Icon with Glowing Container
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.6),
                    accentColor.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  "assets/icon.png",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Title & Version Badge
            const Text(
              "LTvLauncher",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
              ),
              child: Text(
                "v${packageInfo.version} (${packageInfo.buildNumber})",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Legalese
            const Text(
              "Developed by LeanBitLab",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Sponsor Button (Prominent & Focusable for TV)
            _AboutButton(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFFF4081),
              label: "Sponsor Project",
              accentColor: const Color(0xFFFF4081),
              autofocus: true,
              onPressed: () {
                FLauncherChannel().openUrl("https://github.com/sponsors/LeanBitLab");
              },
            ),
            const SizedBox(height: 10),

            // GitHub Repository Button
            _AboutButton(
              icon: Icons.code_rounded,
              iconColor: accentColor,
              label: "Source Code & Docs",
              accentColor: accentColor,
              onPressed: () {
                FLauncherChannel().openUrl("https://github.com/LeanBitLab/LtvLauncher");
              },
            ),
            const SizedBox(height: 14),

            // Close Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color accentColor;
  final VoidCallback onPressed;
  final bool autofocus;

  const _AboutButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.accentColor,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_AboutButton> createState() => _AboutButtonState();
}

class _AboutButtonState extends State<_AboutButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onPressed()),
      },
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _focused ? widget.accentColor.withOpacity(0.25) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused ? widget.accentColor : Colors.white.withOpacity(0.12),
                width: _focused ? 2 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.4),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18, color: widget.iconColor),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _focused ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: _focused ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
