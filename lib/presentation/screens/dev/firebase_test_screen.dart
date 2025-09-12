import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/firebase_provider.dart';
import '../../providers/auth_provider.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final _apiUrlController = TextEditingController(
    text: 'https://your-api-domain.com/api',
  );
  final _authTokenController = TextEditingController();
  final _topicController = TextEditingController(text: 'general');

  @override
  void dispose() {
    _apiUrlController.dispose();
    _authTokenController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<FirebaseProvider, AuthProvider>(
        builder: (context, firebaseProvider, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Firebase Status Card
                _buildStatusCard(firebaseProvider),
                const SizedBox(height: 16),

                // FCM Token Card
                _buildTokenCard(firebaseProvider),
                const SizedBox(height: 16),

                // API Configuration Card
                _buildApiConfigCard(),
                const SizedBox(height: 16),

                // Backend Integration Card
                _buildBackendCard(firebaseProvider, authProvider),
                const SizedBox(height: 16),

                // Topic Management Card
                _buildTopicCard(firebaseProvider),
                const SizedBox(height: 16),

                // Actions Card
                _buildActionsCard(firebaseProvider),
                const SizedBox(height: 16),

                // Error Display
                if (firebaseProvider.error != null)
                  _buildErrorCard(firebaseProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(FirebaseProvider firebaseProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  firebaseProvider.isInitialized
                      ? Icons.check_circle
                      : Icons.error,
                  color: firebaseProvider.isInitialized
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Firebase Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              firebaseProvider.isInitialized
                  ? '✅ Firebase initialized successfully'
                  : '❌ Firebase not initialized',
              style: TextStyle(
                color: firebaseProvider.isInitialized
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  firebaseProvider.isRegisteredWithBackend
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: firebaseProvider.isRegisteredWithBackend
                      ? Colors.green
                      : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  firebaseProvider.isRegisteredWithBackend
                      ? 'Registered with backend'
                      : 'Not registered with backend',
                  style: TextStyle(
                    color: firebaseProvider.isRegisteredWithBackend
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(FirebaseProvider firebaseProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key),
                const SizedBox(width: 8),
                Text(
                  'FCM Token',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (firebaseProvider.fcmToken != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: firebaseProvider.fcmToken!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Token copied to clipboard'),
                        ),
                      );
                    },
                    tooltip: 'Copy token',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                firebaseProvider.fcmToken ?? 'No token available',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: firebaseProvider.isInitialized
                  ? () => firebaseProvider.refreshToken()
                  : null,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Token'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_applications),
                const SizedBox(width: 8),
                Text(
                  'API Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                helperText: 'Update this to your backend API URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authTokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token (optional)',
                helperText: 'Bearer token for authenticated requests',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendCard(
    FirebaseProvider firebaseProvider,
    AuthProvider authProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload),
                const SizedBox(width: 8),
                Text(
                  'Backend Integration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Register your FCM token with the backend to receive notifications.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        firebaseProvider.fcmToken != null &&
                            _apiUrlController.text.isNotEmpty
                        ? () => _registerToken(firebaseProvider)
                        : null,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Register Token'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        firebaseProvider.fcmToken != null &&
                            _apiUrlController.text.isNotEmpty
                        ? () => _deactivateToken(firebaseProvider)
                        : null,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Deactivate'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(FirebaseProvider firebaseProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.topic),
                const SizedBox(width: 8),
                Text(
                  'Topic Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        firebaseProvider.isInitialized &&
                            _topicController.text.isNotEmpty
                        ? () => firebaseProvider.subscribeToTopic(
                            _topicController.text,
                          )
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Subscribe'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        firebaseProvider.isInitialized &&
                            _topicController.text.isNotEmpty
                        ? () => firebaseProvider.unsubscribeFromTopic(
                            _topicController.text,
                          )
                        : null,
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Unsubscribe'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(FirebaseProvider firebaseProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build),
                const SizedBox(width: 8),
                Text(
                  'Test Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !firebaseProvider.isInitialized
                    ? () => firebaseProvider.initialize()
                    : null,
                icon: const Icon(Icons.rocket_launch, size: 16),
                label: Text(
                  firebaseProvider.isInitialized
                      ? 'Firebase Already Initialized'
                      : 'Initialize Firebase',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTestNotification(),
                icon: const Icon(Icons.notifications, size: 16),
                label: const Text('Show Test Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(FirebaseProvider firebaseProvider) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => firebaseProvider.clearError(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              firebaseProvider.error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _registerToken(FirebaseProvider firebaseProvider) {
    final authToken = _authTokenController.text.trim();
    if (authToken.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Auth token is required')));
      return;
    }
    firebaseProvider.registerToken(authToken: authToken);
  }

  void _deactivateToken(FirebaseProvider firebaseProvider) {
    final authToken = _authTokenController.text.trim();
    if (authToken.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Auth token is required')));
      return;
    }
    firebaseProvider.deactivateToken(authToken: authToken);
  }

  void _showTestNotification() {
    // This would show a local test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification shown'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
