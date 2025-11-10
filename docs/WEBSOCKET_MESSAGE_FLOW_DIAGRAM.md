# 🔗 WebSocket Message Flow - Where Messages Go

Visual guide to trace where messages might be getting lost.

---

## 📊 Complete Message Flow

```
SERVER SENDS MESSAGE
         ↓
    WebSocket Channel
         ↓
Flutter WebSocket Stream
         ↓
WebSocketService._handleMessage()  ← 📨 logs here
         ↓
    Decode JSON
         ↓
    Check Event Type
         ↓
    Is App Event? (not Pusher protocol)
         ↓ YES
WebSocketService._handleAppEvent()  ← 💾 logs here
         ↓
    Decode Data (if string)
         ↓
    Is Map?
         ↓ YES
WebSocketEvent.fromJson()  ← ✅ logs here if success
         ↓
    _eventStreamController.add(event)  ← Event added to stream
         ↓
WebSocketManager listens to stream
         ↓
WebSocketManager.onEvent() stream
         ↓
Chat Screen listens to events  ← onMessageReceived callback
         ↓
onMessageReceived(event)  ← Should log in chat screen
         ↓
setState(() { messages.add(event) })
         ↓
UI UPDATES - Message appears in chat ✅
```

---

## 🔴 Breakpoint Detection

Each log shows if message got past that point:

### Breakpoint 1: Raw Message Reception
```
✅ If you see: 📨 [SERVER] Raw message: ...
   → Message reached Flutter from server

❌ If you DON'T see this:
   → Server not sending
   → Network issue
   → Channel name mismatch
```

### Breakpoint 2: Event Type Detection
```
✅ If you see: 📡 [SERVER] Event: "message_sent" | ...
   → Message decoded, event name identified

❌ If you DON'T see this:
   → JSON parse error
   → Malformed message
```

### Breakpoint 3: App Event Recognition
```
✅ If you see: 🎯 [SERVER] App event detected
   → Message recognized as app event (not Pusher protocol)

❌ If you DON'T see this:
   → Event is treated as Pusher system event
   → Wrong event name
```

### Breakpoint 4: Raw Data Extraction
```
✅ If you see: 💾 [SERVER] Raw app event data: {...}
   → Data extracted from message

❌ If you DON'T see this:
   → Error in _handleAppEvent
   → Can't extract data field
```

### Breakpoint 5: Data Type Check
```
✅ If data shows as Map: Data type: Map
   → Ready to parse

❌ If you see: Data type: String
   → Data is string, will attempt decode

❌ If you see: Data type: Null
   → No data in message - PROBLEM!

❌ If you see: Data type: List
   → Data is array, expected object - PROBLEM!
```

### Breakpoint 6: Event Parsing
```
✅ If you see: ✅ [SERVER] Event parsed successfully: MessageSentEvent
   → Event model created, ready for UI

❌ If you see: ⚠️ [SERVER] Failed to parse event: ...
   → Event structure doesn't match model
   → Missing required fields
   → Wrong field names
```

### Breakpoint 7: Stream Addition
```
✅ If you see: ✅ [TRACE] Event successfully added to stream
   → Event in stream, waiting for listeners

❌ If you DON'T see this:
   → Error adding to stream
   → Stream closed
```

### Breakpoint 8: Chat Screen Listener
```
✅ If you see in chat screen logs: onMessageReceived callback triggered
   → Chat screen received event

❌ If you DON'T see this:
   → Chat screen not listening
   → Wrong listener setup
   → initializeWebSocket not called
```

### Breakpoint 9: UI Update
```
✅ If you see: setState being called
   → UI will update

✅ If message appears in chat
   → SUCCESS! 🎉

❌ If message doesn't appear
   → setState not being called
   → Message not being added to list
   → UI not redrawing
```

---

## 🎯 How to Find Your Breakpoint

1. Run app
2. Send test message from backend
3. Look at logs for this sequence:

```
[Expected sequence - each line should appear]

📨 Raw message
  ↓
📡 Event parsed
  ↓
🎯 App event detected
  ↓
💾 Raw data
  ↓
✅ Event parsed successfully
  ↓
✅ Event added to stream
```

