# WebSocket Chat Integration Guide

This document provides a complete guide for integrating WebSocket functionality into your Flutter chat application.

## Overview

The WebSocket integration uses **Pusher** protocol for real-time communication with the backend. The implementation includes:

- **WebSocketService**: Low-level WebSocket management
- **WebSocketManager**: High-level state management using Provider
- **WebSocketChatMixin**: Reusable mixin for chat screen integration
- **WebSocketErrorDialog**: Error handling and recovery UI

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Chat Screen                           │
│  (implements WebSocketChatMixin)                │
└────────────────────┬────────────────────────────┘
                     │ uses
                     ▼
┌─────────────────────────────────────────────────┐
│        WebSocketManager (Provider)              │
│  - Connection state management                  │
│  - Event streaming & filtering                  │
│  - Channel subscription tracking                │
└────────────────────┬────────────────────────────┘
                     │ uses
                     ▼
┌─────────────────────────────────────────────────┐
│         WebSocketService                        │
│  - Raw WebSocket connection                     │
│  - Pusher protocol handling                     │
│  - Automatic reconnection                       │
│  - Message routing                              │
└─────────────────────────────────────────────────┘
```

## Configuration

All WebSocket settings are configured in `lib/core/constants/api_constants.dart`:

```dart
// WebSocket Configuration
static const String reverbAppKey = '1puo7oyhapqfczgdmt1d';
static const String reverbHost = 'tms.amusoft.uz';
static const int reverbPort = 443;
static const String reverbScheme = 'https'; // https (wss) or http (ws)

// Broadcasting auth endpoint
static const String broadcastingAuth = '/broadcasting/auth';
```

## Event Types

### 1. MessageSentEvent

Triggered when a new message is sent in the conversation.

```dart
// Payload from server
{
  "type": "message",
  "data": {
    "message": { /* MessageResource */ },
    "tempId": "..."  // Client-side temp ID
  }
}

// Handle in chat screen
onMessageReceived: (MessageSentEvent event) {
  // Update your message list
  // Replace temp message with actual message if needed
  print('New message: ${event.message.content}');
}
```

### 2. UserIsTypingEvent

Triggered when a user starts typing.

```dart
// Payload from server
{
  "type": "typing",
  "data": {
    "conversation_id": 123,
    "user": { 
      "id": 45, 
      "name": "Ali",
      "email": "ali@example.com"
    }
  }
}

// Handle in chat screen
onUserTyping: (UserIsTypingEvent event) {
  // Show typing indicator for this user
  print('${event.user.firstName} is typing...');
}
```

### 3. MessagesReadEvent

Triggered when messages are marked as read.

```dart
// Payload from server
{
  "type": "read",
  "data": {
    "conversation_id": 123,
    "reader_id": 45,
    "message_ids": [101, 102]
  }
}

// Handle in chat screen
onMessagesRead: (MessagesReadEvent event) {
  // Update message read status
  print('Messages ${event.messageIds} were read by user ${event.readerId}');
}
```

## Integration Steps

### Step 1: Add Provider Setup

Add WebSocketManager to your app's provider setup:

```dart
// In your app setup (e.g., main.dart)
ChangeNotifierProvider(
  create: (_) => WebSocketManager(),
  lazy: false,  // Initialize immediately
),
```

### Step 2: Implement WebSocket in Chat Screen

```dart
import 'package:provider/provider.dart';
import 'package:task_manager/core/managers/websocket_manager.dart';
import 'package:task_manager/presentation/mixins/websocket_chat_mixin.dart';
import 'package:task_manager/data/models/realtime/websocket_event_models.dart';

class ChatConversationScreen extends StatefulWidget {
  final Chat chat;
  final int conversationId;

  const ChatConversationScreen({
    required this.chat,
    required this.conversationId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen>
    with WebSocketChatMixin<ChatConversationScreen> {
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
  }

  Future<void> _setupWebSocket() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      Logger.warning('No current user, skipping WebSocket setup');
      return;
    }

    final channelName = 'private-user.${currentUser.id}';
    
    initializeWebSocket(
      userToken: authProvider.token ?? '',
      userId: int.parse(currentUser.id),
      channelName: channelName,
      onMessageReceived: (MessageSentEvent event) {
        Logger.info('New message received: ${event.message.content}');
        // Update your UI here
        setState(() {
          // Add message to your list
        });
      },
      onUserTyping: (UserIsTypingEvent event) {
        Logger.info('User typing: ${event.user.firstName}');
        // Show typing indicator
        setState(() {
          // Update typing indicator UI
        });
      },
      onMessagesRead: (MessagesReadEvent event) {
        Logger.info('Messages read by user ${event.readerId}');
        // Update message read status
        setState(() {
          // Update message status in UI
        });
      },
    );
  }

