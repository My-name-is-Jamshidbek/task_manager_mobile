import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/managers/websocket_manager.dart';
import '../../../core/services/websocket_auth_service.dart';
import '../../providers/auth_provider.dart';

class WebSocketDebugScreen extends StatefulWidget {
  const WebSocketDebugScreen({super.key});

  @override
  State<WebSocketDebugScreen> createState() => _WebSocketDebugScreenState();
}

class _WebSocketDebugScreenState extends State<WebSocketDebugScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();

  final List<String> _logs = [];
  StreamSubscription? _eventSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  bool _authInProgress = false;
  bool _wsInProgress = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider?>();
    if (authProvider != null && authProvider.currentUser?.id != null) {
      _channelController.text = 'private-user.${authProvider.currentUser!.id}';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachStreams();
      final auth = context.read<AuthProvider?>();
      if (auth != null && auth.currentUser != null) {
        _appendLog('Auth session detected for ${auth.currentUser!.name ?? auth.currentUser!.phone ?? '-'}');
      } else {
        _appendLog('No active auth session found');
      }
    });
  }

  void _attachStreams() {
    final webSocketManager = context.read<WebSocketManager>();
    _eventSubscription = webSocketManager.eventStream.listen((event) {
      _appendLog('Event: ${event.runtimeType} -> $event');
    });
    _errorSubscription = webSocketManager.errorStream.listen((error) {
      _appendLog('Error: $error');
    });
    _connectionSubscription = webSocketManager.connectionStateStream.listen((isConnected) {
      _appendLog('Connection state changed: ${isConnected ? 'connected' : 'disconnected'}');
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _channelController.dispose();
    _eventController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  void _appendLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 200) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _login() async {
    final authProvider = context.read<AuthProvider>();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      _appendLog('Login aborted: phone or password empty');
      return;
    }
    setState(() => _authInProgress = true);
    final success = await authProvider.login(phone, password);
    setState(() => _authInProgress = false);
    if (success && authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      _appendLog('Login successful for ${authProvider.currentUser!.name ?? authProvider.currentUser!.phone ?? '-'}');
      if (userId != null) {
        _channelController.text = 'private-user.$userId';
      }
      await authProvider.loadUserProfile();
    } else {
      _appendLog('Login failed: ${authProvider.error ?? 'unknown error'}');
    }
  }

  Future<void> _relogin() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    _appendLog('Existing session cleared, ready for login');
    await _login();
  }

  Future<void> _connectWebSocket() async {
    final authProvider = context.read<AuthProvider>();
    final webSocketManager = context.read<WebSocketManager>();
    final token = authProvider.authToken;
    final userId = authProvider.currentUser?.id;
    if (token == null || userId == null) {
      _appendLog('Connect aborted: missing auth token or user id');
      return;
    }
    setState(() => _wsInProgress = true);
    final connected = await webSocketManager.connect(
      token: token,
      userId: userId,
    );
    setState(() => _wsInProgress = false);
    if (connected) {
      _appendLog('WebSocket connected');
    } else {
      _appendLog('WebSocket connect failed: ${webSocketManager.lastError ?? 'unknown'}');
    }
  }

  Future<void> _disconnectWebSocket() async {
    final webSocketManager = context.read<WebSocketManager>();
    await webSocketManager.disconnect();
    _appendLog('WebSocket disconnect invoked');
  }

  Future<void> _subscribeChannel() async {
    final channel = _channelController.text.trim();
    if (channel.isEmpty) {
      _appendLog('Subscribe aborted: channel empty');
      return;
    }
    final webSocketManager = context.read<WebSocketManager>();
    final socketId = webSocketManager.socketId;
    if (socketId == null || socketId.isEmpty) {
      _appendLog('Subscribe aborted: socketId missing (connect first)');
      return;
    }
    final success = await webSocketManager.subscribeToChannel(
      channelName: channel,
      onAuthRequired: (name) async {
        final currentSocketId = webSocketManager.socketId;
        if (currentSocketId == null || currentSocketId.isEmpty) {
          throw Exception('Socket ID unavailable for authorization');
        }
        return WebSocketAuthService.authorize(
          channelName: name,
          socketId: currentSocketId,
        );
      },
    );
    if (success) {
      _appendLog('Subscribed to $channel');
    } else {
      _appendLog('Subscription failed: ${webSocketManager.lastError ?? 'unknown'}');
    }
  }

  Future<void> _sendMessage() async {
    final channel = _channelController.text.trim();
    final eventName = _eventController.text.trim();
    final payloadRaw = _payloadController.text.trim();
    if (channel.isEmpty || eventName.isEmpty || payloadRaw.isEmpty) {
      _appendLog('Send aborted: channel, event, or payload empty');
      return;
    }
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(payloadRaw);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      } else {
        _appendLog('Send aborted: payload must be JSON object');
        return;
      }
    } catch (e) {
      _appendLog('Send aborted: payload parse error $e');
      return;
    }
    final webSocketManager = context.read<WebSocketManager>();
    webSocketManager.sendMessage(
      channel: channel,
      event: eventName,
      data: payload,
    );
    _appendLog('Message sent: event=$eventName channel=$channel payload=$payload');
  }

  void _copyLogs() {
    Clipboard.setData(ClipboardData(text: _logs.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final webSocketManager = context.watch<WebSocketManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Debug Console'),
        actions: [
          IconButton(
            onPressed: _copyLogs,
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy logs',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAuthCard(authProvider),
                    const SizedBox(height: 16),
                    _buildWebSocketCard(webSocketManager),
                    const SizedBox(height: 16),
                    _buildPayloadCard(),
                    const SizedBox(height: 16),
                    _buildEventCard(webSocketManager),
                    const SizedBox(height: 16),
                    _buildLogCard(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthCard(AuthProvider authProvider) {
  final isLoggedIn = authProvider.isLoggedIn && authProvider.currentUser != null;
  final status = isLoggedIn
    ? 'Logged in as ${authProvider.currentUser!.name ?? authProvider.currentUser!.phone ?? '-'}'
    : 'Not authenticated';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authentication', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(status),
            if (authProvider.error != null) ...[
              const SizedBox(height: 8),
              Text('Error: ${authProvider.error}', style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _authInProgress ? null : _login,
                  icon: _authInProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Login'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _authInProgress ? null : _relogin,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-login'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: authProvider.isLoggedIn ? authProvider.logout : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSocketCard(WebSocketManager webSocketManager) {
    final isConnected = webSocketManager.isConnected;
    final status = isConnected ? 'Connected (socketId: ${webSocketManager.socketId ?? '-'})' : 'Disconnected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WebSocket', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(status),
            if (webSocketManager.lastError != null) ...[
              const SizedBox(height: 8),
              Text('Last error: ${webSocketManager.lastError}', style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _wsInProgress ? null : _connectWebSocket,
                  icon: _wsInProgress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.power_settings_new),
                  label: const Text('Connect'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isConnected ? _disconnectWebSocket : null,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(labelText: 'Channel (e.g. private-user.1)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isConnected ? _subscribeChannel : null,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Subscribe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Message', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(labelText: 'Event name (e.g. message:send)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _payloadController,
              decoration: const InputDecoration(labelText: 'Payload (JSON object)'),
              maxLines: 6,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(WebSocketManager webSocketManager) {
    final events = webSocketManager.eventHistory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Events (${events.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: events.isEmpty
                  ? const Center(child: Text('No events yet'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          dense: true,
                          title: Text(event.runtimeType.toString()),
                          subtitle: Text(event.toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Console (${_logs.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _logs.isEmpty
                  ? const Center(child: Text('No logs yet'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return ListTile(
                          dense: true,
                          title: Text(log),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => _logs.clear());
                },
                child: const Text('Clear logs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
