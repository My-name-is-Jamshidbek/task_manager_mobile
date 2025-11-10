# Task Completion API - Architecture & Code Flow

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          UI Layer                                │
│  (TaskDetailScreen, CompleteButton, CompletionDialog)            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                 performAction(TaskActionKind.complete)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Provider Layer                                 │
│         (TaskDetailProvider.performAction)                       │
│  ├─ Manages state (_actionInProgress, _activeAction)             │
│  ├─ Calls remote data source                                     │
│  ├─ Updates local task state                                     │
│  └─ Notifies UI listeners                                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
             performTaskAction(taskId, action, reason, fileGroupId)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Remote Data Source Layer                             │
│    (TasksApiRemoteDataSource.performTaskAction)                  │
│  ├─ Builds API endpoint: /tasks/{id}/complete                    │
│  ├─ Constructs request body                                      │
│  ├─ Makes HTTP POST request                                      │
│  └─ Parses response                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    _apiClient.post()
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API Client Layer                               │
│         (ApiClient.post - HTTP wrapper)                          │
│  ├─ Adds authorization headers                                   │
│  ├─ Encodes JSON body                                            │
│  ├─ Makes HTTP POST request                                      │
│  └─ Handles response/errors                                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                        HTTP POST
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Backend Server                                  │
│          POST /tasks/{task}/complete                             │
│  ├─ Validates request                                            │
│  ├─ Updates task status                                          │
│  ├─ Records completion note                                      │
│  └─ Stores file group reference                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                        200 OK Response
                        (Updated Task)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Parse Response & Update State                        │
│  ├─ Parse ApiTask from JSON                                      │
│  ├─ Update local _task                                           │
│  ├─ Refresh workers                                              │
│  ├─ Refresh attachments                                          │
│  └─ Notify listeners                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    notifyListeners()
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UI Updates                                     │
│  ├─ Task status changed to 'completed'                           │
│  ├─ Buttons update based on available_actions                    │
│  ├─ Success message shown                                        │
│  └─ Loading indicator disappears                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Code Flow - Step by Step

### 1. User Interaction
```dart
// UI: User taps "Complete Task" button
User taps button
    ↓
CompleteButton.onPressed()
    ↓
_showCompletionDialog(context)
    ↓
User enters description
    ↓
User confirms (dialog returns true)
```

### 2. Provider Call
```dart
// File: task_detail_provider.dart
Future<bool> performAction(
  TaskActionKind action,  // = TaskActionKind.complete
  {String? reason},       // = "Task finished successfully"
  {int? fileGroupId},     // = null or file group ID
)
{
  // Step 1: Check if already in progress
  if (_actionInProgress) return false;
  
  // Step 2: Set loading state
  _actionInProgress = true;
  _activeAction = action;
  notifyListeners();  // UI shows loading
  
  // Step 3: Call remote data source
  final response = await _remote.performTaskAction(
    taskId: 123,
    action: TaskActionKind.complete,
    reason: "Task finished successfully",
    fileGroupId: null,
  );
}
```

### 3. Remote Data Source Call
```dart
// File: tasks_api_remote_datasource.dart
Future<ApiResponse<ApiTask>> performTaskAction({
  required int taskId,              // = 123
  required TaskActionKind action,   // = TaskActionKind.complete
  String? reason,                   // = "Task finished..."
  int? fileGroupId,                 // = null
})
{
  // Step 1: Build endpoint
  final endpoint = '/tasks/123/complete'
  
  // Step 2: Build request body
  final body = {
    'reason': 'Task finished successfully',
    'description': 'Task finished successfully',
    // fileGroupId is null, so not included
  }
  
  // Step 3: Make API request
  return _apiClient.post<ApiTask>(
    '/tasks/123/complete',
    body: body,
    fromJson: (obj) => ApiTask.fromJson(obj['data']),
  );
}
```

