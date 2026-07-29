/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'animated_character.dart';

class DateTimeWidget extends StatefulWidget {
  final Duration?   updateInterval;
  final String      _dateTimeFormatString;
  final TextStyle?  textStyle;
  final bool        animate;

  const DateTimeWidget(String dateTimeFormatString, {
    super.key,
    this.updateInterval,
    this.textStyle,
    this.animate = true,
  }) :
      _dateTimeFormatString = dateTimeFormatString;

  @override
  State<DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget> with WidgetsBindingObserver {
  late DateFormat _dateFormat;
  late DateTime   _now;
  String          _formattedText = '';
  Timer?          _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDateFormatAndRefresh();
    _startTimer();
  }

  void _initDateFormatAndRefresh() {
    _dateFormat = DateFormat(widget._dateTimeFormatString, Platform.localeName);
    _now = DateTime.now();
    _formattedText = _dateFormat.format(_now);
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = widget.updateInterval ?? _defaultInterval();
    _timer = Timer.periodic(interval, (_) => _refreshTime());
  }

  /// Returns 1-second interval by default so time updates immediately when NTP sync completes or minute rolls over.
  Duration _defaultInterval() {
    return const Duration(seconds: 1);
  }

  @override
  void didUpdateWidget(DateTimeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update format if it changed or updateInterval changed
    if (oldWidget._dateTimeFormatString != widget._dateTimeFormatString ||
        oldWidget.updateInterval != widget.updateInterval) {
      _initDateFormatAndRefresh();
      _startTimer();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTime(force: true);
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedText = _formattedText.isNotEmpty ? _formattedText : _dateFormat.format(_now);
    
    if (widget.animate) {
      return AnimatedTimeDisplay(
        displayText: formattedText,
        textStyle: widget.textStyle,
      );
    }
    
    return Text(formattedText, style: widget.textStyle);
  }

  void _refreshTime({bool force = false}) {
    final now = DateTime.now();
    final newFormattedText = _dateFormat.format(now);
    
    if (force || newFormattedText != _formattedText) {
      setState(() {
        _now = now;
        _formattedText = newFormattedText;
      });
    }
  }
}
