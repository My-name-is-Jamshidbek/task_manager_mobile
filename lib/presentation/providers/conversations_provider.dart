import 'package:flutter/foundation.dart';
import '../../data/models/conversation.dart';
import '../../data/services/conversations_api_service.dart';
import '../../core/utils/logger.dart';

class ConversationsProvider extends ChangeNotifier {
  final ConversationsApiService _apiService;

  ConversationsProvider({ConversationsApiService? apiService})
    : _apiService = apiService ?? ConversationsApiService();

  // Direct conversations state
  List<Conversation> _directConversations = [];
  bool _isLoadingDirect = false;
  String? _directError;
  ConversationsMeta? _directMeta;
  int _directCurrentPage = 1;

  // Department conversations state
  List<Conversation> _departmentConversations = [];
  bool _isLoadingDepartment = false;
  String? _departmentError;
  ConversationsMeta? _departmentMeta;
  int _departmentCurrentPage = 1;

  // Combined conversations state
  List<Conversation> _allConversations = [];
  bool _isLoadingAll = false;
  String? _allError;

  // Getters for direct conversations
  List<Conversation> get directConversations => _directConversations;
  bool get isLoadingDirect => _isLoadingDirect;
  String? get directError => _directError;
  ConversationsMeta? get directMeta => _directMeta;
  bool get canLoadMoreDirect => _directMeta?.hasMorePages ?? false;

  // Getters for department conversations
  List<Conversation> get departmentConversations => _departmentConversations;
  bool get isLoadingDepartment => _isLoadingDepartment;
  String? get departmentError => _departmentError;
  ConversationsMeta? get departmentMeta => _departmentMeta;
  bool get canLoadMoreDepartment => _departmentMeta?.hasMorePages ?? false;

  // Getters for all conversations
  List<Conversation> get allConversations => _allConversations;
  bool get isLoadingAll => _isLoadingAll;
  String? get allError => _allError;

  /// Load direct conversations (first page)
  Future<void> loadDirectConversations() async {
    if (_isLoadingDirect) return;

    _isLoadingDirect = true;
    _directError = null;
    _directCurrentPage = 1;
    notifyListeners();

    try {
      Logger.info('📋 Loading direct conversations...');

      final response = await _apiService.getDirectConversations(
        page: _directCurrentPage,
      );

      _directConversations = response.data;
      _directMeta = response.meta;

      Logger.info(
        '✅ Loaded ${_directConversations.length} direct conversations',
      );
    } catch (e) {
      _directError = e.toString();
      Logger.error(
        '❌ Failed to load direct conversations',
        'ConversationsProvider',
        e,
      );
    } finally {
      _isLoadingDirect = false;
      notifyListeners();
    }
  }

  /// Load more direct conversations (next page)
  Future<void> loadMoreDirectConversations() async {
    if (_isLoadingDirect || !canLoadMoreDirect) return;

    _isLoadingDirect = true;
    notifyListeners();

    try {
      _directCurrentPage++;

      final response = await _apiService.getDirectConversations(
        page: _directCurrentPage,
      );

      _directConversations.addAll(response.data);
      _directMeta = response.meta;

      Logger.info('✅ Loaded ${response.data.length} more direct conversations');
    } catch (e) {
      _directCurrentPage--; // Revert page increment on error
      _directError = e.toString();
      Logger.error(
        '❌ Failed to load more direct conversations',
        'ConversationsProvider',
        e,
      );
    } finally {
      _isLoadingDirect = false;
      notifyListeners();
    }
  }

  /// Load department conversations (first page)
  Future<void> loadDepartmentConversations() async {
    if (_isLoadingDepartment) return;

    _isLoadingDepartment = true;
    _departmentError = null;
    _departmentCurrentPage = 1;
    notifyListeners();

    try {
      Logger.info('📋 Loading department conversations...');

      final response = await _apiService.getDepartmentConversations(
        page: _departmentCurrentPage,
      );

      _departmentConversations = response.data;
      _departmentMeta = response.meta;

      Logger.info(
        '✅ Loaded ${_departmentConversations.length} department conversations',
      );
    } catch (e) {
      _departmentError = e.toString();
      Logger.error(
        '❌ Failed to load department conversations',
        'ConversationsProvider',
        e,
      );
    } finally {
      _isLoadingDepartment = false;
      notifyListeners();
    }
  }

  /// Load more department conversations (next page)
  Future<void> loadMoreDepartmentConversations() async {
    if (_isLoadingDepartment || !canLoadMoreDepartment) return;

    _isLoadingDepartment = true;
    notifyListeners();

    try {
      _departmentCurrentPage++;

      final response = await _apiService.getDepartmentConversations(
        page: _departmentCurrentPage,
      );

      _departmentConversations.addAll(response.data);
      _departmentMeta = response.meta;

      Logger.info(
        '✅ Loaded ${response.data.length} more department conversations',
      );
    } catch (e) {
      _departmentCurrentPage--; // Revert page increment on error
      _departmentError = e.toString();
      Logger.error(
        '❌ Failed to load more department conversations',
        'ConversationsProvider',
        e,
      );
    } finally {
      _isLoadingDepartment = false;
      notifyListeners();
    }
  }

  /// Load all conversations (combines direct and department)
  Future<void> loadAllConversations() async {
    if (_isLoadingAll) return;

    _isLoadingAll = true;
    _allError = null;
    notifyListeners();

    try {
      Logger.info('📋 Loading all conversations...');

      final conversations = await _apiService.getAllConversations();

      _allConversations = conversations;

      Logger.info('✅ Loaded ${_allConversations.length} total conversations');
    } catch (e) {
      _allError = e.toString();
      Logger.error(
        '❌ Failed to load all conversations',
        'ConversationsProvider',
        e,
      );
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  /// Refresh all conversations
  Future<void> refreshAllConversations() async {
    _directCurrentPage = 1;
    _departmentCurrentPage = 1;

    await loadAllConversations();
  }

  /// Clear all error states
  void clearErrors() {
    _directError = null;
    _departmentError = null;
    _allError = null;
    notifyListeners();
  }

  /// Reset all state (useful for logout)
  void reset() {
    _directConversations.clear();
    _departmentConversations.clear();
    _allConversations.clear();

    _isLoadingDirect = false;
    _isLoadingDepartment = false;
    _isLoadingAll = false;

    _directError = null;
    _departmentError = null;
    _allError = null;

    _directMeta = null;
    _departmentMeta = null;

    _directCurrentPage = 1;
    _departmentCurrentPage = 1;

    notifyListeners();
  }

  /// Get conversation by ID
  Conversation? getConversationById(String id) {
    try {
      return _allConversations.firstWhere((conv) => conv.id.toString() == id);
    } catch (e) {
      return null;
    }
  }

  /// Get unread conversations count
  int get unreadConversationsCount {
    return _allConversations.where((conv) => conv.unreadCount > 0).length;
  }

  /// Get total unread messages count
  int get totalUnreadMessagesCount {
    return _allConversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
