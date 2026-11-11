/*
 * LTvLauncher fork — built-in weather
 * Copyright (C) 2026 Parth Shah
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

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/weather_location_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Weather source picker + state hints, shown under the weather toggle in the
/// status bar settings. Kept in its own widget so the upstream page stays
/// close to the original and merges cleanly.
class WeatherSourceSettings extends StatelessWidget {
  const WeatherSourceSettings({Key? key}) : super(key: key);

  static const List<String> _sourceOrder = [WEATHER_SOURCE_DEVICE, WEATHER_SOURCE_MANUAL, WEATHER_SOURCE_BREEZY];

  String _sourceLabel(AppLocalizations l, String source) {
    switch (source) {
      case WEATHER_SOURCE_MANUAL:
        return l.weatherSourceManual;
      case WEATHER_SOURCE_BREEZY:
        return l.weatherSourceBreezy;
      default:
        return l.weatherSourceDevice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer2<SettingsService, WeatherService>(
      builder: (context, settings, weather, _) {
        final source = settings.weatherSource;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FocusableSettingsTile(
              leading: const Icon(Icons.place_outlined),
              title: Text("${l.weatherSource}: ${_sourceLabel(l, source)}"),
              onPressed: () {
                final i = _sourceOrder.indexOf(source);
                settings.setWeatherSource(_sourceOrder[(i + 1) % _sourceOrder.length]);
              },
            ),
            if (source == WEATHER_SOURCE_DEVICE) ..._deviceTiles(context, l, weather),
            if (source == WEATHER_SOURCE_MANUAL) ..._manualTiles(context, l, settings),
            if (source == WEATHER_SOURCE_BREEZY && !weather.hasWeather) _hint(context, l.breezyWeatherSetupHint),
            if (source != WEATHER_SOURCE_BREEZY) _statusLine(context, l, weather),
            if (source != WEATHER_SOURCE_BREEZY)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                child: Text(l.weatherAttribution,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _deviceTiles(BuildContext context, AppLocalizations l, WeatherService weather) {
    final granted = weather.locationPermissionGranted;
    if (granted == true) {
      final name = weather.resolvedLocation?.name;
      return [
        FocusableSettingsTile(
          leading: const Icon(Icons.my_location_outlined),
          title: Text(name != null ? "${l.weatherCurrentLocation}: $name" : l.weatherCurrentLocation),
          onPressed: () => weather.refresh(force: true),
        ),
      ];
    }
    return [
      _hint(context, l.weatherLocationPermissionHint),
      FocusableSettingsTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(l.weatherAllowLocation),
        onPressed: () => weather.requestLocationPermission(),
      ),
      if (granted == false)
        FocusableSettingsTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l.weatherOpenAppSettings),
          onPressed: () => _openOwnAppInfo(context),
        ),
    ];
  }

  List<Widget> _manualTiles(BuildContext context, AppLocalizations l, SettingsService settings) {
    final manual = settings.weatherManualLocation;
    return [
      FocusableSettingsTile(
        leading: const Icon(Icons.edit_location_alt_outlined),
        title: Text("${l.weatherSetLocation}: ${manual?.name ?? l.weatherLocationNotSet}"),
        onPressed: () => Navigator.of(context).pushNamed(WeatherLocationPage.routeName),
      ),
    ];
  }

  Widget _statusLine(BuildContext context, AppLocalizations l, WeatherService weather) {
    String? text;
    switch (weather.status) {
      case WeatherStatus.ok:
        final at = weather.lastUpdated;
        text = at != null ? "${l.weatherLastUpdated}: ${DateFormat.jm().format(at)}" : null;
        break;
      case WeatherStatus.networkError:
        text = l.weatherUnavailable;
        break;
      case WeatherStatus.locationUnavailable:
        text = l.weatherLocationUnavailable;
        break;
      case WeatherStatus.permissionDenied:
        text = weather.locationPermissionGranted == false ? l.weatherLocationPermissionDenied : null;
        break;
      case WeatherStatus.locationNotSet:
        text = l.weatherLocationNotSet;
        break;
      case WeatherStatus.disabled:
      case WeatherStatus.idle:
        text = null;
    }
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
    );
  }

  Widget _hint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );

  Future<void> _openOwnAppInfo(BuildContext context) => context.read<WeatherService>().openOwnAppInfo();
}
