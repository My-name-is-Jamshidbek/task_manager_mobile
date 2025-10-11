import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Runs the tool/check_localizations.dart script and asserts no missing keys.
void main() {
  test('localization audit has no missing keys', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/check_localizations.dart',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    expect(
      result.exitCode,
      0,
      reason:
          'Localization audit failed (exit ${result.exitCode}). Run: dart run tool/check_localizations.dart',
    );
  });
}