### 4. API Client
```dart
// File: core/api/api_client.dart
Future<ApiResponse<T>> post<T>(
  String endpoint,
  {required Map<String, dynamic> body},
) async
{
  // Step 1: Build full URL
  final url = Uri.parse('https://tms.amusoft.uz/api/tasks/123/complete')
  
  // Step 2: Add headers
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  }
  
  // Step 3: Make HTTP request
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body),  // {"reason": "...", "description": "..."}
  )
  
  // Step 4: Parse response
  final data = jsonDecode(response.body);  // {data: {id: 123, status: ...}}
  
  // Step 5: Return result
  return ApiResponse(
    isSuccess: true,
    data: ApiTask.fromJson(data['data']),
  );
}
```

### 5. HTTP Request
```
POST /tasks/123/complete HTTP/1.1
Host: tms.amusoft.uz
Content-Type: application/json
Authorization: Bearer eyJhbGci...
Content-Length: 89

{
  "reason": "Task finished successfully",
  "description": "Task finished successfully"
}
```

### 6. Server Response
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": {
    "id": 123,
    "name": "Complete report",
    "description": "Quarterly report",
    "status": {
      "id": 2,
      "label": "completed"
    },
    "status_label": "completed",
    "project": {...},
    "workers": [...],
    "available_actions": ["rework"],
    ...
  }
}
```

### 7. Update Local State
```dart
// Back in performAction()
if (response.isSuccess) {
  success = true;
  refreshedTask = response.data;  // Updated ApiTask
  
  if (refreshedTask != null) {
    // Step 1: Update local task
    _task = refreshedTask;  // Status is now "completed"
    
    // Step 2: Refresh related data
    _fetchWorkers(refreshedTask.id);
    _fetchAttachments(refreshedTask.fileGroupId);
    
    // Step 3: Clear loading state
    _actionInProgress = false;
    _activeAction = null;
    
    // Step 4: Notify UI
    notifyListeners();
  }
}
```

### 8. UI Updates
```dart
// Widget rebuilds due to notifyListeners()
Consumer<TaskDetailProvider>(
  builder: (context, provider, _) {
    final task = provider.task;  // Status = "completed"
    
    return Column(
      children: [
        Text(task.status.label),  // "completed"
        // Buttons update based on task.availableActions
        if (task.availableActions.contains('rework'))
          ReworkButton(),
      ],
    );
  },
)
```

---

## Code Files Involved

### 1. **API Constants** (`core/constants/api_constants.dart`)
```dart
static const String tasks = '/tasks';
```
**Purpose**: Base endpoint constant

---

### 2. **Remote Data Source** (`data/datasources/tasks_api_remote_datasource.dart`)
```dart
Future<ApiResponse<ApiTask>> performTaskAction({
  required int taskId,
  required TaskActionKind action,
  String? reason,
  int? fileGroupId,
}) async {
  final endpoint = '${ApiConstants.tasks}/$taskId/${action.pathSegment}';
  final body = <String, dynamic>{};
  
  if (reason != null && reason.trim().isNotEmpty) {
    body['reason'] = reason.trim();
    body['description'] = reason.trim();
  }
  
  if (fileGroupId != null) {
    body['file_group_id'] = fileGroupId;
  }
  
  return _apiClient.post<ApiTask>(
    endpoint,
    body: body.isEmpty ? null : body,
    fromJson: (obj) {
      final map = (obj['data'] is Map<String, dynamic>)
          ? obj['data'] as Map<String, dynamic>
          : obj;
      return ApiTask.fromJson(map);
    },
  );
}
```
**Purpose**: Makes API call and parses response

---

### 3. **Task Actions Model** (`data/models/task_action.dart`)
```dart
enum TaskActionKind {
  complete('complete'),
  // ...
}
```
**Purpose**: Defines available task actions

---

### 4. **Provider** (`presentation/providers/task_detail_provider.dart`)
```dart
Future<bool> performAction(
  TaskActionKind action, {
  String? reason,
  int? fileGroupId,
}) async {
  // ... state management and API call
}
```
**Purpose**: Manages state and orchestrates API call

---

### 5. **API Client** (`core/api/api_client.dart`)
```dart
Future<ApiResponse<T>> post<T>(
  String endpoint, {
  required Map<String, dynamic> body,
  required dynamic Function(dynamic) fromJson,
}) async {
  // ... HTTP request and response handling
}
```
**Purpose**: Handles HTTP communication

---

## State Management Details

### Provider Properties
```dart
class TaskDetailProvider extends ChangeNotifier {
  // Task data
  ApiTask? _task;
  
