import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/services/notification_service.dart';

class FirebaseNotificationDebugScreen extends StatefulWidget {
  const FirebaseNotificationDebugScreen({Key? key}) : super(key: key);

  @override
  _FirebaseNotificationDebugScreenState createState() => _FirebaseNotificationDebugScreenState();
}

class _FirebaseNotificationDebugScreenState extends State<FirebaseNotificationDebugScreen> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _token = token;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _token = 'Error fetching token: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Push Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              SelectableText(
                _token ?? 'No token available',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _token == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: _token!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied to clipboard')),
                          );
                        },
                  child: const Text('Copy Token'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                      // Show a test in-app notification
                      NotificationService.showInAppNotification(
                        title: 'Test Notification',
                        body: 'This is a local test push',
                      );
                  },
                  child: const Text('Show Local Notification'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
