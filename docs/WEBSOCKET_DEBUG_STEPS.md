# 🎯 WebSocket Debug - Messages Not Showing - Action Steps

**Problem:** Messages arriving at WebSocket server but not showing in logs or chat

---

## ✅ Step-by-Step Debugging

### Step 1: Run Enhanced Logging Version

```bash
# Terminal 1: Run app with your latest code
cd /Users/jamshidbek/FlutterProjects/task_manager_mobile
flutter run
```

### Step 2: Monitor ONLY WebSocket Messages

```bash
# Terminal 2: Open NEW terminal and run this
flutter logs | grep -E "(📨|🎯|💾|✅|❌|🔄|🔴|🔗|📻|\[TRACE\])"
```

This will show:
- 📨 = Raw message from server
- 🎯 = App event detected
- 💾 = Raw app event data  
- ✅ = Successfully parsed
- ❌ = Error
- 🔄 = Trace of execution flow
- 🔴 = Problem detected
- 🔗 = Connection established
- 📻 = Subscription succeeded

### Step 3: Send a Test Message

From your backend, manually broadcast a message:

**If using Laravel/Reverb:**
```php
use App\Events\MessageSentEvent;
use Illuminate\Support\Facades\Broadcast;

// Get user IDs
$userId1 = 1;
$userId2 = 2;
$conversationId = 1;

// Broadcast event to private channel
Broadcast::channel('private-chat.' . $conversationId . '.' . $userId1)->dispatch(
    new MessageSentEvent([
        'type' => 'message_sent',
        'message_id' => 'test-' . time(),
        'text' => 'Test message from backend',
        'sender_id' => $userId2,
        'conversation_id' => $conversationId,
        'timestamp' => now()->toIso8601String(),
    ])
);
```

**Or using curl (if you have an API endpoint):**
```bash
curl -X POST https://your-backend.com/api/messages \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": 1,
    "text": "Test message"
  }'
```

### Step 4: Watch Terminal 2 Output

Look for this sequence of logs:

```
📨 [SERVER] Raw message: {"event":"message_sent","channel":"private-chat.1.1","data":{...}}
🔄 [TRACE] Raw message received (type: String)
📡 [SERVER] Event: "message_sent" | Channel: "private-chat.1.1" | Data type: Map
🎯 [SERVER] App event detected. Event: "message_sent", Channel: "private-chat.1.1"
🔄 [TRACE] Routing to _handleAppEvent
💾 [SERVER] Raw app event data: {"type":"message_sent","message_id":"test-...",...}
🔄 [TRACE] Data is Map, attempting to parse event
🔄 [TRACE] Calling WebSocketEvent.fromJson with: [type, message_id, text, sender_id, ...]
✅ [SERVER] Event parsed successfully: MessageSentEvent
🔄 [TRACE] Adding event to stream
✅ [TRACE] Event successfully added to stream
```

---

## 🔍 Interpretation Guide

### If you see 📨 but NOT 🎯
**Means:** Event doesn't match app-specific event naming  
**Check:** Backend event name vs app expected names
**Solution:** Event name is probably different. Backend is sending something app doesn't recognize

### If you see 🎯 but NOT 💾
**Means:** Data is not a Map or error parsing  
**Check:** `⚠️ [SERVER] Invalid app event data type`
**Solution:** Data structure is wrong. Check backend payload

### If you see 💾 but NOT ✅
**Means:** Event parsing failed  
**Check:** `⚠️ [SERVER] Failed to parse event: ...`
**Solution:** Event data doesn't match MessageSentEvent structure. See below.

### If you see ✅ but message NOT in chat
**Means:** Event parsed but UI not updated  
**Check:** Is `onMessageReceived` callback being called?
**Solution:** Add logging in chat screen callback

---

## 📋 Expected Message Structure

Your backend MUST send messages in this format:

