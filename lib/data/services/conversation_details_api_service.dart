import '../models/conversation_details.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/logger.dart';

class ConversationDetailsApiService {
  final ApiClient _apiClient;

  ConversationDetailsApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get conversation details with messages history
  ///
  /// [conversationId] - ID of the conversation to fetch
  ///
  /// Returns [ConversationDetails] with partner info and messages history
  Future<ConversationDetails> getConversationDetails(int conversationId) async {
    try {
      Logger.info('🔍 Fetching conversation details - ID: $conversationId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/inbox/conversations/$conversationId',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        // Extract conversation data from the 'data' field
        final conversationData =
            response.data!['data'] as Map<String, dynamic>?;
        if (conversationData == null) {
          throw ConversationDetailsApiException(
            'Missing conversation data in API response',
          );
        }

        final conversationDetails = ConversationDetails.fromJson(
          conversationData,
        );
        Logger.info(
          '✅ Fetched conversation details with ${conversationDetails.messagesCount} messages',
        );
        return conversationDetails;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Conversation details API error: $errorMessage');

        // Handle specific error cases based on status code
        if (response.statusCode == 403) {
          throw ConversationDetailsApiException(
            'You are not authorized to view this conversation.',
          );
        } else if (response.statusCode == 404) {
          throw ConversationDetailsApiException('Conversation not found.');
        } else {
          throw ConversationDetailsApiException(errorMessage);
        }
      }
    } catch (e) {
      if (e is ConversationDetailsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error fetching conversation details',
        'ConversationDetailsApiService',
        e,
      );
      throw ConversationDetailsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Mark all messages in conversation as read
  Future<bool> markConversationAsRead(int conversationId) async {
    // TODO: TEMPORARY - API endpoint is not working, disable for now
    Logger.info(
      '📖 [DISABLED] Would mark conversation as read - ID: $conversationId',
    );
    Logger.warning(
      '⚠️ Mark as read API temporarily disabled - endpoint not working',
    );
    return true; // Return success to avoid blocking UI

    /* ORIGINAL CODE - RE-ENABLE WHEN API IS FIXED
    try {
      Logger.info('📖 Marking conversation as read - ID: $conversationId');

      final response = await _apiClient.post(
        '/inbox/conversations/$conversationId/read',
      );

      if (response.isSuccess) {
        Logger.info('✅ Conversation marked as read successfully');
        return true;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Mark as read API error: $errorMessage');
        
        // Handle specific error cases based on status code
        if (response.statusCode == 403) {
          throw ConversationDetailsApiException(
            'You are not authorized to modify this conversation.',
          );
        } else {
          throw ConversationDetailsApiException(errorMessage);
        }
      }
    } catch (e) {
      if (e is ConversationDetailsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error marking conversation as read',
        'ConversationDetailsApiService',
        e,
      );
      throw ConversationDetailsApiException(
        'Network error. Please check your connection.',
      );
    }
    */
  }

  /// Send a new message to conversation
  ///
  /// [conversationId] - ID of the conversation
  /// [message] - Message content to send
  /// [files] - Optional list of file attachments
  ///
  /// Returns the sent message details
  Future<ConversationMessage> sendMessage({
    required int conversationId,
    required String message,
    List<String>? files,
  }) async {
    try {
      Logger.info('📤 Sending message to conversation - ID: $conversationId');

      final body = {
        'body': message,
        if (files != null && files.isNotEmpty) 'files': files,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/inbox/conversations/$conversationId/messages',
        body: body,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        // Extract message data from the 'data' field
        final messageData = response.data!['data'] as Map<String, dynamic>?;
        if (messageData == null) {
          throw ConversationDetailsApiException(
            'Missing message data in API response',
          );
        }

        final sentMessage = ConversationMessage.fromJson(messageData);
        Logger.info('✅ Message sent successfully - ID: ${sentMessage.id}');
        return sentMessage;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Send message API error: $errorMessage');

        // Handle specific error cases based on status code
        if (response.statusCode == 403) {
          throw ConversationDetailsApiException(
            'You are not authorized to send messages in this conversation.',
          );
        } else {
          throw ConversationDetailsApiException(errorMessage);
        }
      }
    } catch (e) {
      if (e is ConversationDetailsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error sending message',
        'ConversationDetailsApiService',
        e,
      );
      throw ConversationDetailsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Close the API client
  void dispose() {
    _apiClient.dispose();
  }
}

/// Custom exception for conversation details API errors
class ConversationDetailsApiException implements Exception {
  final String message;

  ConversationDetailsApiException(this.message);

  @override
  String toString() => 'ConversationDetailsApiException: $message';
}
