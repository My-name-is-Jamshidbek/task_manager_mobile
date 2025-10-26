# 📋 WebSocket - All Log Messages Reference

Complete guide to all WebSocket logging throughout the app lifecycle.

---

## 🔄 App Startup Flow

### Phase 1: App Root Initialization
```
👤 AppRoot: Loading user profile data
✅ AppRoot: User profile data loaded
🔌 AppRoot: Initializing WebSocket connection
```

---

## 🌐 WebSocket Connection (Service Level)

### Connecting
```
[WebSocket] Connecting to WebSocket: wss://tms.amusoft.uz:443/app/1puo7oyhapqfczgdmt1d?protocol=7&client=js&version=8.2.0&flash=false
[WebSocket] WebSocket connection initiated
```

### Connection States
```
✅ AppRoot: WebSocket connection established    (Success)
⚠️ AppRoot: WebSocket connection failed          (Failed to connect)
⚠️ AppRoot: Cannot initialize WebSocket - missing token or userId
```

### Error Handling
```
⚠️ AppRoot: WebSocket initialization error: <error message>
[WebSocket] Failed to send data: <error>
[WebSocket] Error closing WebSocket: <error>
[WebSocket] Error handling WebSocket message: <error>
```

---

## 📦 Channel Operations (Manager Level)

### Subscribe to Channel
```
[WebSocketManager] WebSocket connection successful
[WebSocketManager] Subscribed to channel: <channel_name>
```

Examples:
```
[WebSocketManager] Subscribed to channel: private-chat.1.2  (private channel)
[WebSocketManager] Subscribed to channel: chat              (public channel)
```

### Already Subscribed
```
[WebSocketManager] Already subscribed to channel: <channel_name>
```

### Unsubscribe
```
[WebSocketManager] Unsubscribed from channel: <channel_name>
[WebSocketManager] Not subscribed to channel: <channel_name>  (wasn't subscribed)
```

### Subscription Errors
```
[WebSocketManager] Failed to subscribe: <error>
[WebSocketManager] Error unsubscribing: <error>
```

---

## 🔐 Authorization Flow (Chat Mixin Level)

### Starting Authorization
```
🔌 WebSocketChatMixin: Initializing WebSocket connection
```

### Socket ID Negotiation
```
📍 WebSocketChatMixin: Socket ID: <socket_id>
❌ WebSocketChatMixin: Socket ID not available
```

### Authorization Request
```
🔑 WebSocketChatMixin: Requesting channel authorization
```

### Authorization Response
```
📥 WebSocketChatMixin: Auth response received
✅ WebSocketChatMixin: Channel authorization successful
🔐 WebSocketChatMixin: Auth token: <token>
```

### Authorization Errors
```
❌ WebSocketChatMixin: No auth token in response
❌ WebSocketChatMixin: Authorization failed: <error>
❌ WebSocketChatMixin: Request failed: <error>
```

---

## 📨 Message Events

### Sent
```
[WebSocketManager] Message sent: <event_data>
[WebSocket] Message sent: <event>
```

### Received
```
[WebSocket] WebSocket message received: <decoded_message>
```

### Event Types Received
```
MessageSentEvent received
UserIsTypingEvent received
MessagesReadEvent received
PusherConnectionEstablishedEvent received
PusherSubscriptionSucceededEvent received
```

---

## 🔄 Connection State Changes

### Connected
```
[WebSocketManager] WebSocket connected
```

### Disconnected
```
[WebSocketManager] WebSocket disconnected
⚠️ WebSocket already connected or connecting
```

### Reconnection (Pusher Protocol)
```
[WebSocket] Pong sent
[WebSocket] Reconnecting WebSocket after error
```

---

## ⚠️ Error Messages

### Cannot Perform Operation
```
[WebSocket] Cannot unsubscribe: not connected
[WebSocket] Cannot send message: WebSocket not connected
[WebSocketManager] Already connecting
```

### Connection Errors
```
[WebSocketManager] WebSocket error: <error_details>
[WebSocket] WebSocket error in initial connection: <error>
```

### Disposal Errors
```
[WebSocketManager] Error disconnecting: <error>
[WebSocket] Error closing WebSocket: <error>
```

### Authorization Errors (Status Codes)
```
❌ WebSocketChatMixin: Authorization failed: 401 Unauthorized
❌ WebSocketChatMixin: Authorization failed: 403 Forbidden
❌ WebSocketChatMixin: Authorization failed: 500 Server Error
```

---

## 🧹 Cleanup

### Disposing Resources
```
[WebSocketChatMixin] Disposing WebSocket resources
[WebSocketManager] WebSocket disconnected
```

