# Worker ID Fix - Task Worker Detail Navigation

## Issue
When navigating to the task worker detail screen, the code was sending the user ID (456) instead of the task worker assignment ID (16) from the API response.

## Root Cause
The API response structure includes:
```json
{
  "id": 16,  // ← Task worker assignment ID (needed for detail endpoint)
  "user": {
    "id": 456,  // ← User ID (was being used instead)
    "name": "jamshid",
    ...
  },
  ...
}
```

The `WorkerUser` model was only storing the user ID (456) and ignoring the task worker assignment ID (16).

## Solution

### 1. Updated `WorkerUser` Model (`worker_models.dart`)
Added a new field `taskWorkerId` to store the task worker assignment ID:

```dart
class WorkerUser {
  final int id; // User ID (456)
  final int? taskWorkerId; // Task worker assignment ID (16)
  final String name;
  // ... other fields
  
  factory WorkerUser.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return WorkerUser(
      id: userObj['id'] as int? ?? 0, // User ID
      taskWorkerId: json['id'] as int?, // Top-level id is task worker ID
      name: userObj['name'] as String? ?? '',
      // ... map other fields
    );
  }
}
```

### 2. Updated Navigation in `task_detail_screen.dart`
Changed the worker tap handler to use the correct worker ID:

```dart
onWorkerTap: (worker) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => TaskWorkerDetailScreen(
        taskId: task.id,
        // Use taskWorkerId if available, otherwise use user id
        workerId: worker.taskWorkerId ?? worker.id,
      ),
    ),
  );
}
```

## API Endpoint Behavior
- Worker list endpoint `/tasks/{task}/workers` returns array with task worker assignment IDs
- Worker detail endpoint `/tasks/{task}/workers/{worker}` expects the task worker assignment ID (not user ID)
- The top-level `id` field in the response is the assignment ID
- The nested `user.id` is the actual user ID

## Testing
Now when users tap on a worker in the task detail screen:
- ✅ Task ID: 3 (correct)
- ✅ Worker ID: 16 (task worker assignment ID - correct)
- ✅ Endpoint called: `/tasks/3/workers/16` (correct)

## Backward Compatibility
The fallback `worker.id` ensures that if `taskWorkerId` is null (for legacy data), the code still works by using the user ID as a fallback.
