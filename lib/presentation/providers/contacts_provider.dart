import 'package:flutter/foundation.dart';
import '../../data/models/contact.dart';
import '../../data/models/find_or_create_conversation_response.dart';
import '../../data/services/contacts_api_service.dart';
import '../../core/utils/logger.dart';

class ContactsProvider extends ChangeNotifier {
  final ContactsApiService _apiService;

  // State variables
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;
  String _currentSearch = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Find or create conversation state
  bool _isCreatingConversation = false;
  String? _createConversationError;

  ContactsProvider({ContactsApiService? apiService})
    : _apiService = apiService ?? ContactsApiService();

  // Getters
  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentSearch => _currentSearch;
  int get currentPage => _currentPage;
  bool get hasMoreData => _hasMoreData;
  bool get isCreatingConversation => _isCreatingConversation;
  String? get createConversationError => _createConversationError;

  /// Load contacts from API
  Future<void> loadContacts({String? search, bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      // If it's a new search or refresh, reset pagination
      if (search != _currentSearch || refresh) {
        _currentSearch = search ?? '';
        _currentPage = 1;
        _hasMoreData = true;
        if (refresh) _contacts.clear();
      }

      Logger.info(
        '🔄 Loading contacts - search: $_currentSearch, page: $_currentPage',
      );

      final response = await _apiService.getContacts(
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
        page: _currentPage,
      );

      if (_currentPage == 1) {
        _contacts = response.data;
      } else {
        _contacts.addAll(response.data);
      }

      // Check if there's more data based on response
      _hasMoreData =
          response.data.isNotEmpty &&
          response.data.length >= 20; // Assuming 20 per page

      Logger.info(
        '✅ Loaded ${response.data.length} contacts, total: ${_contacts.length}',
      );
    } catch (e) {
      Logger.error('❌ Failed to load contacts', 'ContactsProvider', e);
      _setError(e.toString().replaceAll('ContactsApiException: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  /// Load more contacts (pagination)
  Future<void> loadMoreContacts() async {
    if (_isLoading || !_hasMoreData) return;

    _currentPage++;
    await loadContacts();
  }

  /// Search contacts
  Future<void> searchContacts(String query) async {
    if (_currentSearch == query) return;

    _currentSearch = query;
    _currentPage = 1;
    _hasMoreData = true;
    _contacts.clear();

    await loadContacts(search: query);
  }

  /// Clear search and load all contacts
  Future<void> clearSearch() async {
    if (_currentSearch.isEmpty) return;

    _currentSearch = '';
    _currentPage = 1;
    _hasMoreData = true;
    _contacts.clear();

    await loadContacts();
  }

  /// Refresh contacts list
  Future<void> refreshContacts() async {
    await loadContacts(refresh: true);
  }

  /// Get contact by ID
  Contact? getContactById(int id) {
    try {
      return _contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Find or create a direct conversation with a contact
  Future<FindOrCreateConversationResponse?> findOrCreateConversation(
    int partnerId,
  ) async {
    if (_isCreatingConversation) return null;

    _isCreatingConversation = true;
    _createConversationError = null;
    notifyListeners();

    try {
      Logger.info(
        '💬 Finding or creating conversation with partner ID: $partnerId',
      );

      final conversationResponse = await _apiService.findOrCreateConversation(
        partnerId,
      );

      Logger.info(
        '✅ Conversation found/created successfully: ${conversationResponse.id}',
      );
      return conversationResponse;
    } catch (e) {
      _createConversationError = e.toString();
      Logger.error(
        '❌ Failed to find/create conversation',
        'ContactsProvider',
        e,
      );
      return null;
    } finally {
      _isCreatingConversation = false;
      notifyListeners();
    }
  }

  /// Filter contacts locally
  List<Contact> filterContacts(String query) {
    if (query.isEmpty) return _contacts;

    final lowercaseQuery = query.toLowerCase();
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowercaseQuery) ||
          contact.phone.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