  // Action state
  bool _actionInProgress = false;
  TaskActionKind? _activeAction;
  String? _actionError;
  
  // Getters
  bool get actionInProgress => _actionInProgress;
  TaskActionKind? get activeAction => _activeAction;
  String? get actionError => _actionError;
  ApiTask? get task => _task;
}
```

### State Transitions
```
Initial State
  ↓
User calls performAction()
  ↓
[Set _actionInProgress = true, _activeAction = complete]
[notifyListeners() → UI shows loading]
  ↓
Remote API call in progress
  ↓
Response received
  ↓
[Success]               [Error]
  ↓                       ↓
Update _task         Set _actionError
  ↓                       ↓
[Set _actionInProgress = false, _activeAction = null]
[notifyListeners() → UI shows result]
  ↓
Final State
```

---

## Error Flow

### When Error Occurs
```dart
if (response.isSuccess) {
  // ... update state
} else {
  // Capture error
  _actionError = response.error ?? 'Unknown error';
}

_actionInProgress = false;
_activeAction = null;
notifyListeners();  // UI shows error

// Consumer can access error
final errorMessage = provider.actionError;
```

### UI Error Display
```dart
Consumer<TaskDetailProvider>(
  builder: (context, provider, _) {
    if (provider.actionError != null) {
      return ErrorWidget(message: provider.actionError!);
    }
    // ... normal display
  },
)
```

---

## Request Body Construction

### When reason is provided
```dart
final body = {
  'reason': 'Task finished successfully',
  'description': 'Task finished successfully',
};
```

### When fileGroupId is provided
```dart
final body = {
  'reason': '...',
  'description': '...',
  'file_group_id': 42,
};
```

### When both provided
```dart
final body = {
  'reason': 'Done',
  'description': 'Done',
  'file_group_id': 42,
};
```

### When neither provided
```dart
final body = null;  // Empty body
```

---

## Response Parsing

### Nested Response Format
```json
{
  "data": {
    "id": 123,
    "name": "Task Name",
    "status": {...}
  }
}
```

### Parsing Code
```dart
final map = (obj['data'] is Map<String, dynamic>)
    ? obj['data'] as Map<String, dynamic>
    : obj;
return ApiTask.fromJson(map);
```

### Handles Both Formats
- ✅ Envelope format: `{data: {...}}`
- ✅ Raw format: `{id: 123, name: "...", ...}`

---

## Testing Architecture

### Unit Test Structure
```dart
// Mock the API client
final mockApiClient = MockApiClient();
final dataSource = TasksApiRemoteDataSource(apiClient: mockApiClient);

// Setup mock response
when(mockApiClient.post(...))
  .thenAnswer((_) async => ApiResponse(
    isSuccess: true,
    data: mockTask,
  ));

// Test the call
final result = await dataSource.performTaskAction(...);

// Verify result
expect(result.isSuccess, true);
expect(result.data?.status?.label, 'completed');
```

### Integration Test Structure
```dart
// Create providers
final provider = TaskDetailProvider();

// Perform action
final success = await provider.performAction(
  TaskActionKind.complete,
  reason: 'Test',
);

// Verify state
expect(success, true);
expect(provider.task?.status?.label, 'completed');
expect(provider.actionInProgress, false);
```

---

## Summary

✅ **Complete architecture for task completion:**
1. **UI Layer**: Buttons, dialogs, messages
2. **Provider Layer**: State management
3. **Remote Layer**: API calls
4. **API Client**: HTTP wrapper
5. **Server**: Processes request

**All layers properly integrated and tested.**
