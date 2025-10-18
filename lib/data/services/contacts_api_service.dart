import '../models/contact.dart';
import '../models/find_or_create_conversation_response.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/logger.dart';

class ContactsApiService {
  final ApiClient _apiClient;

  ContactsApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get contacts list for creating new chats
  ///
  /// [search] - Search text by name or phone number (optional)
  /// [page] - Page number for pagination (default: 1)
  ///
  /// Returns [ContactsResponse] with contacts list and pagination info
  Future<ContactsResponse> getContacts({String? search, int page = 1}) async {
    try {
      Logger.info('🔍 Fetching contacts - search: $search, page: $page');

      final queryParams = <String, String>{'page': page.toString()};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/inbox/contacts',
        queryParams: queryParams,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final contactsResponse = ContactsResponse.fromJson(response.data!);
        Logger.info('✅ Fetched ${contactsResponse.data.length} contacts');
        return contactsResponse;
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Contacts API error: $errorMessage');
        throw ContactsApiException(errorMessage);
      }
    } catch (e) {
      if (e is ContactsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error fetching contacts',
        'ContactsApiService',
        e,
      );
      throw ContactsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Find or create a direct conversation with a partner
  ///
  /// [partnerId] - ID of the user to start conversation with
  ///
  /// Returns conversation details if found or created successfully
  Future<FindOrCreateConversationResponse> findOrCreateConversation(
    int partnerId,
  ) async {
    try {
      Logger.info(
        '🔍 Finding or creating conversation with partner ID: $partnerId',
      );

      final body = {'partner_id': partnerId};

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/inbox/conversations/find-or-create',
        body: body,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        try {
          // Extract conversation data from the 'data' field
          final conversationData =
              response.data!['data'] as Map<String, dynamic>?;
          if (conversationData == null) {
            throw FormatException('Missing conversation data in API response');
          }

          final conversationResponse =
              FindOrCreateConversationResponse.fromJson(conversationData);

          Logger.info(
            '✅ Conversation found/created successfully: ${conversationResponse.id}',
          );
          return conversationResponse;
        } catch (e) {
          Logger.error('❌ Failed to parse conversation response: $e');
          Logger.error('❌ Response data: ${response.data}');
          throw ContactsApiException('Invalid response format from server');
        }
      } else {
        final errorMessage = response.error ?? 'Unknown error occurred';
        Logger.error('❌ Find/Create conversation API error: $errorMessage');
        throw ContactsApiException(errorMessage);
      }
    } catch (e) {
      if (e is ContactsApiException) {
        rethrow;
      }

      Logger.error(
        '❌ Network error finding/creating conversation',
        'ContactsApiService',
        e,
      );
      throw ContactsApiException(
        'Network error. Please check your connection.',
      );
    }
  }

  /// Close the API client
  void dispose() {
    _apiClient.dispose();
  }
}

/// Custom exception for contacts API errors
class ContactsApiException implements Exception {
  final String message;

  ContactsApiException(this.message);

  @override
  String toString() => 'ContactsApiException: $message';
}
