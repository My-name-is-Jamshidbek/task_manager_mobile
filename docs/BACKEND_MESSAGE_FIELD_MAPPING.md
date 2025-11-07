# Backend to Message Model Mapping

## 📦 Your Backend JSON → Flutter Message Model

### Backend Sends (From Your Example)
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
    "conversation": {...},
    "type": "department",
    "fileGroups": null,
    "created_at": "2025-10-26T13:09:19+05:00"
  }
}
```

### Flutter Message Model Expects

```dart
class Message {
  final String id;              // ← message.id (convert to string)
  final String chatId;          // ← message.conversation_id (convert to string)
  final String senderId;        // ← message.sender.id (convert to string)
  final String? senderName;     // ← message.sender.name
  final String? senderAvatarUrl;// ← message.sender.avatar_url
  final MessageType type;       // ← message.type
  final String content;         // ← message.body
  final DateTime sentAt;        // ← message.created_at
  final MessageStatus status;   // ← message.is_read → sent if false, read if true
  ...
}
```

---

## 🔗 Field Mapping

| Backend Field | Type | → Flutter Field | Type | Mapping Logic |
|---|---|---|---|---|
| `message.id` | int | `id` | String | Convert to String |
| `message.conversation_id` | int | `chatId` | String | Convert to String |
| `message.sender.id` | int | `senderId` | String | Extract sender.id, convert |
| `message.sender.name` | string | `senderName` | String? | Extract from sender |
| `message.sender.avatar_url` | string | `senderAvatarUrl` | String? | Extract from sender |
| `message.type` | string | `type` | MessageType enum | Convert to enum |
| `message.body` | string | `content` | String | Direct mapping |
| `message.created_at` | ISO8601 | `sentAt` | DateTime | Parse datetime |
| `message.is_read` | boolean | `status` | MessageStatus | false → sent, true → read |
| `message.fileGroups` | array? | `attachments` | List<String>? | If implemented |

---

## ⚠️ ISSUE IDENTIFIED: Field Mismatch

Your backend sends different field names than Flutter expects!

### What Flutter Model Expects
```dart
Message.fromJson(Map<String, dynamic> json) {
  return Message(
    id: json['id'] as String,                    // ← Direct id
    chatId: json['chat_id'] as String,           // ← snake_case chat_id
    senderId: json['sender_id'] as String,       // ← snake_case sender_id
    senderName: json['sender_name'] as String?,  // ← snake_case sender_name
    content: json['content'] as String,          // ← Direct content
    sentAt: DateTime.parse(json['sent_at'] as String),  // ← snake_case sent_at
    ...
  );
}
```

### What Your Backend Sends
```json
{
  "id": 25,                          // ✅ id (matches)
  "body": "...",                     // ❌ body (expects content)
  "sender": {...},                   // ❌ nested sender object
  "sender.id": undefined,            // ❌ expects flat sender_id
  "sender.name": undefined,          // ❌ expects flat sender_name
  "conversation_id": 1,              // ❌ snake_case but wrong field name
  "created_at": "...",               // ✅ created_at (matches)
  "is_read": false                   // ❌ is_read but expects status enum
}
```

---

## ✅ SOLUTION: Adapter Pattern

Need to convert backend format to Message model format. Two options:

### Option 1: Modify Message.fromJson() (Recommended for your backend)

```dart
factory Message.fromJson(Map<String, dynamic> json) {
  // Handle Laravel backend format with nested sender
  final sender = json['sender'] as Map<String, dynamic>?;
  final conversationId = json['conversation_id'] ?? json['chat_id'];
  
  return Message(
    id: (json['id'] as dynamic).toString(),
    chatId: conversationId.toString(),
    senderId: (sender?['id'] as dynamic?)?.toString() ?? '',
    senderName: sender?['name'] as String?,
    senderAvatarUrl: sender?['avatar_url'] as String?,
    type: MessageType.values.firstWhere(
      (e) => e.value == json['type'],
      orElse: () => MessageType.text,
    ),
    content: (json['body'] ?? json['content']) as String,  // ← Handle both
    sentAt: DateTime.parse(json['created_at'] as String),
    status: (json['is_read'] as bool?) == true 
        ? MessageStatus.read 
        : MessageStatus.sent,
    ...
  );
}
```

### Option 2: Transform at Backend

Have Laravel send format that matches Flutter:
```json
{
  "id": "25",
  "chat_id": "1",
  "sender_id": "7",
  "sender_name": "Bekmurod",
  "sender_avatar_url": "...",
  "type": "text",
  "content": "jkhgjkhlgljkhg",
  "sent_at": "2025-10-26T13:09:19+05:00",
  "is_read": false
}
```

---

## 🛠️ What Needs to Be Done

Choose ONE:

### ✅ Recommended: Update Message.fromJson() to Handle Backend Format

This keeps your backend unchanged and adds flexibility:

1. Handle nested `sender` object
2. Map `body` → `content`
3. Map `conversation_id` → `chat_id`
4. Convert numeric IDs to strings
5. Map `is_read` boolean to `status` enum

### 🔄 Alternative: Update Backend to Send Flutter Format

Would require backend changes but cleaner architecture.

---

## 📋 Implementation Path

If you choose Option 1 (recommended):

1. **Locate:** `lib/data/models/message.dart`
2. **Find:** `factory Message.fromJson()` method
3. **Replace:** Current parsing with adapter that handles your backend format
4. **Test:** Send message from backend
5. **Verify:** Message displays with correct fields

Would you like me to implement Option 1 (modify Message.fromJson()) to handle your backend format?