```json
{
  "event": "message_sent",
  "channel": "private-chat.1.1",
  "data": {
    "type": "message_sent",
    "message_id": "unique-id",
    "text": "Hello",
    "sender_id": 2,
    "conversation_id": 1,
    "timestamp": "2025-10-26T10:30:00Z"
  }
}
```

**Critical fields:**
- `event` = "message_sent" (EXACT match)
- `type` = "message_sent" (EXACT match)
- `message_id` = string (unique)
- `text` = string (message content)
- `sender_id` = number (user who sent)
- `conversation_id` = number (which chat)
- `timestamp` = ISO 8601 string

---

## 🛠️ If Still Not Working

### Check 1: Connection Status
```bash
flutter logs | grep "✅ \[SERVER\] Connection established"
```
Should see this. If not, WebSocket not connecting.

### Check 2: Channel Subscription
```bash
flutter logs | grep "📻 \[SERVER\] Subscription succeeded"
```
Should see this. If not, not subscribed to channel.

### Check 3: Raw Messages Arriving
```bash
flutter logs | grep "📨 \[SERVER\] Raw message"
```
Should see server messages. If not, backend not sending.

### Check 4: Backend Sending Correctly
Check your backend logs:
```bash
# Laravel
tail -f storage/logs/laravel.log | grep -i "broadcast\|message"
```

Should see broadcasts being sent.

---

## 📊 Complete Trace Format

With new logging, you'll see `🔄 [TRACE]` messages showing execution flow:

```
🔄 [TRACE] Raw message received (type: String)
🔄 [TRACE] Routing to _handleAppEvent
🔄 [TRACE] _handleAppEvent called with message keys: [event, channel, data]
🔄 [TRACE] Data is Map, attempting to parse event
🔄 [TRACE] Calling WebSocketEvent.fromJson with: [type, message_id, text, ...]
🔄 [TRACE] Adding event to stream
✅ [TRACE] Event successfully added to stream
```

If flow stops at any point, you've found the issue.

---

## 🧪 Quick Test Commands

```bash
# See connection status
flutter logs | grep -E "(🔗|📻|✅ Connection|✅ Subscription)" | tail -5

# See all raw messages
flutter logs | grep "📨"

# See parsing errors
flutter logs | grep "⚠️"

# See trace of flow
flutter logs | grep "🔄"

# See everything
flutter logs | grep -E "(📨|🎯|💾|✅|❌|🔄|🔴|🔗|📻)"
```

---

## 🚨 Error Scenarios

### Scenario 1: No raw messages appearing
```
Message: No 📨 logs
Cause: Backend not sending to this channel
Fix: Verify channel name in backend matches
```

### Scenario 2: Raw message appears but no parse
```
Messages:
📨 [SERVER] Raw message: ...
But then stops

Cause: Event type not recognized by app
Fix: Check event name in backend vs app
```

### Scenario 3: Parse fails
```
🎯 [SERVER] App event detected
But then:
⚠️ [SERVER] Failed to parse event
Cause: Data structure doesn't match model
Fix: Align backend payload with expected fields
```

### Scenario 4: All logs ok but no UI update
```
✅ [TRACE] Event successfully added to stream
But message doesn't appear in chat

Cause: Chat screen not listening to events
Fix: Ensure initializeWebSocket called with onMessageReceived callback
```

---

## 📞 Provide These When Asking for Help

```bash
# Run this and save output
flutter logs | tail -100 > websocket_debug.txt

# Share:
1. websocket_debug.txt (last 100 lines of logs)
2. Backend broadcast code
3. Chat screen initState code
4. Error messages (if any)
```

---

## ✅ Success Criteria

You'll know it's working when:

1. ✅ App starts and connects
2. ✅ Channel subscription succeeds
3. ✅ Send message from backend
4. ✅ See all trace logs appearing
5. ✅ Message appears in chat UI

---

**Last Updated:** 26 October 2025  
**Enhanced Logging Active:** YES  
**Ready to Debug:** YES

Run the app and send a test message now! 🚀
