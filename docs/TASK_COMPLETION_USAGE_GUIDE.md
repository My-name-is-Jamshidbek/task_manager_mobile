# Task Completion API - Usage Guide & Testing

## Quick Start

### Mark a Task as Complete

#### Basic (without description)
```dart
final provider = context.read<TaskDetailProvider>();
final success = await provider.performAction(TaskActionKind.complete);

if (success) {
  print('✅ Task marked as complete');
} else {
  print('❌ Error: ${provider.actionError}');
}
```

#### With Description
```dart
final success = await provider.performAction(
  TaskActionKind.complete,
  reason: 'Task finished successfully',
);
```

#### With Description and File Group
```dart
final success = await provider.performAction(
  TaskActionKind.complete,
  reason: 'Task finished with attachments',
  fileGroupId: 42,
);
```

---

## API Request Details

### Endpoint
```
POST /tasks/{task}/complete
```

### Request Body Examples

#### Minimal (no parameters)
```json
{}
```

#### With Description
```json
{
  "reason": "Task completed successfully",
  "description": "Task completed successfully"
}
```

#### With File Group
```json
{
  "reason": "Task finished with attachments",
  "description": "Task finished with attachments",
  "file_group_id": 42
}
```

### Response (200 OK)
```json
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
    "deadline": "2025-10-15T10:00:00Z",
    "project": {...},
    "creator": {...},
    "workers": [...],
    "files": [],
    "file_group_id": null,
    "parent_task_id": null,
    "available_actions": ["rework"]
  }
}
```

---

## Integration with UI

### Example: Task Detail Screen Button

```dart
class TaskCompleteButton extends StatelessWidget {
  final int taskId;
  
  const TaskCompleteButton({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskDetailProvider>(
      builder: (context, provider, _) {
        final isCompleting = provider.activeAction == TaskActionKind.complete;
        final isDisabled = isCompleting || provider.actionInProgress;
        
        return ElevatedButton(
          onPressed: isDisabled 
            ? null 
            : () => _completeTask(context, provider),
          child: isCompleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Mark as Complete'),
        );
      },
    );
  }

  Future<void> _completeTask(
    BuildContext context,
    TaskDetailProvider provider,
  ) async {
    // Optional: Show dialog for description
    String? description;
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => _CompletionDialog(
        onDescriptionChanged: (desc) => description = desc,
      ),
    ) ?? false;

    if (!shouldContinue) return;

    final success = await provider.performAction(
      TaskActionKind.complete,
      reason: description,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Task marked as complete'
            : 'Error: ${provider.actionError}'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
```

---

## Complete Implementation Example

### Step 1: Create Completion Dialog
```dart
class TaskCompletionDialog extends StatefulWidget {
  final String? initialDescription;

  const TaskCompletionDialog({this.initialDescription});

  @override
  State<TaskCompletionDialog> createState() => _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends State<TaskCompletionDialog> {
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(
      text: widget.initialDescription ?? '',
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Completion notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'What did you do to complete this task?',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Complete'),
        ),
      ],
    );
  }

  String? get description => 
    _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
}
```

### Step 2: Use in Task Detail Screen
```dart
class TaskDetailScreen extends StatelessWidget {
  final int taskId;

  const TaskDetailScreen({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TaskDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final task = provider.task;
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Task details...
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _showCompletionDialog(context, provider),
                    child: const Text('Mark as Complete'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCompletionDialog(
    BuildContext context,
    TaskDetailProvider provider,
  ) async {
    final description = await showDialog<String?>(
      context: context,
      builder: (context) => TaskCompletionDialog(),
    );

    if (description != null || context.mounted) {
      final success = await provider.performAction(
        TaskActionKind.complete,
        reason: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? '✅ Task marked as complete'
              : '❌ Error: ${provider.actionError}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Navigate back or refresh
          Navigator.pop(context, true);
        }
      }
    }
  }
}
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 404 Not Found | Task doesn't exist | Verify task ID |
| 403 Forbidden | User not authorized | Check permissions |
| 400 Bad Request | Invalid parameters | Check description format |
| Network Error | Connection issue | Retry or show offline message |

### Handle Errors
```dart
final success = await provider.performAction(
  TaskActionKind.complete,
  reason: 'Done',
);

