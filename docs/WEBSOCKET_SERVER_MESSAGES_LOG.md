# 📡 WebSocket Server Messages - Complete Logging Guide

All incoming messages from the WebSocket server are now logged with detailed information.

---

## 🎯 Enhanced Logging Format

### Message Log Structure
```
[SOURCE] [EMOJI] [TAG] Message content
```

Where:
- **[SOURCE]**: `[SERVER]` = from WebSocket server, `[CLIENT]` = from app
- **[EMOJI]**: Visual indicator of message type
- **[TAG]**: `[WebSocket]`, `[WebSocketManager]`, or `[WebSocketChatMixin]`
- **Message**: Detailed content

---

## 📨 ALL Server Messages Logged

### 1. Raw Message Received
```
📨 [SERVER] Raw message: {"event":"pusher:connection_established","data":"{\"socket_id\":\"xxxxx\",\"activity_timeout\":120}"}
```
- **Logged**: Every message from server
- **Contains**: Full JSON of message
- **Use**: Debug raw server responses

### 2. Event Parsing
```
📡 [SERVER] Event: "pusher:connection_established" | Channel: "N/A" | Data type: String
```
- **Logged**: After decoding each message
- **Shows**: Event name, channel name, data type
- **Use**: Understand message structure

### 3. Connection Established
```
🔗 [SERVER] Connection established message received
✅ [SERVER] Connection established. socket_id: abc123def456 | activity_timeout: 120
```
- **Logged**: When WebSocket connects
- **Contains**: Socket ID and timeout settings
- **Use**: Verify connection setup

### 4. Subscription Request (Client Side)
```
🔑 [CLIENT] Requesting auth for channel: "private-chat.1.2"
✅ [CLIENT] Auth token obtained, length: 256
📤 [CLIENT] Sending subscription payload for channel: "private-chat.1.2"
Payload: {"event":"pusher:subscribe","data":{"channel":"private-chat.1.2","auth":"eyJhbGc..."}}
📻 [CLIENT] Subscribe message sent to channel: "private-chat.1.2"
```
- **Logged**: When subscribing to channel
- **Shows**: Auth request, token obtained, payload sent
- **Use**: Debug subscription issues

### 5. Subscription Succeeded (Server Response)
```
📻 [SERVER] Subscription succeeded for channel: "private-chat.1.2"
Full message: {"event":"pusher:subscription_succeeded","channel":"private-chat.1.2","data":"{}"}
```
- **Logged**: When server confirms subscription
- **Contains**: Channel name and server response
- **Use**: Confirm successful channel join

### 6. App Event Received
```
🎯 [SERVER] App event detected. Event: "message_sent", Channel: "private-chat.1.2"
💾 [SERVER] Raw app event data: {"type":"message_sent","message_id":"uuid","text":"Hello","sender_id":1,"timestamp":"2025-10-26T10:30:00"}
✅ [SERVER] Event parsed successfully: MessageSentEvent
Event details: {"type":"message_sent","message_id":"uuid",...}
```
- **Logged**: Every app-specific event from server
- **Shows**: Event type, raw data, parsed event
- **Use**: Track incoming real-time events

### 7. Ping/Pong (Keep-Alive)
```
[WebSocket] Pong sent
```
- **Logged**: Every ~30 seconds (keep-alive)
- **Shows**: Connection is healthy
- **Use**: Confirm connection is active

### 8. Connection Closed
```
🔌 [SERVER] WebSocket connection closed
```
- **Logged**: When server disconnects
- **Use**: Debug disconnection issues

### 9. Error Messages
```
❌ [SERVER] WebSocket error: SocketException: Connection reset by peer
Error type: SocketException
❌ [CLIENT] Failed to subscribe to channel "private-chat.1.2": 401 Unauthorized
Stack: ...
```
- **Logged**: All errors from server or client
- **Shows**: Error type and stack trace
- **Use**: Troubleshoot problems

---

## 🔄 Complete Flow Example

### Successful Chat Connection
```
[App starts]
🔌 AppRoot: Initializing WebSocket connection

[Connection phase]
📨 [SERVER] Raw message: {"event":"pusher:connection_established",...}
🔗 [SERVER] Connection established message received
✅ [SERVER] Connection established. socket_id: abc123 | activity_timeout: 120

[Subscription phase]
🔑 [CLIENT] Requesting auth for channel: "private-chat.1.2"
✅ [CLIENT] Auth token obtained, length: 256
📤 [CLIENT] Sending subscription payload for channel: "private-chat.1.2"
📻 [CLIENT] Subscribe message sent to channel: "private-chat.1.2"

[Server response]
📨 [SERVER] Raw message: {"event":"pusher:subscription_succeeded",...}
📻 [SERVER] Subscription succeeded for channel: "private-chat.1.2"

[Ready for chat]
✅ AppRoot: WebSocket connection established

[User sends message]
[WebSocket] Message sent: {"event":"client-event","channel":"private-chat.1.2","data":{"type":"message_sent",...}}

[Server sends message back - REAL-TIME]
📨 [SERVER] Raw message: {"event":"message_sent","channel":"private-chat.1.2",...}
🎯 [SERVER] App event detected. Event: "message_sent", Channel: "private-chat.1.2"
💾 [SERVER] Raw app event data: {"type":"message_sent","message_id":"...","text":"Hello",...}
✅ [SERVER] Event parsed successfully: MessageSentEvent
```