---

## 📊 Complete Startup Example

When a user logs in and navigates to chat, you should see:

```
👤 AppRoot: Loading user profile data
✅ AppRoot: User profile data loaded
🔌 AppRoot: Initializing WebSocket connection

[WebSocket] Connecting to WebSocket: wss://tms.amusoft.uz:443/app/...
[WebSocket] WebSocket connection initiated
✅ AppRoot: WebSocket connection established

[WebSocketManager] WebSocket connected
[WebSocketManager] Subscribed to channel: private-chat.1.2

🔌 WebSocketChatMixin: Initializing WebSocket connection
📍 WebSocketChatMixin: Socket ID: <socket_id>
🔑 WebSocketChatMixin: Requesting channel authorization
📥 WebSocketChatMixin: Auth response received
✅ WebSocketChatMixin: Channel authorization successful
```

---

## 🎯 Log Levels

### INFO (✅, 🔌, 📍, 🔑, 📥, ✅)
- Connection established
- Channel subscribed
- Socket ID obtained
- Authorization complete
- Normal operations

### WARNING (⚠️)
- Connection failed
- Already connecting
- Missing credentials
- Reconnection needed

### ERROR (❌, Error)
- Authorization failed
- Connection error
- Socket ID missing
- Auth token missing
- Server errors (401, 403, 500)

### DEBUG ([tag])
- Detailed message content
- Pong messages
- Message sent/received

---

## 🔍 Filtering Logs

### View Only WebSocket Logs
```bash
# In terminal during flutter run:
adb logcat | grep -i websocket
# or
flutter logs | grep -E "(WebSocket|WebSocketManager|WebSocketChatMixin|AppRoot.*WebSocket)"
```

### View Only Errors
```bash
flutter logs | grep "ERROR\|❌\|failed\|error"
```

### View Complete Flow
```bash
flutter logs | grep -E "(AppRoot|WebSocket|WebSocketManager|WebSocketChatMixin)"
```

---

## 📍 Log Sources

### AppRoot (`app_root.dart`)
- 🔌 AppRoot: Initializing WebSocket connection
- ✅ AppRoot: WebSocket connection established
- ⚠️ AppRoot: WebSocket connection failed
- ⚠️ AppRoot: Cannot initialize WebSocket - missing token or userId
- ⚠️ AppRoot: WebSocket initialization error

### WebSocket Service (`websocket_service.dart`)
- [WebSocket] Connecting to WebSocket: ...
- [WebSocket] WebSocket connection initiated
- [WebSocket] Subscribed to channel: ...
- [WebSocket] Message sent: ...
- [WebSocket] WebSocket message received: ...
- [WebSocket] Pong sent
- [WebSocket] Error messages

### WebSocket Manager (`websocket_manager.dart`)
- [WebSocketManager] WebSocket connected
- [WebSocketManager] WebSocket disconnected
- [WebSocketManager] Subscribed to channel: ...
- [WebSocketManager] Message sent: ...
- [WebSocketManager] Error messages

### Chat Mixin (`websocket_chat_mixin.dart`)
- 🔌 WebSocketChatMixin: Initializing WebSocket connection
- 📍 WebSocketChatMixin: Socket ID: ...
- 🔑 WebSocketChatMixin: Requesting channel authorization
- 📥 WebSocketChatMixin: Auth response received
- ✅ WebSocketChatMixin: Channel authorization successful
- 🔐 WebSocketChatMixin: Auth token: ...
- ❌ WebSocketChatMixin: Error messages

---

## ✅ Healthy State Indicators

A healthy WebSocket connection shows:

1. ✅ AppRoot: WebSocket connection established
2. [WebSocketManager] WebSocket connected
3. [WebSocketManager] Subscribed to channel: private-chat.X.Y
4. ✅ WebSocketChatMixin: Channel authorization successful

---

## ❌ Troubleshooting

### Missing "connection established" log?
→ Check if WebSocketManager is added to MultiProvider in main.dart

### Socket ID not available?
→ Connection not completed before authorization attempt

### Authorization failed (401)?
→ Invalid or expired token

### Authorization failed (403)?
→ User doesn't have permission to this channel

### No logs at all?
→ Logger might be disabled - check Logger.enable()

---

## 🚀 Live Monitoring

To monitor WebSocket in real-time while running:

```bash
# Terminal 1: Run the app
flutter run

# Terminal 2: Watch logs
flutter logs --verbose | grep -E "(WebSocket|Authorization|AppRoot)"
```

Or use VSCode's Debug Console for live output while app is running.

---

Generated: 26 October 2025
Status: ✅ All WebSocket logging points documented
