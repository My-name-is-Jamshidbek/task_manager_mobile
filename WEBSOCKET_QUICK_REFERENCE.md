# WebSocket Quick Reference

## Files Created/Modified

| File | Status | Purpose |
|------|--------|---------|
| `pubspec.yaml` | ✏️ Modified | Added `web_socket_channel: ^2.4.6` |
| `lib/core/constants/api_constants.dart` | ✏️ Modified | Added WebSocket configuration |
| `lib/core/services/websocket_service.dart` | ✨ NEW | Low-level WebSocket management |
| `lib/core/managers/websocket_manager.dart` | ✨ NEW | State management provider |
| `lib/data/models/realtime/websocket_event_models.dart` | ✨ NEW | Event models (Message, Typing, Read) |
| `lib/presentation/widgets/websocket_error_dialog.dart` | ✨ NEW | Error dialogs and snackbars |
| `lib/presentation/mixins/websocket_chat_mixin.dart` | ✨ NEW | Reusable integration mixin |
| `WEBSOCKET_INTEGRATION_GUIDE.md` | ✨ NEW | Full integration documentation |
| `WEBSOCKET_IMPLEMENTATION_SUMMARY.md` | ✨ NEW | Implementation overview |
| `websocket_listener.py` | ✨ NEW | Python test script |

## Quick Start

### 1. Setup (3 steps)

```dart
// Step 1: Add to main.dart providers
ChangeNotifierProvider(
  create: (_) => WebSocketManager(),
),

// Step 2: Use mixin in chat screen
class _ChatScreenState extends State 
    with WebSocketChatMixin<ChatScreen> {

// Step 3: Initialize in initState
initializeWebSocket(
  userToken: token,
  userId: userId,
  channelName: 'private-user.$userId',
  onMessageReceived: onMsg,
  onUserTyping: onTyping,
  onMessagesRead: onRead,
);
```

### 2. Handle Events

```dart
onMessageReceived: (MessageSentEvent event) {
  print('Message: ${event.message.content}');
  // Update your message list
},

onUserTyping: (UserIsTypingEvent event) {
  print('${event.user.firstName} is typing');
  // Show typing indicator
},

onMessagesRead: (MessagesReadEvent event) {
  print('Messages read: ${event.messageIds}');
  // Update message status
},
```

### 3. Clean Up

```dart
@override
void dispose() {
  disposeWebSocket();
  super.dispose();
}
```

## Event Types

### 1. Message Received
```dart
MessageSentEvent {
  final Message message;
  final String? tempId;
}
```

### 2. User Typing
```dart
UserIsTypingEvent {
  final int conversationId;
  final User user;
}
```

### 3. Messages Read
```dart
MessagesReadEvent {
  final int conversationId;
  final int readerId;
  final List<String> messageIds;
}
```

## Error Handling

### Automatic Dialog
```dart
// Shows automatically when connection errors occur
showWebSocketErrorDialog(
  context,
  title: 'Connection Error',
  message: error,
  errorType: 'connection',
  onRetry: () { /* reconnect */ },
);
```

### Manual Snackbar
```dart
showWebSocketErrorSnackbar(
  context,
  message: 'Failed to send message',
  onRetry: () { /* retry */ },
);
```

## Configuration

All settings in `lib/core/constants/api_constants.dart`:

```dart
static const String reverbAppKey = '1puo7oyhapqfczgdmt1d';
static const String reverbHost = 'tms.amusoft.uz';
static const int reverbPort = 443;
static const String reverbScheme = 'https';
static const String broadcastingAuth = '/broadcasting/auth';
```

## Testing

### Python Script
```bash
python websocket_listener.py
# Shows real-time events from server
```

### Manual Testing
1. Run app with WebSocket enabled
2. Send messages from another device
3. Check logs for event receipt
4. Verify UI updates

## Logging

All operations logged with tags:

```dart
// In debug console:
[adb logcat | grep "WebSocketService"]
[adb logcat | grep "WebSocketManager"]

// Shows:
[TaskManager] [INFO] WebSocket connection initiated
[TaskManager] [INFO] Subscribed to channel: private-user.123
[TaskManager] [INFO] App event received: MessageSentEvent
```