---

## 📊 Message Types to Watch For

### System Messages (Pusher Protocol)
| Message | Log | Meaning |
|---------|-----|---------|
| pusher:connection_established | 🔗✅ | Connected to WebSocket server |
| pusher:ping | ⏱️ | Keep-alive ping from server |
| pusher:pong | ⏱️ | Keep-alive pong response |
| pusher_internal:subscription_succeeded | 📻 | Subscribed to channel |
| pusher:subscribe | 📤 | Subscription request from client |

### App Messages (Custom Events)
| Message | Log | What It Is |
|---------|-----|-----------|
| message_sent | 🎯💾✅ | New message in chat |
| user_is_typing | 🎯💾✅ | Someone typing indicator |
| messages_read | 🎯💾✅ | Messages marked as read |

---

## 🔍 Filtering Logs

### View Only Server Messages
```bash
flutter logs | grep "\[SERVER\]"
```

### View Only Client Messages
```bash
flutter logs | grep "\[CLIENT\]"
```

### View Only Raw Server Data
```bash
flutter logs | grep "📨 \[SERVER\] Raw message"
```

### View Only App Events
```bash
flutter logs | grep "🎯 \[SERVER\] App event"
```

### View Only Errors
```bash
flutter logs | grep "❌"
```

### View Complete Flow
```bash
flutter logs | grep -E "(🔌|📨|🔗|✅|📻|🎯|💾|❌|\[CLIENT\]|\[SERVER\])"
```

---

## ⚠️ Common Issues & Their Logs

### Issue: No Connection
**Missing logs:**
```
🔗 [SERVER] Connection established message received
```
**Expected logs instead:**
```
❌ [SERVER] WebSocket error: Connection timeout
```

**Fix:** Check network, WebSocket URL, API key

---

### Issue: Subscription Not Succeeding
**Missing logs:**
```
📻 [SERVER] Subscription succeeded for channel: "private-chat.X.Y"
```
**Logs instead:**
```
❌ [CLIENT] Failed to subscribe to channel "private-chat.X.Y": 401 Unauthorized
```

**Fix:** Check auth token, channel permissions

---

### Issue: Not Receiving Chat Messages
**Missing logs:**
```
💾 [SERVER] Raw app event data: {"type":"message_sent",...}
✅ [SERVER] Event parsed successfully: MessageSentEvent
```

**Check:**
1. Is channel subscribed? (look for 📻 Subscription succeeded)
2. Are messages being sent? (check database)
3. Are events reaching server? (check backend logs)

---

### Issue: Connection Drops
**Logs to check:**
```
🔌 [SERVER] WebSocket connection closed
[WebSocketManager] Attempting to reconnect... (attempt 1/5)
```

**If reconnect succeeds:**
```
🔗 [SERVER] Connection established message received
✅ [SERVER] Connection established. socket_id: new_socket_id
```

---

## 📊 Log Levels

| Level | Icons | Examples |
|-------|-------|----------|
| INFO | ✅ 📨 🔗 📻 🔑 📤 | Connection, subscription, auth |
| DEBUG | 💾 Full messages | Raw data, event details |
| WARNING | ⚠️ | Already connected, missing data |
| ERROR | ❌ | Failed operations, connection errors |

---

## 🚀 Running with Full Logs

### Terminal 1: Run Flutter
```bash
flutter run
```

### Terminal 2: Monitor ALL Server Messages
```bash
flutter logs | grep -E "(📨|🎯|💾|✅|❌|\[SERVER\])"
```

### Terminal 3: Count Message Types
```bash
flutter logs | grep "📨 \[SERVER\]" | wc -l
```

---

## 📋 Debugging Checklist

When chat is not working:

1. **Check Connection**
   ```bash
   flutter logs | grep "🔗 \[SERVER\] Connection established"
   ```

2. **Check Subscription**
   ```bash
   flutter logs | grep "📻 \[SERVER\] Subscription succeeded"
   ```

3. **Check Incoming Events**
   ```bash
   flutter logs | grep "💾 \[SERVER\] Raw app event data"
   ```

4. **Check Errors**
   ```bash
   flutter logs | grep "❌"
   ```

5. **Check Message Parse**
   ```bash
   flutter logs | grep "Event parsed successfully"
   ```

---

## 💡 Tips

- **Every message is logged** - even if it fails to parse
- **Raw JSON is always shown** - for debugging server issues
- **Stack traces included** - for error debugging
- **Timestamps from logger** - use to correlate with server logs
- **Emoji makes it easy** - to scan logs visually

---

## Generated

Date: 26 October 2025  
Status: ✅ All server messages now logged with enhanced details  
Enhancement: Detailed logging on all WebSocket messages from server

---

### Quick Start Monitoring

```bash
# Terminal: Watch for real-time messages from server
flutter logs | grep -E "(🎯|💾|✅|❌)" 

# Look for: 💾 Raw app event data - this is the chat message
# If you see 💾 but not ✅, parsing is failing
# If you see neither, message is not reaching app
```

**Start the app, login, send a message, and check the logs!** 📊