if (!success) {
  final error = provider.actionError;
  
  if (error?.contains('404') ?? false) {
    print('Task not found');
  } else if (error?.contains('403') ?? false) {
    print('You do not have permission to complete this task');
  } else {
    print('Error: $error');
  }
}
```

---

## State Management

### Provider State Properties

```dart
// Active action in progress
final isCompleting = provider.activeAction == TaskActionKind.complete;

// Overall action in progress flag
final isActionInProgress = provider.actionInProgress;

// Error message if action failed
final errorMessage = provider.actionError;

// Current task being edited
final currentTask = provider.task;
```

### Watch for Changes
```dart
Consumer<TaskDetailProvider>(
  builder: (context, provider, _) {
    if (provider.activeAction == TaskActionKind.complete) {
      return const LoadingIndicator();
    }
    
    if (provider.actionError != null) {
      return ErrorMessage(message: provider.actionError!);
    }
    
    return const CompletionSuccessMessage();
  },
)
```

---

## Testing

### Unit Test
```dart
group('Task Completion API', () {
  late TasksApiRemoteDataSource dataSource;
  late MockApiClient apiClient;

  setUp(() {
    apiClient = MockApiClient();
    dataSource = TasksApiRemoteDataSource(apiClient: apiClient);
  });

  test('Complete task with description', () async {
    final mockTask = ApiTask(
      id: 123,
      name: 'Test Task',
      status: const ApiTaskStatusRef(id: 2, label: 'completed'),
    );

    when(apiClient.post<ApiTask>(
      any,
      body: anyNamed('body'),
      fromJson: anyNamed('fromJson'),
    )).thenAnswer((_) async => ApiResponse(
      isSuccess: true,
      data: mockTask,
    ));

    final response = await dataSource.performTaskAction(
      taskId: 123,
      action: TaskActionKind.complete,
      reason: 'Completed successfully',
    );

    expect(response.isSuccess, true);
    expect(response.data?.status?.label, 'completed');
  });

  test('Handle completion error', () async {
    when(apiClient.post<ApiTask>(
      any,
      body: anyNamed('body'),
      fromJson: anyNamed('fromJson'),
    )).thenAnswer((_) async => ApiResponse(
      isSuccess: false,
      error: 'Task not found',
    ));

    final response = await dataSource.performTaskAction(
      taskId: 999,
      action: TaskActionKind.complete,
    );

    expect(response.isSuccess, false);
    expect(response.error, 'Task not found');
  });
});
```

### Integration Test
```dart
testWidgets('Complete task flow', (WidgetTester tester) async {
  // Pump widget with provider
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => TaskDetailProvider(),
      child: const MaterialApp(home: TaskDetailScreen()),
    ),
  );

  // Find and tap complete button
  await tester.tap(find.byText('Mark as Complete'));
  await tester.pumpAndSettle();

  // Verify task is marked as complete
  expect(find.byText('✅ Task marked as complete'), findsOneWidget);
});
```

---

## Files Modified

1. **tasks_api_remote_datasource.dart**
   - Added `fileGroupId` parameter to `performTaskAction()`
   - Added description/reason to request body
   - Added file_group_id to request body

2. **task_detail_provider.dart**
   - Added `fileGroupId` parameter to `performAction()`
   - Pass file group ID to remote data source

---

## API Compatibility

✅ **Fully compatible with API specification:**
- ✅ POST method
- ✅ Path: `/tasks/{task}/complete`
- ✅ Description parameter (mapped as `reason`)
- ✅ Optional file_group_id parameter
- ✅ Proper error handling
- ✅ Response parsing and state update

---

## Next Steps

1. **Test with backend** - Verify endpoint works
2. **Add UI** - Create completion dialog/button
3. **Handle notifications** - Show success/error messages
4. **Track analytics** - Log completion actions
5. **Add to task flow** - Integrate into task detail screen
