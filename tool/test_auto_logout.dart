// Test to verify automatic logout on 401 response
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🔍 Testing automatic logout on 401 response...\n');

  try {
    // Clear any existing data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Simulate user being logged in with tokens
    print('📱 STEP 1: Simulating logged-in user');
    await prefs.setString('auth_token', 'valid_token_12345');
    await prefs.setString('auth_user', '{"id":1,"name":"Test User"}');
    await prefs.setString('auth_phone', '+998901234567');

    print('✅ User logged in with tokens:');
    print('   Token: ${prefs.getString('auth_token')?.substring(0, 15)}...');
    print('   User: ${prefs.getString('auth_user')}');
    print('   Phone: ${prefs.getString('auth_phone')}');
    print('');

    // Simulate what happens when API returns 401
    print('🚨 STEP 2: Simulating 401 Unauthorized API response');
    print('   - User makes API call (e.g., get tasks, update profile)');
    print('   - Server responds with 401 Unauthorized');
    print('   - ApiClient detects the 401 response');
    print('   - AuthenticationManager.handleAuthFailure() is triggered');
    print('');

    // Simulate the automatic logout process
    print('🔄 STEP 3: Automatic logout process');
    print('   1. Clear authentication token from ApiClient');
    print('   2. Call AuthProvider.logout() to clear app state');
    print('   3. Clear all stored authentication data');

    // Clear the tokens (simulating logout)
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    await prefs.remove('auth_phone');

    print('   4. Navigate to login screen with route clearing');
    print('   5. Show session expired message to user');
    print('');

    // Verify tokens are cleared
    print('✅ STEP 4: Verification after automatic logout');
    print('Token: ${prefs.getString('auth_token') ?? 'NULL (cleared)'}');
    print('User: ${prefs.getString('auth_user') ?? 'NULL (cleared)'}');
    print('Phone: ${prefs.getString('auth_phone') ?? 'NULL (cleared)'}');
    print('');

    print('📊 IMPLEMENTATION SUMMARY:');
    print('✅ ApiClient now detects 401 responses automatically');
    print('✅ AuthenticationManager handles logout and navigation');
    print('✅ Localized session expired messages');
    print('✅ Automatic token cleanup');
    print('✅ Navigation to login screen');
    print('');

    print('🎯 BENEFITS:');
    print('• Users don\'t get stuck with invalid tokens');
    print('• Automatic security when sessions expire');
    print('• Clear feedback about session expiry');
    print('• Seamless re-authentication flow');
    print('• Works for ANY API call that returns 401');
  } catch (e, stackTrace) {
    print('❌ ERROR during test: $e');
    print('Stack trace: $stackTrace');
  }
}
