# Task Worker Detail Screen Implementation

## Summary
Created a comprehensive task worker detail screen that displays worker profile information and submission history (confirms, reworks, rejects) with file viewing capabilities.

## Files Created

### 1. `lib/data/models/task_worker_models.dart` (NEW)
Data models for task worker detail API responses:

**TaskWorkerSubmission**
- Represents individual submissions (confirm/rework/reject)
- Fields: id, description, fileGroupId, files, createdAt, updatedAt
- Includes file attachment list parsing

**TaskWorkerDetail**
- Main response model from `/tasks/{task}/workers/{worker}` endpoint
- Fields:
  - taskId, taskWorkerId, departmentUserId
  - user (WorkerUser object)
  - statusCode (0=PENDING, 1=ACCEPTED, 2=REWORK, 3=REJECTED)
  - statusName, statusLabel, statusColor
  - assignedAt, updatedAt timestamps
  - Three submission arrays: confirms, reworks, rejects
- Factory constructor handles envelope and flat response formats

### 2. `lib/presentation/screens/tasks/task_worker_detail_screen.dart` (NEW)
Main UI screen with three-tab interface:

**Features:**
- Tabbed navigation: Confirms | Reworks | Rejects
- Worker profile header showing:
  - Avatar with initials
  - Name and status badge (with color coding)
  - Phone contact
  - Department information
  - Assignment and update timestamps

- Submission history display:
  - Empty state when no submissions
  - Submission cards with description
  - File attachments with click-to-view functionality
  - Submission timestamps (created/updated)
  - Relative date formatting (Today, Yesterday, etc.)

- File viewing integration:
  - Opens FileViewerDialog on file tap
  - Extracts file name from URL
  - Supports PDF and document preview

## Files Modified

### 1. `lib/data/datasources/tasks_api_remote_datasource.dart`
**Added method:**
```dart
Future<ApiResponse<TaskWorkerDetail>> getTaskWorkerDetail({
  required int taskId,
  required int workerId,
})
```
- Endpoint: `GET /tasks/{taskId}/workers/{workerId}`
- Handles envelope responses: `{ data: {...} }` or flat objects
- Returns parsed TaskWorkerDetail with full submission history

**Added import:**
- `import '../models/task_worker_models.dart';`

### 2. `lib/presentation/providers/tasks_api_provider.dart`
**Added method:**
```dart
Future<ApiResponse<TaskWorkerDetail>> getTaskWorkerDetail({
  required int taskId,
  required int workerId,
})
```
- Wrapper around datasource method
- Enables provider pattern usage in screens

**Added imports:**
- `import '../../core/api/api_client.dart';` (for ApiResponse type)
- `import '../../data/models/task_worker_models.dart';` (for TaskWorkerDetail)

### 3. `lib/presentation/widgets/task_assignees_card.dart`
**Enhanced with navigation:**
- Added `onWorkerTap` callback parameter
  ```dart
  final void Function(WorkerUser worker)? onWorkerTap;
  ```
- Wrapped worker cards in GestureDetector
- Passes worker data on tap for navigation

### 4. `lib/presentation/screens/tasks/task_detail_screen.dart`
**Navigation integration:**
- Added import: `import 'task_worker_detail_screen.dart';`
- Updated `_workersSection()` method to pass `onWorkerTap` callback
- Opens TaskWorkerDetailScreen on worker card tap with taskId and workerId

## API Integration

### Response Structure
The API endpoint returns:
```json
{
  "task_id": 1,
  "task_worker_id": 10,
  "department_user_id": 5,
  "user": {
    "id": 3,
    "name": "John Doe",
    "phone": "+998 XX XXX XXXX",
    "avatar_url": "https://...",
    "departments": [
      {
        "id": 1,
        "name": "Development"
      }
    ]
  },
  "status_code": 1,
  "status_name": "ACCEPTED",
  "status_label": "Qabul qilindi",
  "status_color": "success",
  "assigned_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-20T15:30:00Z",
  "confirms": [
    {
      "id": 1,
      "description": "Confirmed and completed",
      "file_group_id": 10,
      "files": [
        {
          "id": 1,
          "name": "report.pdf",
          "mime": "application/pdf",
          "size": 1024000,
          "url": "https://..."
        }
      ],
      "created_at": "2024-01-18T10:00:00Z",
      "updated_at": "2024-01-18T10:00:00Z"
    }
  ],
  "reworks": [],
  "rejects": []
}
```

## UI Components

### Worker Profile Header
- Displays avatar with initials (gradient background)
- Shows worker name, status badge, phone, and departments
- Shows assignment and update timestamps

### Submission List
- Empty state with inbox icon for no submissions
- Card-based layout for each submission
- Description text display
- File section with attachment list
- Timestamps for each submission

### File Items
- Icon with attachment name
- Clickable to open in FileViewerDialog
- File size and type information from API

### Status Colors
- Maps API status colors to Material Design colors:
  - `success` → Green
  - `warning` → Orange
  - `error` → Red
  - `secondary` → Grey
  - Default → Blue

## Navigation Flow

1. User views task detail screen
2. Sees TaskAssigneesCard with worker cards
3. Taps on a worker card
4. TaskWorkerDetailScreen opens with taskId and workerId
5. Screen fetches TaskWorkerDetail from API
6. Displays worker profile and submission history in tabs
7. User can tap files to view them in FileViewerDialog

## Compilation Status
✅ All files compile without errors:
- task_worker_models.dart
- task_worker_detail_screen.dart
- tasks_api_remote_datasource.dart
- tasks_api_provider.dart
- task_assignees_card.dart
- task_detail_screen.dart

## Next Steps
1. Test with real API endpoint to verify response parsing
2. Ensure FileViewerDialog works with all file types
3. Add refresh functionality at detail screen level
4. Consider adding pull-to-refresh on submission lists
5. Add error handling for failed API calls
6. Implement caching for frequently accessed worker details
