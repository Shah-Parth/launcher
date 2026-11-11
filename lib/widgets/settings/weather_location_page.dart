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
import 'package:flauncher/models/weather_location.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Manual weather location: type a city or postal code, pick a result.
/// Used as a fallback when location permission is not wanted.
class WeatherLocationPage extends StatefulWidget {
  static const String routeName = "weather_location_panel";

  const WeatherLocationPage({Key? key}) : super(key: key);

  @override
  State<WeatherLocationPage> createState() => _WeatherLocationPageState();
}

class _WeatherLocationPageState extends State<WeatherLocationPage> {
  final TextEditingController _controller = TextEditingController();
  List<WeatherLocation> _results = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2 || _searching) return;
    setState(() => _searching = true);
    final results = await context.read<WeatherService>().searchLocations(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _select(WeatherLocation location) async {
    await context.read<SettingsService>().setWeatherManualLocation(location);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = context.watch<SettingsService>().weatherManualLocation;
    return Column(
      children: [
        Text(l.weatherSetLocation, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        if (current != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("${l.weatherCurrentLocation}: ${current.name ?? ""}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: l.weatherSearchHint,
              border: const OutlineInputBorder(),
              suffixIcon: _searching
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(icon: const Icon(Icons.search), onPressed: _search),
            ),
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text(_searched ? l.weatherNoResults : "",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return FocusableSettingsTile(
                      // Jump the remote's focus straight to the first hit after a search.
                      autofocus: i == 0,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(r.name ?? "${r.latitude.toStringAsFixed(2)}, ${r.longitude.toStringAsFixed(2)}"),
                      onPressed: () => _select(r),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
