# Data Transformation - Laravel Format to Pusher Standard

## 🔄 Before → After Transformation

### Your Backend's Message (Laravel Format)

**Raw JSON from Pusher channel `private-chat.1.1`:**

```json
{
  "message": {
    "id": 25,
    "body": "jkhgjkhlgljkhg",
    "sender": {
      "id": 7,
      "name": "Bekmurod",
      "phone": "998977913883",
      "avatar_url": "https://ui-avatars.com/api/?name=Bekmurod"
    },
    "is_read": false,
    "conversation_id": 1,
    "conversation": {
      "id": 1,
      "department_id": 1,
      "created_by": 1,
      "type": "department",
      "title": "Rektorat",
      "is_archived": 0,
      "created_at": "2025-10-18T06:21:23.000000Z",
      "updated_at": "2025-10-18T06:21:23.000000Z",
      "participants": [...]
    },
    "type": "department",
    "fileGroups": null,
    "created_at": "2025-10-26T13:09:19+05:00"
  },
  "tempId": null
}
```

**Problem:** No `type` field at top level! → Events weren't being recognized

---

### What Flask App Receives (Works ✅)

```json
{
  "message": {...},
  "tempId": null
}
```

**Python treats this as:** "data with message field" → Works!

---

### What Flutter Was Expecting (Before Fix ❌)

```json
{
  "type": "message",
  "data": {
    "message": {...},
    "tempId": null
  }
}
```

---

### What Flutter Now Does (After Fix ✅)

**Step 1: websocket_service.dart receives raw data**
```dart
// This is what arrives from server
var data = {
  "message": {...},
  "tempId": null
}
```

**Step 2: Detect and transform**
```dart
// NEW CODE: Detect Laravel format
if (data.containsKey('message') && !data.containsKey('type')) {
  // Wrap to standard format
  data = {'type': 'message', 'data': data};
}
```

**Step 3: Now data looks like**
```dart
var data = {
  'type': 'message',
  'data': {
    'message': {...},
    'tempId': null
  }
}
```

**Step 4: WebSocketEvent.fromJson() receives it**
```dart
factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;  // ✅ Now has type: "message"
  final data = json['data'] as Map<String, dynamic>?;  // ✅ Data available
  
  switch (type) {
    case 'message':
      return MessageSentEvent.fromJson(data ?? json);  // ✅ Parses successfully
  }
}
```

**Step 5: MessageSentEvent.fromJson() extracts message**
```dart
factory MessageSentEvent.fromJson(Map<String, dynamic> json) {
  // Receives: {'message': {...}, 'tempId': null}
  return MessageSentEvent(
    message: Message.fromJson(json['message']),  // ✅ Extracts nested message
    tempId: json['tempId'],
  );
}
```

---

## 🎯 Key Differences Explained

| Aspect | Your Backend | What Flutter Needed |
|--------|--------------|-------------------|
| **Top-level structure** | `{"message": {...}}` | `{"type": "...", "data": {...}}` |
| **Message location** | Direct under `"message"` | Nested under `"data"` |
| **Type field** | ❌ Missing | ✅ Required |
| **Solution** | ✅ Auto-detected and wrapped | ✅ Wrap detection added |

## 📊 Message Content Mapping

Your backend sends this structure inside `"message"`:

```json
{
  "id": 25,              // Message ID
  "body": "...",         // Message text
  "sender": {            // Sender user info
    "id": 7,
    "name": "Bekmurod",
    "phone": "...",
    "avatar_url": "..."
  },
  "is_read": false,      // Read status
  "conversation_id": 1,  // Conversation reference
  "conversation": {...}, // Full conversation object
  "type": "department",  // Message type
  "fileGroups": null,    // Attachments (if any)
  "created_at": "..."    // Timestamp
}
```

This maps to Flutter's Message model:
- `id` → message.id
- `body` → message.body
- `sender` → message.sender (User model)
- `is_read` → message.isRead
- `conversation_id` → message.conversationId
- `created_at` → message.createdAt

## ✅ Validation Checklist

After fix is applied, the flow is:

```
1. ✅ Server sends: {"message": {...}, "tempId": null}
2. ✅ websocket_service detects Laravel format
3. ✅ websocket_service wraps: {"type": "message", "data": {...}}
4. ✅ WebSocketEvent.fromJson recognizes type: "message"
5. ✅ MessageSentEvent.fromJson extracts message from nested structure
6. ✅ Message object created successfully
7. ✅ Event added to stream
8. ✅ Chat UI receives event and updates
9. ✅ Message appears in chat
```

## 🔍 Debug If Message Still Doesn't Show

Check logs in order:

1. **First log:**
   - `🎯 [SERVER] Detected Laravel message format` = ✅ Detection working
   - No log = Data not reaching handler

2. **Second log:**
   - `💾 [SERVER] Raw app event data: {"message": {...}}` = ✅ Wrapping working
   - Different data structure = Check if event name is different

3. **Third log:**
   - `✅ [SERVER] Event parsed successfully: MessageSentEvent` = ✅ All working
   - `❌ [SERVER] Failed to parse event:` = Message model field mismatch

4. **Last log:**
   - Message appears in chat = ✅ Complete success!
   - No message = Check if chat UI is listening to WebSocket events