**Find the LAST log that appears.** That's where it stops.

---

## 📋 Detailed Breakpoint Analysis

### If last log is: `📨 Raw message`
```
Problem: Message received but not parsed
Cause: JSON decode error
Check: Is message valid JSON?
Solution: 
  1. Backend sending invalid JSON
  2. Check message encoding
```

### If last log is: `📡 Event: ...`
```
Problem: Event detected but not routed
Cause: Event type not recognized
Check: Event name in Pusher protocol check
Solution:
  1. Event name is "pusher:..." or "pusher_internal:..."
  2. Add handler for this event type
  3. Or check backend event naming
```

### If last log is: `🎯 App event detected`
```
Problem: App event detected but not handled
Cause: Error in _handleAppEvent
Check: Error logs after 🎯
Solution:
  1. Data extraction error
  2. Data type mismatch
  3. Check data field in message
```

### If last log is: `💾 Raw data`
```
Problem: Data extracted but not parsed
Cause: Event model doesn't match
Check: Event structure
Solution:
  1. Missing required fields
  2. Wrong field names
  3. Wrong field types
  4. Check backend payload
```

### If last log is: `✅ Event parsed successfully`
```
Problem: Event parsed but not in chat
Cause: Chat screen not listening
Check: Chat screen code
Solution:
  1. onMessageReceived callback not called
  2. initializeWebSocket not called
  3. Stream subscription error
```

---

## 💾 Message Structure Validation

### Valid Message (Will reach chat)
```json
{
  "event": "message_sent",
  "channel": "private-chat.1.2",
  "data": {
    "type": "message_sent",
    "message_id": "test-123",
    "text": "Hello",
    "sender_id": 1,
    "conversation_id": 1,
    "timestamp": "2025-10-26T10:30:00Z"
  }
}
```

### Invalid: data is string (Will fail at parse)
```json
{
  "event": "message_sent",
  "channel": "private-chat.1.2",
  "data": "{\"type\":\"message_sent\",...}"  ← String, not object
}
```
**Log:** `⚠️ Invalid app event data type: String`

### Invalid: Missing type field (Will fail at parse)
```json
{
  "event": "message_sent",
  "channel": "private-chat.1.2",
  "data": {
    "message_id": "test-123",
    "text": "Hello"
    ← MISSING "type" field
  }
}
```
**Log:** `⚠️ Failed to parse event: Missing required field 'type'`

### Invalid: data is null (Will fail at parse)
```json
{
  "event": "message_sent",
  "channel": "private-chat.1.2",
  "data": null  ← NULL, not object
}
```
**Log:** `⚠️ Invalid app event data type: Null`

---

## 🧪 Quick Debug Test

```bash
# 1. Watch for each breakpoint
flutter logs | grep -E "(📨|📡|🎯|💾|✅)" | head -20

# 2. Identify where it stops
# 3. Go to that section above for solution

# 4. For detailed flow trace
flutter logs | grep "🔄 \[TRACE\]"
```

---

## 🚀 Debugging Strategy

**If messages not showing in chat:**

1. **Check Breakpoint 1** (Raw message)
   ```bash
   flutter logs | grep "📨"
   ```
   
2. **If seen, check Breakpoint 4** (Raw data)
   ```bash
   flutter logs | grep "💾"
   ```
   
3. **If seen, check Breakpoint 6** (Parsed)
   ```bash
   flutter logs | grep "✅ Event parsed successfully"
   ```
   
4. **If seen, check Breakpoint 8** (Chat callback)
   ```bash
   # Add log in chat screen:
   onMessageReceived: (event) {
     Logger.info('🎉 [CHAT SCREEN] Received: ${event.messageId}');
     ...
   }
   ```

5. **If not seen, issue is in chat screen, not WebSocket**

---

## 📞 Quick Diagnosis

When asking for help, provide:

```bash
# Get the complete flow
flutter logs | grep -E "(📨|🎯|💾|✅|❌)" | tail -30 > flow.txt

# Share flow.txt and say which log is LAST before it stops
```

---

**Updated:** 26 October 2025  
**Purpose:** Find exactly where messages stop flowing  
**Status:** Ready for debugging

Use this to pinpoint the exact failure point! 🎯
