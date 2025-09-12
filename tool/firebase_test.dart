#!/usr/bin/env dart

/// A simple command-line tool to send test push notifications via Firebase Cloud Messaging.
/// Usage:
///   dart run tool/firebase_test.dart <serverKey> <deviceToken> [<title>] [<body>]

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/firebase_test.dart <serverKey> <deviceToken> [<title>] [<body>]',
    );
    exit(1);
  }

  final serverKey = args[0];
  final deviceToken = args[1];
  final title = args.length > 2 ? args[2] : 'Test Notification';
  final body = args.length > 3 ? args[3] : 'This is a test message';

  final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
  final payload = {
    'to': deviceToken,
    'notification': {'title': title, 'body': body},
    'data': {
      'sentAt': DateTime.now().toIso8601String(),
      'customData': 'firebase_test_tool',
    },
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      stdout.writeln('✅ Notification sent successfully!');
      stdout.writeln('Response:');
      stdout.writeln(response.body);
    } else {
      stderr.writeln(
        '❌ Failed to send notification. HTTP ${response.statusCode}',
      );
      stderr.writeln('Response:');
      stderr.writeln(response.body);
      exit(1);
    }
  } catch (e) {
    stderr.writeln('Exception occurred while sending notification: $e');
    exit(1);
  }
}
