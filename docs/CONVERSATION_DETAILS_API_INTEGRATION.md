# Conversation Details API Integration

## Overview

This document details the implementation of the conversation details API endpoint (`GET /inbox/conversations/{conversation}`) which provides detailed conversation information including message history, partner details, and file attachments.

## API Endpoint

**Endpoint**: `GET /inbox/conversations/{conversation}`  
**Purpose**: Fetch detailed conversation data including message history  
**Authentication**: Bearer Token Required

### Parameters
- `conversation` (integer, path) - Conversation ID

### Response Structure
```json
{
  "id": 1,
  "type": "direct",
  "partner": {
    "id": 1,
    "name": "Ali Valiyev",
    "phone": "+998901234567",
    "email": "ali@example.com",
    "roles": ["user"],
    "created_at": "2025-01-01 12:34:56",
    "updated_at": "2025-01-10 08:15:00"
  },
  "messages": [
    {
      "id": 101,
      "body": "Salom, yaxshimisiz?",
      "conversation_id": 1,
      "is_read": false,
      "sender": {
        "id": 1,
        "name": "Ali Valiyev",
        "phone": "+998901234567",
        "email": "ali@example.com",
        "roles": ["user"],
        "created_at": "2025-01-01 12:34:56",
        "updated_at": "2025-01-10 08:15:00"
      },
      "created_at": "2025-09-28T14:30:00.000000Z",
      "files": [
        {
          "id": 1,
          "name": "document.pdf",
          "size": "128.5 KB",
          "mime_type": "application/pdf",
          "is_image": false,
          "url": "http://.../files/1/download",
          "preview_url": "http://.../storage/chat_files/image.png"
        }
      ]
    }
  ]
}
```

## Implementation

### 1. Data Models

#### ConversationDetails Model
- **File**: `lib/data/models/conversation_details.dart`
- **Purpose**: Main response model for conversation details API
- **Key Properties**:
  - `id`: Conversation identifier
  - `type`: "direct" or "department"
  - `partner`: Partner information
  - `messages`: List of conversation messages

#### ConversationPartner Model
- **Purpose**: Partner information in conversations
- **Features**: 
  - User details (name, phone, email, roles)
  - Conversion to Contact model for UI compatibility

#### ConversationMessage Model
- **Purpose**: Individual message in conversation
- **Features**:
  - Message content and metadata
  - Sender information
  - File attachments support
  - Read status tracking

#### MessageFile Model
- **Purpose**: File attachment in messages
- **Features**:
  - File metadata (name, size, MIME type)
  - Download and preview URL support
  - Image detection capabilities

#### MessageSender Model
- **Purpose**: Message sender information
- **Features**: User details with display name helper

### 2. API Service

#### ConversationDetailsApiService
- **File**: `lib/data/services/conversation_details_api_service.dart`
- **Methods**:
  - `getConversationDetails(int conversationId)`: Fetch conversation details
  - `markConversationAsRead(int conversationId)`: Mark all messages as read
  - `sendMessage({required int conversationId, required String message, List<String>? files})`: Send new message
- **Features**:
  - Comprehensive error handling
  - HTTP status code management
  - Bearer token authentication
  - Logging and debugging support

### 3. State Management

#### ConversationDetailsProvider
- **File**: `lib/presentation/providers/conversation_details_provider.dart`
- **State Management**:
  - Current conversation details
  - Loading states for different operations
  - Error handling for API failures
  - Message sending capabilities
  - Mark as read functionality

### 4. UI Integration

#### Updated ChatConversationScreen
- **File**: `lib/presentation/screens/chat/chat_conversation_screen.dart`
- **Enhancements**:
  - Support for both API data and fallback sample data
  - Real-time message display from API
  - Message sending via API
  - Error state handling
  - Conversation message to UI message conversion

#### Updated Chat Navigation
- **File**: `lib/presentation/screens/main/chat_screen.dart`
- **Changes**:
  - Extract conversation ID from chat ID
  - Pass conversation ID to conversation screen
  - Maintain backward compatibility with sample data

## Key Features

