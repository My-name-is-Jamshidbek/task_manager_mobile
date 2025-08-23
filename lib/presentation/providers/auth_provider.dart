import 'package:flutter/foundation.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Initialize provider
  Future<void> initialize() async {
    await _authService.initialize();
    _currentUser = _authService.currentUser;
    _isLoggedIn = _authService.isLoggedIn;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Login with phone and password
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(phone, password);
      
      if (response.isSuccess) {
        // Check if we got a token directly (no SMS verification needed)
        if (response.data?.token != null && response.data?.user != null) {
          _currentUser = response.data!.user;
          _isLoggedIn = true;
          _setLoading(false);
          notifyListeners();
          return true;
        } else {
          // SMS verification required
          _setLoading(false);
          return true;
        }
      } else {
        _setError(response.error);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Verify SMS code
  Future<bool> verifyCode(String phone, String code) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verifyCode(phone, code);
      
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!.user;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.error);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      // Even if logout fails, clear local state
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Get stored phone for SMS verification
  Future<String?> getStoredPhone() async {
    return await _authService.getStoredPhone();
  }

  // Check session validity
  Future<bool> checkSession() async {
    return await _authService.isSessionValid();
  }
}
