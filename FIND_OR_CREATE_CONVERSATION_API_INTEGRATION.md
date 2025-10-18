# Find-or-Create Conversation API Integration

## Overview

This document details the implementation of the find-or-create conversation API endpoint (`POST /inbox/conversations/find-or-create`) which allows finding an existing direct conversation with a user or creating a new one if it doesn't exist.

## API Endpoint

**Endpoint**: `POST /inbox/conversations/find-or-create`  
**Purpose**: Find existing direct conversation or create new one with specified partner  
**Authentication**: Bearer Token Required

### Request Body
```json
{
  "partner_id": 2
}
```

### Response Structure
```json
{
  "id": 1,
  "type": "direct",
  "title": "Ali Valiyev",
  "avatar": "string",
  "last_message": "Siz: Yaxshi, rahmat.",
  "last_message_time": "5 daqiqa avval",
  "unread_count": 3
}
```

### Response Codes
- **200**: Conversation found or created successfully
- **401**: Unauthenticated (invalid token)
- **422**: Validation Error (missing or invalid partner_id)

## Implementation

### 1. Data Model

#### FindOrCreateConversationResponse Model
- **File**: `lib/data/models/find_or_create_conversation_response.dart`
- **Purpose**: Response model for find-or-create conversation API
- **Key Properties**:
  - `id`: Conversation identifier
  - `type`: "direct" or "department"
  - `title`: Conversation display name
  - `avatar`: Partner avatar URL (optional)
  - `lastMessage`: Latest message preview (optional)
  - `lastMessageTime`: Formatted time string (optional)
  - `unreadCount`: Number of unread messages

#### Model Features
- **JSON Serialization**: Complete fromJson/toJson methods
- **UI Helpers**: Display helpers for title, message preview, formatting
- **Type Checking**: isDirect/isDepartment boolean properties
- **Conversion**: toConversationJson for compatibility with existing models

### 2. API Service Integration

#### Updated ContactsApiService
- **File**: `lib/data/services/contacts_api_service.dart`
- **New Method**: `findOrCreateConversation(int partnerId)`
- **Features**:
  - HTTP POST request with partner ID
  - Comprehensive error handling for all response codes
  - 422 validation error parsing with detailed messages
  - Bearer token authentication
  - Detailed logging for debugging

#### Error Handling Strategy
```dart
// 401 Unauthorized
if (response.statusCode == 401) {
  throw ContactsApiException('Unauthenticated. Please login again.');
}

// 422 Validation Error
if (response.statusCode == 422) {
  final errors = errorBody['errors'] as Map<String, dynamic>? ?? {};
  final errorMessages = <String>[];
  errors.forEach((key, value) {
    if (value is List) {
      errorMessages.addAll(value.cast<String>());
    }
  });
  final errorMessage = errorMessages.isNotEmpty 
      ? errorMessages.join(', ')
      : 'Validation error';
  throw ContactsApiException(errorMessage);
}
```

### 3. State Management

#### Updated ContactsProvider
- **File**: `lib/presentation/providers/contacts_provider.dart`
- **New Method**: `findOrCreateConversation(int partnerId)`
- **State Variables**:
  - `_isCreatingConversation`: Loading state for conversation creation
  - `_createConversationError`: Error state for failed operations
- **Features**:
  - Loading state management
  - Error handling and user feedback
  - Success/failure return values
  - Detailed logging

### 4. UI Integration

#### Updated CreateChatScreen
- **File**: `lib/presentation/screens/chat/create_chat_screen.dart`
- **Enhanced `_createDirectChat` Method**:
  - Uses find-or-create API instead of sample chat creation
  - Loading dialog during API call
  - Error handling with user-friendly messages
  - Navigation to conversation with real conversation ID

#### Helper Method: `_convertResponseToChat`
```dart
Future<Chat> _convertResponseToChat(
  FindOrCreateConversationResponse response, 
  Contact contact,
) async {
  // Convert API response to Chat object for UI compatibility
  // Includes last message, chat members, and metadata
}
```

## Key Features

### Smart Conversation Management
- **Existing Conversation**: Returns existing conversation if found
- **New Conversation**: Creates new conversation if none exists
- **Partner Detection**: Automatically identifies conversation partner
- **Type Safety**: Ensures direct conversation type

### User Experience Enhancement
- **Instant Access**: Quick access to conversations without duplication
- **Loading Feedback**: Visual loading indicators during API calls
- **Error Recovery**: Clear error messages with retry options
- **Seamless Navigation**: Direct navigation to conversation screen

