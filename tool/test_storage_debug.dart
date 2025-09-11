// Simple debug script to check login storage
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🔍 Starting login storage debug...');

  try {
    // Get current SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Clear everything first to start fresh
    await prefs.clear();
    print('🧹 Cleared all stored data');

    // Check what keys exist before login
    print('\n📱 BEFORE LOGIN:');
    print('All keys: ${prefs.getKeys()}');
    print('Token: ${prefs.getString('auth_token')}');
    print('User: ${prefs.getString('auth_user')}');
    print('Phone: ${prefs.getString('auth_phone')}');

    // Simulate the login storage process
    print('\n🚀 SIMULATING LOGIN...');

    // Step 1: Store phone (as done in login)
    await prefs.setString('auth_phone', '+998901234567');
    print('✅ Stored phone number');

    // Step 2: Store token and user (as done in SMS verification)
    final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    final mockUser = '{"id":1,"name":"Test User","phone":"+998901234567"}';

    await prefs.setString('auth_token', mockToken);
    await prefs.setString('auth_user', mockUser);
    print('✅ Stored token and user data');

    // Check immediately after storage
    print('\n📱 IMMEDIATELY AFTER LOGIN:');
    print('All keys: ${prefs.getKeys()}');
    print('Token: ${prefs.getString('auth_token')?.substring(0, 20)}...');
    print('User: ${prefs.getString('auth_user')}');
    print('Phone: ${prefs.getString('auth_phone')}');

    // Force reload to simulate what happens in AuthService.initialize()
    await prefs.reload();
    print('\n🔄 AFTER RELOAD (simulates app restart):');
    print('All keys: ${prefs.getKeys()}');
    print('Token: ${prefs.getString('auth_token')}');
    print('User: ${prefs.getString('auth_user')}');
    print('Phone: ${prefs.getString('auth_phone')}');

    if (prefs.getString('auth_token') != null) {
      print('\n✅ SUCCESS: Tokens are persisting correctly!');
      print('The issue must be elsewhere in the login flow.');
    } else {
      print('\n❌ ISSUE: Tokens are not persisting after reload!');
      print('This indicates a SharedPreferences problem.');
    }
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }
}
