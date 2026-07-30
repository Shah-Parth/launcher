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
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_service.dart';

class AccentColorPage extends StatelessWidget {
  static const String routeName = "accent_color_panel";

  // Define accent color presets with names
  static const List<(String hex, String name)> colorPresets = [
    (ACCENT_COLOR_PURPLE, 'Purple'),
    (ACCENT_COLOR_TEAL, 'Teal'),
    (ACCENT_COLOR_BLUE, 'Blue'),
    (ACCENT_COLOR_ORANGE, 'Orange'),
    (ACCENT_COLOR_PINK, 'Pink'),
    (ACCENT_COLOR_GREEN, 'Green'),
    (ACCENT_COLOR_WHITE, 'White'),
    (ACCENT_COLOR_YELLOW, 'Yellow'),
    (ACCENT_COLOR_RED, 'Red'),
    (ACCENT_COLOR_CYAN, 'Cyan'),
    (ACCENT_COLOR_INDIGO, 'Indigo'),
    (ACCENT_COLOR_LIME, 'Lime'),
    (ACCENT_COLOR_AMBER, 'Amber'),
    (ACCENT_COLOR_ROSE, 'Rose'),
    (ACCENT_COLOR_ICE_BLUE, 'Ice Blue'),
  ];

  const AccentColorPage({super.key});

  Color _hexToColor(String hex) {
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settingsService, _) {
        final currentColorHex = settingsService.accentColorHex;
        final currentColor = _hexToColor(currentColorHex);
        final activePreset = colorPresets.firstWhere(
          (p) => p.$1 == currentColorHex,
          orElse: () => (currentColorHex, 'Custom'),
        );

        return Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: currentColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: currentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.accentColor,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Personalize interface highlights & focus effects',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Subtle Gradient Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    currentColor.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Color Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemCount: colorPresets.length,
                itemBuilder: (context, index) {
                  final (hex, name) = colorPresets[index];
                  final isSelected = currentColorHex == hex;

                  return _ColorTile(
                    color: _hexToColor(hex),
                    name: name,
                    isSelected: isSelected,
                    autofocus: index == 0,
                    onTap: () => settingsService.setAccentColor(hex),
                  );
                },
              ),
            ),

            // Live UI Preview Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentColor.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withOpacity(0.12),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini Status Bar & Card Row Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.widgets_outlined, size: 14, color: currentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Live Preview',
                              style: TextStyle(
                                color: currentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: currentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: currentColor.withOpacity(0.5), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: currentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activePreset.$2,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Mini Apps Focus Preview Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniCard(Colors.grey.shade800, false, currentColor),
                        _buildMiniCard(currentColor, true, currentColor),
                        _buildMiniCard(Colors.grey.shade800, false, currentColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniCard(Color baseColor, bool isFocused, Color accentColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 54,
      height: 34,
      decoration: BoxDecoration(
        color: isFocused ? accentColor.withOpacity(0.25) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused ? accentColor : Colors.white12,
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: Icon(
          isFocused ? Icons.play_arrow_rounded : Icons.apps_rounded,
          size: 16,
          color: isFocused ? accentColor : Colors.white54,
        ),
      ),
    );
  }
}

class _ColorTile extends StatefulWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;

  const _ColorTile({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<_ColorTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDarkSwatch = widget.color.computeLuminance() < 0.4;
    final checkColor = isDarkSwatch ? Colors.white : Colors.black87;

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap()),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onTap()),
      },
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _focused ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _focused
                    ? Colors.white.withOpacity(0.12)
                    : (widget.isSelected
                        ? widget.color.withOpacity(0.18)
                        : Colors.white.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focused
                      ? widget.color
                      : (widget.isSelected ? widget.color.withOpacity(0.7) : Colors.white.withOpacity(0.1)),
                  width: _focused ? 2.5 : (widget.isSelected ? 2 : 1),
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.65),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : widget.isSelected
                        ? [
                            BoxShadow(
                              color: widget.color.withOpacity(0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Color Orb Swatch
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.color,
                          widget.color.withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: checkColor,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  // Color Name Label
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          color: _focused || widget.isSelected ? Colors.white : Colors.white70,
                          fontWeight: _focused || widget.isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
