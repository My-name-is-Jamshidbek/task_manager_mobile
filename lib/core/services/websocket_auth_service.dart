import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';

/// Handles authorization for private/presence WebSocket channels.
class WebSocketAuthService {
  static const String _tag = 'WebSocketAuthService';

  /// Authorize access to a channel via the broadcasting auth endpoint.
  static Future<String> authorize({
    required String channelName,
    required String socketId,
  }) async {
    final apiClient = ApiClient();

    Logger.info(
      '$_tag: Authorizing channel "$channelName" for socket $socketId',
      _tag,
    );

    final response = await apiClient.post<Map<String, dynamic>>(
      ApiConstants.broadcastingAuth,
      body: {'channel_name': channelName, 'socket_id': socketId},
      includeAuth: true,
      showGlobalError: true,
      fromJson: (json) => json,
    );

    Logger.info('$_tag: Auth response status: ${response.statusCode}', _tag);

    if (response.isSuccess && response.data != null) {
      final authToken = response.data!['auth'] as String?;
      if (authToken != null && authToken.isNotEmpty) {
        Logger.info('$_tag: Authorization successful', _tag);
        return authToken;
      }
      Logger.error('$_tag: Missing auth token in response', _tag);
      throw Exception('Broadcast auth response missing token');
    }

    switch (response.statusCode) {
      case 401:
        Logger.error(
          '$_tag: Unauthorized (401) while authorizing channel',
          _tag,
        );
        throw Exception('Unauthorized - invalid authentication token');
      case 403:
        Logger.error('$_tag: Forbidden (403) while authorizing channel', _tag);
        throw Exception('Forbidden - no access to channel');
      default:
        final message = response.error ?? 'Unknown error';
        Logger.error('$_tag: Authorization failed - $message', _tag);
        throw Exception('Channel authorization failed: $message');
    }
  }
}