### API Integration Benefits
- **Real Data**: Uses actual backend conversations instead of local mock data
- **Persistence**: Conversations persist across app sessions
- **Synchronization**: Keeps client and server in sync
- **Scalability**: Supports unlimited conversations with pagination

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── find_or_create_conversation_response.dart # Response model
│   └── services/
│       └── contacts_api_service.dart # Updated with find-or-create method
├── presentation/
│   ├── providers/
│   │   └── contacts_provider.dart # Updated with conversation creation
│   └── screens/
│       └── chat/
│           └── create_chat_screen.dart # Updated direct chat creation
```

## Usage Flow

1. **Contact Selection**: User selects a contact from the create chat screen
2. **API Request**: System sends POST request with partner ID to find-or-create endpoint
3. **Response Processing**: API returns existing or newly created conversation details
4. **Chat Object Creation**: Response is converted to Chat object for UI compatibility
5. **Navigation**: User is navigated to the conversation screen with real conversation ID
6. **Real-time Chat**: User can immediately start chatting with real API backend

## Error Scenarios

### Authentication (401)
- **Trigger**: Expired or invalid Bearer token
- **Handling**: Show authentication error message
- **User Action**: Redirect to login or refresh token

### Validation Error (422)
- **Trigger**: Missing or invalid partner_id in request
- **Handling**: Parse and display validation error messages
- **User Action**: Fix input and retry

### Network Issues
- **Trigger**: Connection problems or server errors
- **Handling**: Show network error with retry option
- **User Action**: Check connection and retry

### Partner Not Found
- **Trigger**: Invalid partner_id (user doesn't exist)
- **Handling**: Display user-friendly error message
- **User Action**: Select different contact

## Benefits Over Previous Implementation

### Before (Sample Data)
- Mock chat creation with local data only
- No persistence across sessions
- No real message history
- Limited to sample conversations

### After (API Integration)
- Real conversation creation with backend
- Full persistence and synchronization
- Access to complete message history
- Unlimited real conversations
- Proper user association and permissions

## Future Enhancements

### Planned Features
1. **Group Conversation Creation**: Extend to support group conversations
2. **Conversation Settings**: Manage conversation preferences and permissions
3. **Real-time Notifications**: Instant notifications for new conversations
4. **Conversation Search**: Search and filter conversations by partner or content
5. **Conversation Archiving**: Archive and restore conversations

### Performance Optimizations
1. **Caching**: Cache conversation responses for faster access
2. **Background Creation**: Create conversations in background for better UX
3. **Batch Operations**: Support creating multiple conversations at once
4. **Offline Support**: Queue conversation creation requests for offline scenarios

## Configuration

### API Configuration
Update base URL and timeout in `ApiConfig`:
```dart
class ApiConfig {
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const Duration timeout = Duration(seconds: 30);
}
```

### Authentication Token
Update token management in API service:
```dart
Future<Map<String, String>> _getHeaders() async {
  final token = await AuthService.getToken();
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
```

## Testing

### Unit Tests
- FindOrCreateConversationResponse model serialization
- ContactsApiService find-or-create method
- ContactsProvider state management
- Error handling scenarios

### Integration Tests
- End-to-end conversation creation flow
- Error recovery mechanisms
- UI interaction patterns
- Navigation between screens

### API Mock Tests
- Mock successful conversation creation
- Mock existing conversation found
- Mock validation errors
- Mock authentication failures

## Success Metrics

✅ **Completed Features**:
1. Complete find-or-create conversation API integration
2. Real conversation creation with backend persistence
3. Smart existing conversation detection
4. Comprehensive error handling for all response codes
5. Loading states and user feedback
6. Seamless navigation to conversation screen
7. Backward compatibility with existing chat system
8. Model conversion for UI compatibility
9. Provider-based state management
10. Enhanced create chat screen functionality

## Deployment Checklist

- [x] Find-or-create conversation API integration complete
- [x] Response model implemented and tested
- [x] API service method with comprehensive error handling
- [x] Provider state management for conversation creation
- [x] UI integration with loading states and error feedback
- [x] Navigation integration with real conversation IDs
- [x] Model conversion for UI compatibility
- [ ] Authentication token management setup
- [ ] Production API endpoint configuration
- [ ] Performance testing and optimization
- [ ] User acceptance testing

## Conclusion

The find-or-create conversation API integration provides a seamless and efficient way for users to start conversations with their contacts. By intelligently finding existing conversations or creating new ones as needed, the system eliminates duplicate conversations while providing instant access to chat functionality. The implementation maintains full compatibility with the existing chat system while adding real backend persistence and synchronization capabilities.