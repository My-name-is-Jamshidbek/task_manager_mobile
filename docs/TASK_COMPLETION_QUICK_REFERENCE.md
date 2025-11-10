# Task Completion API - Quick Reference 🚀

## API Endpoint
```
POST /tasks/{task}/complete
```

## Parameters
| Name | Type | Required | Example |
|------|------|----------|---------|
| task | path | ✅ | 123 |
| description | body | ❌ | "Task completed" |
| file_group_id | body | ❌ | 42 |

---

## Code Usage

### Complete Task
```dart
await provider.performAction(TaskActionKind.complete);
```

### With Description
```dart
await provider.performAction(
  TaskActionKind.complete,
  reason: 'Done',
);
```

### With File Group
```dart
await provider.performAction(
  TaskActionKind.complete,
  fileGroupId: 42,
);
```

### With Both
```dart
await provider.performAction(
  TaskActionKind.complete,
  reason: 'Done',
  fileGroupId: 42,
);
```

---

## Request Body

### Empty (no parameters)
```json
{}
```

### With description
```json
{
  "reason": "Task completed",
  "description": "Task completed"
}
```

### With file_group_id
```json
{
  "file_group_id": 42
}
```

### With both
```json
{
  "reason": "Done",
  "description": "Done",
  "file_group_id": 42
}
```

---

## Response (200 OK)
```json
{
  "data": {
    "id": 123,
    "status": {
      "label": "completed"
    }
  }
}
```

---

## Error Handling

```dart
final success = await provider.performAction(
  TaskActionKind.complete,
  reason: 'Done',
);

if (!success) {
  print('Error: ${provider.actionError}');
}
```

---

## Provider State

```dart
// Check if completing
provider.activeAction == TaskActionKind.complete

// Check if any action in progress
provider.actionInProgress

// Get error message
provider.actionError

// Get current task
provider.task
```

---

## Files Modified

1. ✅ `tasks_api_remote_datasource.dart` - Added fileGroupId parameter
2. ✅ `task_detail_provider.dart` - Added fileGroupId to performAction

---

## Status

✅ **Implemented**
✅ **Tested**
✅ **Ready for use**

---

## Documentation

- 📄 TASK_COMPLETION_API_INTEGRATION.md - Full spec
- 📄 TASK_COMPLETION_USAGE_GUIDE.md - Examples
- 📄 TASK_COMPLETION_ARCHITECTURE.md - Flow
- 📄 TASK_COMPLETION_SUMMARY.md - Overview
- 📄 TASK_COMPLETION_CHANGES.md - Changes made
- 📄 TASK_COMPLETION_QUICK_REFERENCE.md - This file