### API Integration
- **Real Data Display**: Shows actual conversation messages from API
- **Message Sending**: Send messages through API endpoints
- **Read Status**: Mark conversations and messages as read
- **File Attachments**: Support for viewing file attachments in messages

### Error Handling
- **Network Errors**: Graceful handling with retry mechanisms
- **Authentication Errors**: 401 handling with re-authentication prompts
- **Authorization Errors**: 403 handling for access denied scenarios
- **Fallback Strategy**: Sample data fallback when API is unavailable

### User Experience
- **Loading States**: Clear visual feedback during API operations
- **Error Messages**: User-friendly error messages and recovery options
- **Real-time Updates**: Live message display as they're sent/received
- **Seamless Integration**: Backward compatibility with existing chat functionality

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── conversation_details.dart    # Conversation details models
│   └── services/
│       └── conversation_details_api_service.dart # API service
├── presentation/
│   ├── providers/
│   │   └── conversation_details_provider.dart # State management
│   └── screens/
│       ├── chat/
│       │   └── chat_conversation_screen.dart # Updated conversation UI
│       └── main/
│           └── chat_screen.dart # Updated navigation
└── main.dart # Provider registration
```

## Usage Flow

1. **Navigation**: User taps on a chat from the chat list
2. **ID Extraction**: System extracts conversation ID from chat ID
3. **API Call**: ConversationDetailsProvider loads conversation details
4. **Display**: Messages are displayed with real API data
5. **Interaction**: User can send messages and mark as read
6. **Real-time**: Updates reflected immediately in UI

## Error Scenarios

### Authentication (401)
- **Trigger**: Expired or invalid token
- **Handling**: Prompt for re-authentication
- **User Action**: Redirect to login screen

### Authorization (403)
- **Trigger**: User not member of conversation
- **Handling**: Show access denied message
- **User Action**: Return to chat list

### Network Issues
- **Trigger**: Connection problems
- **Handling**: Show retry option with error message
- **User Action**: Retry or use cached data

### Data Parsing Errors
- **Trigger**: Malformed API response
- **Handling**: Log error and show generic error message
- **User Action**: Refresh or contact support

## Future Enhancements

### Planned Features
1. **Real-time Updates**: WebSocket integration for live messages
2. **File Upload**: Support for sending file attachments
3. **Message Actions**: Reply, edit, delete message capabilities
4. **Push Notifications**: Integration with message notifications
5. **Offline Support**: Local caching and sync capabilities

### Performance Optimizations
1. **Message Pagination**: Load messages in chunks
2. **Image Caching**: Cache message images locally
3. **Background Sync**: Periodic message refresh
4. **Lazy Loading**: Load conversation details on demand

## Configuration

### API Configuration
Update the base URL in `ApiConfig`:
```dart
class ApiConfig {
  static const String baseUrl = 'https://your-api-domain.com/api';
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
- Model serialization/deserialization
- API service methods
- Provider state management
- Error handling scenarios

### Integration Tests
- End-to-end conversation loading
- Message sending flow
- Error recovery mechanisms
- UI interaction patterns

### Mock Data
- API response mocking
- Error simulation
- Performance testing
- Offline scenario testing

## Success Metrics

✅ **Completed Features**:
1. Complete conversation details API integration
2. Real message display from API responses
3. Message sending capabilities
4. Read status management
5. File attachment support
6. Comprehensive error handling
7. Backward compatibility with existing chat system
8. Provider-based state management
9. User-friendly error states and retry mechanisms
10. Seamless navigation integration

## Deployment Checklist

- [x] Conversation details API integration complete
- [x] Message models implemented
- [x] API service with error handling
- [x] Provider state management
- [x] UI integration with fallback support
- [x] Navigation updates with conversation ID
- [x] Error handling and user feedback
- [ ] Authentication token management setup
- [ ] Production API endpoint configuration
- [ ] Performance testing and optimization
- [ ] User acceptance testing

## Conclusion

The conversation details API integration provides a robust foundation for real-time chat functionality while maintaining compatibility with existing chat features. The implementation supports rich message history, file attachments, and comprehensive error handling, creating a seamless user experience for chat interactions.