  @override
  void dispose() {
    disposeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        chat: widget.chat,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          MessageInput(
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    // Send via REST API first
    // Then listen for WebSocket event confirmation
  }

  Widget _buildMessagesList() {
    return Consumer<ConversationDetailsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Your message list UI
        return ListView.builder(
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return MessageBubble(message: message);
          },
        );
      },
    );
  }
}
```

### Step 3: Implement Channel Authorization

The WebSocket mixin requires you to implement the `_authorizeChannel` method. Override it in your chat screen:

```dart
@override
Future<String> _authorizeChannel(String channel, String token) async {
  // Call your backend to authorize the channel
  final response = await http.post(
    Uri.parse('${ApiConstants.baseUrl}${ApiConstants.broadcastingAuth}'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'channel_name': channel,
      'socket_id': _webSocketManager._webSocketService.socketId,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['auth'];
  } else {
    throw Exception('Failed to authorize channel: ${response.body}');
  }
}
```

## Usage Examples

### Sending Messages via WebSocket

```dart
// Optional: Send message events through WebSocket for real-time sync
sendMessageViaWebSocket(
  channel: 'private-user.${currentUserId}',
  messageContent: 'Hello!',
  messageId: message.id,
);
```

### Sending Typing Indicator

```dart
// Notify other users that you're typing
sendTypingIndicator(
  channel: 'private-user.${currentUserId}',
);
```

### Listening to Specific Events

```dart
final webSocketManager = context.read<WebSocketManager>();

// Listen only to message events
webSocketManager.onEventType<MessageSentEvent>((event) {
  print('Message: ${event.message.content}');
});

// Listen only to typing events
webSocketManager.onEventType<UserIsTypingEvent>((event) {
  print('${event.user.firstName} is typing');
});
```

## Error Handling

The WebSocket implementation includes automatic error handling:

1. **Connection Errors**: Shows error dialog with retry option
2. **Subscription Errors**: Shows snackbar notification
3. **Event Processing Errors**: Logged and ignored (non-blocking)
4. **Automatic Reconnection**: Up to 5 attempts with 3-second delays

### Custom Error Handling

```dart
// Access error stream directly
final manager = context.read<WebSocketManager>();
manager.errorStream.listen((error) {
  Logger.error('WebSocket error: $error');
  // Handle error as needed
});
```

## Logging

All WebSocket operations are logged with the tag `WebSocketService` and `WebSocketManager`. Enable logging for debugging:

```dart
Logger.enable();  // Enable all logs

// Check logs with tag filter
// In Android: adb logcat | grep "WebSocketService"
// In iOS: Check Xcode console with filter "WebSocketService"
```

## Testing

### Manual Testing with Python Script

Use the provided Python example (`websocket_listener.py`) to test your WebSocket server:

```bash
cd your_project_root
python websocket_listener.py
```

This will:
1. Login as a test user
2. Connect to WebSocket
3. Subscribe to private user channel
4. Listen and print all events

### Unit Testing

```dart
test('WebSocket connects successfully', () async {
  final manager = WebSocketManager();
  
  final connected = await manager.connect(
    token: 'test_token',
    userId: 123,
  );
  
  expect(connected, true);
  expect(manager.isConnected, true);
  
  await manager.disconnect();
});

test('WebSocket handles message events', () async {
  final manager = WebSocketManager();
  // ... setup connection
  
  final events = <WebSocketEvent>[];
  manager.onEvent((event) {
    events.add(event);
  });
  
  // Simulate event from server
  // ...
  
  expect(events.isNotEmpty, true);
  expect(events.first, isA<MessageSentEvent>());
});
```

## Troubleshooting

### Connection Fails

1. Check internet connectivity
2. Verify WebSocket server is running
3. Check API constants (app key, host, port, scheme)
4. Enable logging to see detailed error messages

### Events Not Received

1. Verify channel subscription succeeded
2. Check channel name is correct
3. Verify channel authorization passed
4. Check firewall/proxy settings

### Duplicate Messages

1. Implement temporary message handling (temp ID tracking)
2. Match incoming message ID with sent message ID
3. Remove temp message when actual message arrives

### Memory Leaks

1. Always call `disposeWebSocket()` in screen's dispose
2. Cancel stream subscriptions properly
3. Use `WeakReference` if keeping long-term listeners

## Best Practices

1. **Connection Lifecycle**: Manage connection at app level, not per-screen
2. **Error Recovery**: Implement exponential backoff for reconnection
3. **Message Deduplication**: Track sent messages by ID to avoid duplicates
4. **Typing Indicators**: Debounce typing events (e.g., 1 per second)
5. **Logging**: Always enable logging in development for debugging
6. **Testing**: Use Python test script before deploying to production
7. **Security**: Always use WSS (WebSocket Secure) in production

## Files Modified/Created

- `pubspec.yaml`: Added `web_socket_channel` dependency
- `lib/core/constants/api_constants.dart`: Added WebSocket constants
- `lib/core/services/websocket_service.dart`: Low-level WebSocket service
- `lib/core/managers/websocket_manager.dart`: State management provider
- `lib/data/models/realtime/websocket_event_models.dart`: Event models
- `lib/presentation/widgets/websocket_error_dialog.dart`: Error dialogs
- `lib/presentation/mixins/websocket_chat_mixin.dart`: Reusable mixin

## Support

For issues or questions:
1. Check the logging output
2. Review the Python test script
3. Consult the Pusher protocol documentation
4. Check API backend logs
