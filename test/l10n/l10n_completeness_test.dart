import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all localization arb files contain all keys from app_en.arb without extra keys', () async {
    final enFile = File('lib/l10n/app_en.arb');
    expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');

    final enJson = jsonDecode(await enFile.readAsString()) as Map<String, dynamic>;
    final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

    final l10nDir = Directory('lib/l10n');
    final arbFiles = l10nDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'))
        .toList();

    expect(arbFiles, isNotEmpty, reason: 'Target arb files must exist');

    final errors = <String>[];

    for (final file in arbFiles) {
      final fileName = file.uri.pathSegments.last;
      final fileJson = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final fileKeys = fileJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingKeys = enKeys.difference(fileKeys);
      if (missingKeys.isNotEmpty) {
        errors.add('$fileName is missing keys: ${missingKeys.join(', ')}');
      }

      final extraKeys = fileKeys.difference(enKeys);
      if (extraKeys.isNotEmpty) {
        errors.add('$fileName has extra keys: ${extraKeys.join(', ')}');
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}