## Common Tasks

### Send Typing Indicator
```dart
sendTypingIndicator(
  channel: 'private-user.$userId',
);
```

### Send Message via WebSocket
```dart
sendMessageViaWebSocket(
  channel: 'private-user.$userId',
  messageContent: 'Hello!',
  messageId: message.id,
);
```

### Check Connection Status
```dart
final manager = context.read<WebSocketManager>();
print(manager.isConnected);        // bool
print(manager.lastError);          // String?
print(manager.eventHistory);       // List<WebSocketEvent>
```

### Listen to Specific Events
```dart
final manager = context.read<WebSocketManager>();

// Listen to messages only
manager.onEventType<MessageSentEvent>((event) {
  print('Message: ${event.message.content}');
});

// Listen to typing only
manager.onEventType<UserIsTypingEvent>((event) {
  print('User typing: ${event.user.firstName}');
});
```

## Channel Authorization

Override in your chat screen:

```dart
@override
Future<String> _authorizeChannel(String channel, String token) async {
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
  
  final data = jsonDecode(response.body);
  return data['auth'];
}
```

## Architecture Overview

```
Chat Screen
    ↓
WebSocketChatMixin (handles lifecycle & events)
    ↓
WebSocketManager (state, Provider)
    ↓
WebSocketService (connection, protocol)
    ↓
WebSocket Server (Pusher Reverb)
```

## Best Practices

✅ **DO**
- Call `disposeWebSocket()` in screen dispose
- Implement temp ID tracking for messages
- Use snackbars for non-critical errors
- Enable logging in development

❌ **DON'T**
- Leave WebSocket subscriptions active after screen closes
- Send duplicate messages (use temp IDs)
- Ignore error callbacks
- Disable logging in production (just reduce level)

## Troubleshooting Checklist

- [ ] WebSocket URL is correct (wss://)
- [ ] App key matches backend configuration
- [ ] Bearer token is valid and not expired
- [ ] Channel authorization returns proper auth token
- [ ] No firewall/proxy blocking WebSocket
- [ ] SSL certificates valid (or REVERB_INSECURE_SSL=1)
- [ ] Logger enabled to see connection details
- [ ] All streams properly disposed

## Performance Tips

1. **Reuse connection**: Don't reconnect per screen
2. **Debounce events**: Throttle typing indicators
3. **Limit history**: Event history limited to 100
4. **Clean disposal**: Always dispose streams
5. **Batch updates**: Update UI in single setState

## Support

For issues:
1. Check `WEBSOCKET_INTEGRATION_GUIDE.md`
2. Review event payloads in the Python script
3. Enable logging: `Logger.enable()`
4. Check Flutter/Dart console for errors
5. Verify backend WebSocket server is running

## Example Integration

```dart
// Complete working example
class _ChatScreenState extends State<ChatScreen> 
    with WebSocketChatMixin<ChatScreen> {
  
  late ConversationDetailsProvider _convProvider;
  
  @override
  void initState() {
    super.initState();
    _convProvider = context.read<ConversationDetailsProvider>();
    _setupWebSocket();
  }
  
  Future<void> _setupWebSocket() async {
    final auth = context.read<AuthProvider>();
    
    initializeWebSocket(
      userToken: auth.token ?? '',
      userId: int.parse(auth.currentUser!.id),
      channelName: 'private-user.${auth.currentUser!.id}',
      onMessageReceived: (event) {
        // Update conversation
        _convProvider.addMessage(event.message);
      },
      onUserTyping: (event) {
        // Show indicator
        setState(() => _typingUserId = event.user.id);
      },
      onMessagesRead: (event) {
        // Mark as read
        _convProvider.markMessagesAsRead(event.messageIds);
      },
    );
  }
  
  @override
  void dispose() {
    disposeWebSocket();
    super.dispose();
  }
  
  @override
  Future<String> _authorizeChannel(String ch, String token) async {
    final resp = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.broadcastingAuth}'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({'channel_name': ch}),
    );
    return jsonDecode(resp.body)['auth'];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: _buildMessages(),
    );
  }
}
```

---

For detailed integration steps, see `WEBSOCKET_INTEGRATION_GUIDE.md`
