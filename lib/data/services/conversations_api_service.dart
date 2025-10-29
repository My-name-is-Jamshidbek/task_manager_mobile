import '../models/conversation.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/logger.dart';

class ConversationsApiService {
  final ApiClient _apiClient;

  ConversationsApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get direct conversations list
  ///
  /// [page] - Page number for pagination (default: 1)
  ///
  /// Returns [ConversationsResponse] with direct conversations and pagination info
  Future<ConversationsResponse> getDirectConversations({int page = 1}) async {
    try {
      Logger.info('🔍 Fetching direct conversations - page: $page');

      final queryParams = {'page': page.toString()};

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/inbox/conversations/direct',
        queryParams: queryParams,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final conversationsResponse = ConversationsResponse.fromJson(
          response.data!,
        );
        Logger.info(
          '✅ Fetched ${conversationsResponse.data.length} direct conversations',
        );
        return conversationsResponse;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Direct conversations API error: $errorMessage');
        throw ConversationsApiException(errorMessage);
      }
    } catch (e) {
      if (e is ConversationsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error fetching direct conversations',
        'ConversationsApiService',
        e,
      );
      throw ConversationsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Get department (group) conversations list
  ///
  /// [page] - Page number for pagination (default: 1)
  ///
  /// Returns [ConversationsResponse] with department conversations and pagination info
  Future<ConversationsResponse> getDepartmentConversations({
    int page = 1,
  }) async {
    try {
      Logger.info('🔍 Fetching department conversations - page: $page');

      final queryParams = {'page': page.toString()};

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/inbox/conversations/department',
        queryParams: queryParams,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final conversationsResponse = ConversationsResponse.fromJson(
          response.data!,
        );
        Logger.info(
          '✅ Fetched ${conversationsResponse.data.length} department conversations',
        );
        return conversationsResponse;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Department conversations API error: $errorMessage');
        throw ConversationsApiException(errorMessage);
      }
    } catch (e) {
      if (e is ConversationsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error fetching department conversations',
        'ConversationsApiService',
        e,
      );
      throw ConversationsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Get all conversations (combines direct and department)
  Future<List<Conversation>> getAllConversations({
    int directPage = 1,
    int departmentPage = 1,
  }) async {
    try {
      // Fetch both types in parallel
      final futures = await Future.wait([
        getDirectConversations(page: directPage),
        getDepartmentConversations(page: departmentPage),
      ]);

      final directConversations = futures[0];
      final departmentConversations = futures[1];

      // Combine and sort by last message time (most recent first)
      final allConversations = [
        ...directConversations.data,
        ...departmentConversations.data,
      ];

      // Sort by unread count first, then by last message time
      allConversations.sort((a, b) {
        // Prioritize unread conversations
        if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
        if (a.unreadCount == 0 && b.unreadCount > 0) return 1;

        // Then sort by last message time (newer first)
        // Parse time strings and handle potential null/empty values
        DateTime aTime;
        DateTime bTime;

        try {
          aTime = DateTime.parse(a.lastMessageTime ?? '');
        } catch (e) {
          aTime = DateTime.now().subtract(
            const Duration(days: 365),
          ); // Old fallback
        }

        try {
          bTime = DateTime.parse(b.lastMessageTime ?? '');
        } catch (e) {
          bTime = DateTime.now().subtract(
            const Duration(days: 365),
          ); // Old fallback
        }

        return bTime.compareTo(aTime);
      });

      Logger.info('✅ Combined ${allConversations.length} total conversations');
      return allConversations;
    } catch (e) {
      Logger.error(
        '❌ Error fetching all conversations',
        'ConversationsApiService',
        e,
      );
      rethrow;
    }
  }

  /// Mark specific messages as read
  Future<bool> markMessagesAsRead(List<int> messageIds) async {
    if (messageIds.isEmpty) {
      Logger.info('ℹ️ ConversationsApiService: No message IDs to mark read');
      return true;
    }

    try {
      Logger.info(
        '📖 ConversationsApiService: Marking ${messageIds.length} messages as read',
      );

      final response = await _apiClient.post<dynamic>(
        '/inbox/messages/read',
        body: {'message_ids': messageIds},
      );

      if (response.isSuccess) {
        Logger.info('✅ Messages read API call succeeded');
        return true;
      }

      final errorMessage = response.error ?? 'Unknown error occurred';
      Logger.error('❌ Messages read API error: $errorMessage');

      if (response.statusCode == 403) {
        throw ConversationsApiException(
          'You are not authorized to modify these messages.',
        );
      }

      throw ConversationsApiException(errorMessage);
    } catch (e) {
      if (e is ConversationsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error marking messages as read',
        'ConversationsApiService',
        e,
      );
      throw ConversationsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Close the API client
  void dispose() {
    _apiClient.dispose();
  }
}

/// Custom exception for conversations API errors
class ConversationsApiException implements Exception {
  final String message;

  ConversationsApiException(this.message);

  @override
  String toString() => 'ConversationsApiException: $message';
}
