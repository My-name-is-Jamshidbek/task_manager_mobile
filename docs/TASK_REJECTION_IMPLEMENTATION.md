# Task Rejection API Integration

## Overview
Implemented complete task rejection feature including API integration, full-screen UI, and multilingual support.

## API Integration

### Endpoint
```
POST /tasks/{task}/reject
Vazifani rad etish (REJECTED)
```

### Parameters
- **task** (path): Task ID
- **description** (body, required): Reason for rejection
- **file_group_id** (body, optional): Attached files group ID

### Implementation
The API infrastructure was already in place:

1. **TasksApiRemoteDataSource** (`lib/data/datasources/tasks_api_remote_datasource.dart`)
   - `performTaskAction()` method handles rejection
   - Sends description as both `reason` and `description` for API compatibility
   - Supports optional file_group_id

2. **TaskDetailProvider** (`lib/presentation/providers/task_detail_provider.dart`)
   - `performAction()` method routes parameters correctly
   - Handles success/error states
   - Refreshes task data after rejection

## UI Implementation

### TaskRejectionScreen
**File**: `lib/presentation/screens/tasks/task_rejection_screen.dart`
**Type**: Full-screen Scaffold-based widget
**Features**:
- Task summary card (displayed in error color scheme)
- Reason field (required, validated on submit)
- FileGroupAttachmentsCard for optional file attachments
- Cancel/Proceed buttons with loading states
- Success/error messaging

### Key Components
- **Description**: Reason for rejection (required)
- **File Group**: Optional attachments via existing FileGroupAttachmentsCard widget
- **Visual Styling**: Error colors for task summary and button

### State Management
- `_reasonController`: Text editing controller for reason input
- `_reasonError`: Error message for validation
- `_selectedFileGroupId`: Selected file group ID
- `_isSubmitting`: Loading state during submission

### Methods
- `_handleReasonChanged()`: Clears error on user input
- `_handleSubmit()`: Validates reason and calls performAction
- `_buildTaskSummary()`: Displays task context with error colors

## Integration with TaskDetailScreen

**File**: `lib/presentation/screens/tasks/task_detail_screen.dart`

### Changes
1. Added import for TaskRejectionScreen
2. Updated `_handleAction()` method to handle `TaskActionKind.reject`
3. Routes to TaskRejectionScreen instead of dialog

### Navigation
```dart
final result = await Navigator.of(context).push<bool>(
  MaterialPageRoute(
    builder: (context) =>
        TaskRejectionScreen(task: task, taskProvider: provider),
  ),
);
```

### Return Handling
- Screen returns `true` on successful rejection
- Displays success message on return
- Pops back to task detail

## Translation Support

### Added Translation Keys

#### English (en.json)
```json
"rejection": {
  "reasonLabel": "Rejection Reason",
  "reasonHint": "Explain why this task is being rejected",
  "reasonHelper": "Required - Provide details about the rejection",
  "reasonRequired": "Please provide a rejection reason",
  "filesLabel": "Attachments",
  "filesHint": "Optionally attach files or group to this rejection"
}
```

#### Russian (ru.json)
```json
"rejection": {
  "reasonLabel": "Причина отклонения",
  "reasonHint": "Объясните, почему эта задача отклоняется",
  "reasonHelper": "Обязательно - Предоставьте подробности об отклонении",
  "reasonRequired": "Пожалуйста, укажите причину отклонения",
  "filesLabel": "Вложения",
  "filesHint": "При необходимости прикрепите файлы или группу к этому отклонению"
}
```

#### Uzbek (uz.json)
```json
"rejection": {
  "reasonLabel": "Rad etish sababi",
  "reasonHint": "Bu vazifa nima uchun rad etilmoqda, tushuntiring",
  "reasonHelper": "Majburiy - Rad etish haqida tafsilotlarni bering",
  "reasonRequired": "Iltimos, rad etish sababini ko'rsating",
  "filesLabel": "Ilova qilingan fayllar",
  "filesHint": "Agar kerak bo'lsa, ushbu rad etishga fayllar yoki guruhni biriktiring"
}
```

## Files Modified/Created

| File | Type | Status |
|------|------|--------|
| task_rejection_screen.dart | Created | ✅ |
| task_detail_screen.dart | Modified | ✅ |
| en.json | Modified | ✅ |
| ru.json | Modified | ✅ |
| uz.json | Modified | ✅ |

## Build Status
- **Errors**: 0
- **Warnings**: 0
- **Status**: ✅ Ready for testing

## Features Implemented
✅ Full-screen rejection UI
✅ Required reason validation
✅ Optional file group attachments
✅ Error handling and messaging
✅ Loading states
✅ Multilingual support (3 languages)
✅ Consistent with completion flow
✅ Error color scheme for visual feedback

## Next Steps
- Manual testing on Android/iOS devices
- Verify API calls with rejection data
- Test file uploads with rejection
- Confirm all language translations display correctly
- Test success/error messaging

## Architecture Pattern
The implementation follows the existing task completion pattern:
1. Full-screen widget instead of dialog
2. Uses existing FileGroupAttachmentsCard for files
3. Provider-based state management
4. Consistent navigation and error handling
5. Multilingual support via AppLocalizations
