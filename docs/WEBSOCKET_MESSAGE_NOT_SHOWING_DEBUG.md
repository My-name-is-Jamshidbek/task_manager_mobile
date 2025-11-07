# 🔍 WebSocket Message Debugging - Complete Trace

## Problem: Messages From Server Not Showing in Logs or Chat

If you see messages arriving at your WebSocket server but they're not showing:
1. In the Flutter terminal logs
2. In the chat UI

Follow this debugging guide.

---

## Step 1: Verify Connection is Working

Check for these logs in your terminal:

```
✅ [SERVER] Connection established. socket_id: abc123
📻 [SERVER] Subscription succeeded for channel: "private-chat.1.2"
```

If you DON'T see these, **the connection is not established yet**. See troubleshooting below.

---

## Step 2: Verify Messages Are Being Sent From Server

You need to check your backend that messages are actually being sent.

**Backend Check:**
```bash
# On your backend server, watch for outgoing WebSocket messages
# For Reverb, check logs for event broadcasts
tail -f storage/logs/laravel.log | grep -i "broadcast\|message"
```

**Expected backend log:**
```
[2025-10-26 10:30:45] Broadcasting.INFO: Broadcasting event: message_sent to channel: private-chat.1.2
```

If backend is NOT sending messages, the problem is in your backend, not Flutter.

---

## Step 3: Enable Full Trace Logging

Add this to your main.dart to see EVERY message:

```dart
void main() async {
  // ... existing code ...
  
  // Enable verbose logging
  Logger.enable();  // Make sure this is called
  
  // ... rest of code
}
```

---

## Step 4: Check Message Format

Messages from server must have this structure:

```json
{
  "event": "message_sent",
  "channel": "private-chat.1.2",
  "data": {
    "type": "message_sent",
    "message_id": "uuid",
    "text": "Hello",
    "sender_id": 1,
    "timestamp": "2025-10-26T10:30:00"
  }
}
```

**Key points:**
- `event` must be a string (not a Pusher protocol event)
- `channel` must match the subscribed channel exactly
- `data` must be JSON object (not string)

---

## Step 5: Monitor WITH THIS EXACT COMMAND

Run this in a NEW terminal while app is running:

```bash
flutter logs 2>&1 | grep -E "(📨|🎯|💾|✅|❌|\[SERVER\]|\[CLIENT\])"
```

This shows ONLY the relevant logs.

---

## Step 6: Send a Test Message

From your backend OR using curl:

```bash
# Using Laravel/Reverb
Broadcast::channel('private-chat.1.2')->dispatch(
    new MessageSentEvent([
        'type' => 'message_sent',
        'message_id' => 'test-123',
        'text' => 'Test message',
        'sender_id' => 1,
        'timestamp' => now()->toIso8601String(),
    ])
);
```

Or using curl (if your backend API accepts it):

```bash
curl -X POST http://your-backend.com/api/chat/send-message \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"conversation_id": 1, "text": "Test message"}'
```

---

## Step 7: Watch Terminal Output

Watch for these logs appearing in order:

### Expected Log Sequence:

```
📨 [SERVER] Raw message: {"event":"message_sent","channel":"private-chat.1.2","data":...}
📡 [SERVER] Event: "message_sent" | Channel: "private-chat.1.2" | Data type: Map
🎯 [SERVER] App event detected. Event: "message_sent", Channel: "private-chat.1.2"
💾 [SERVER] Raw app event data: {"type":"message_sent","message_id":"test-123",...}
✅ [SERVER] Event parsed successfully: MessageSentEvent
```

---

## 🔴 If You DON'T See These Logs

### Missing: `📨 Raw message`
**Means:** Server is not sending messages to your app  
**Check:**
1. Is channel subscribed? Look for `📻 Subscription succeeded`
2. Is server actually broadcasting? Check backend logs
3. Is firewall blocking? Check network

**Solution:** Verify backend is sending messages to this channel

---

### Missing: `🎯 App event detected`
**Means:** Event type doesn't match expected pattern  
**Check:** Event name in backend vs app  
**Solution:** Event name might be different. Add logging for all events:

```dart
// In websocket_service.dart _handleMessage, change:
} else {
  // Log ALL unhandled events
  Logger.info('🔴 [SERVER] Unhandled event: "$event" on channel "$channel"', _tag);
  Logger.debug('Full message: ${jsonEncode(decodedMessage)}', _tag);
}
```

---

### Missing: `✅ Event parsed successfully`
**Means:** Event structure doesn't match MessageSentEvent format  
**Check:** Event data structure  
**Solution:** Compare with expected model:

```dart
// Expected structure in data:
{
  "type": "message_sent",  // MUST match
  "message_id": "string",
  "text": "string",
  "sender_id": number,
  "timestamp": "ISO string"
}
```

---

## 🟡 Logs Appear BUT Messages Don't Show in Chat

### Issue: Event parsed but not showing in chat
**Cause:** Event listener not connected or UI not updating  

**Check 1: Is event listener running?**

In chat screen, make sure you called:

```dart
@override
void initState() {
  super.initState();
  initializeWebSocket(
    userToken: authProvider.authToken!,
    userId: authProvider.currentUser!.id,
    channelName: 'private-chat.${widget.conversationId}.${authProvider.currentUser!.id}',
    onMessageReceived: (event) {
      Logger.info('🎉 [CHAT] Message received in UI: ${event.messageId}', 'ChatScreen');
      // Handle message
      setState(() {
        messages.add(event);
      });
    },
    onUserTyping: (event) { ... },
    onMessagesRead: (event) { ... },
  );
}
```

**Add this log to see if callback is triggered:**

```dart
onMessageReceived: (event) {
  Logger.info('✅ [CHAT] onMessageReceived callback triggered!', 'ChatScreen');
  Logger.debug('Event: ${jsonEncode(event)}', 'ChatScreen');
  setState(() {
    messages.add(event);
  });
}
```

---

## 📋 Complete Debugging Checklist

- [ ] Connection established? (look for ✅ Connection established)
- [ ] Channel subscribed? (look for 📻 Subscription succeeded)
- [ ] Backend sending messages? (check backend logs)
- [ ] Raw message appearing in logs? (look for 📨 Raw message)
- [ ] Event being parsed? (look for ✅ Event parsed successfully)
- [ ] Callback being triggered? (look for callback logs)
- [ ] UI updating? (check setState being called)
- [ ] Messages showing? (check chat screen)

---

## 🛠️ Quick Test

1. **Terminal 1:** Run app
```bash
flutter run
```

2. **Terminal 2:** Watch logs
```bash
flutter logs | grep -E "(📨|✅|❌|\[SERVER\])"
```

3. **Terminal 3:** Send test message from backend
```bash
# Your test command here
```

4. **Watch Terminal 2** for messages appearing

---

## 📞 If Still Not Working

Provide these logs:

```bash
# Get last 50 lines of WebSocket logs
flutter logs | tail -50 | grep -E "(WebSocket|message|chat)" > websocket_logs.txt
```

Share:
1. `websocket_logs.txt`
2. Backend broadcast code
3. Chat UI code (initState part)
4. Error messages if any

---

**Updated:** 26 October 2025  
**Status:** Debugging guide ready

---

## Quick Commands

```bash
# See if server is sending to right channel
flutter logs | grep "private-chat"

# See if events are parsed
flutter logs | grep "Event parsed"

# See all errors
flutter logs | grep "❌"

# Follow complete flow
flutter logs | grep -E "(🔌|📨|✅|🎯|💾)"
```
