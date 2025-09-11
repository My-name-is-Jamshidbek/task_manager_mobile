import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 DEBUG: Starting login debug test...');

  // Initialize SharedPreferences for testing
  SharedPreferences.setMockInitialValues({});

  try {
    // Check current storage state BEFORE login
    print('\n📱 ==> BEFORE LOGIN: Checking storage...');
    final prefsBeforeLogin = await SharedPreferences.getInstance();
    await prefsBeforeLogin.reload();

    final keysBeforeLogin = prefsBeforeLogin.getKeys();
    print('🔍 Keys in storage BEFORE login: $keysBeforeLogin');

    final tokenBeforeLogin = prefsBeforeLogin.getString('auth_token');
    final userBeforeLogin = prefsBeforeLogin.getString('auth_user');
    final phoneBeforeLogin = prefsBeforeLogin.getString('auth_phone');

    print('🔑 Token BEFORE login: $tokenBeforeLogin');
    print('👤 User BEFORE login: $userBeforeLogin');
    print('📱 Phone BEFORE login: $phoneBeforeLogin');

    // Simulate login process
    print('\n🚀 ==> SIMULATING LOGIN PROCESS...');

    // Step 1: Simulate phone login (should store phone)
    print('📱 Step 1: Storing phone number...');
    await prefsBeforeLogin.setString('auth_phone', '+998901234567');

    // Step 2: Simulate SMS verification success (should store token and user)
    print('✅ Step 2: Simulating SMS verification success...');
    final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    final mockUser =
        '{"id":1,"name":"Test User","phone":"+998901234567","email":"test@example.com"}';

    await prefsBeforeLogin.setString('auth_token', mockToken);
    await prefsBeforeLogin.setString('auth_user', mockUser);

    print('💾 Token to store: ${mockToken.substring(0, 20)}...');
    print('💾 User to store: $mockUser');

    // Verify storage immediately after setting
    print('\n📱 ==> IMMEDIATELY AFTER LOGIN: Checking storage...');
    await prefsBeforeLogin.reload();

    final keysAfterLogin = prefsBeforeLogin.getKeys();
    print('🔍 Keys in storage AFTER login: $keysAfterLogin');

    final tokenAfterLogin = prefsBeforeLogin.getString('auth_token');
    final userAfterLogin = prefsBeforeLogin.getString('auth_user');
    final phoneAfterLogin = prefsBeforeLogin.getString('auth_phone');

    print(
      '🔑 Token AFTER login: ${tokenAfterLogin != null ? '${tokenAfterLogin.substring(0, 20)}...' : 'NULL'}',
    );
    print(
      '👤 User AFTER login: ${userAfterLogin != null ? 'YES (${userAfterLogin.length} chars)' : 'NULL'}',
    );
    print('📱 Phone AFTER login: $phoneAfterLogin');

    // Simulate app restart by creating a new SharedPreferences instance
    print(
      '\n🔄 ==> SIMULATING APP RESTART: Creating new SharedPreferences instance...',
    );
    SharedPreferences.setMockInitialValues(
      {},
    ); // Clear mock values to simulate restart
    final prefsAfterRestart = await SharedPreferences.getInstance();
    await prefsAfterRestart.reload();

    final keysAfterRestart = prefsAfterRestart.getKeys();
    print('🔍 Keys in storage AFTER RESTART: $keysAfterRestart');

    final tokenAfterRestart = prefsAfterRestart.getString('auth_token');
    final userAfterRestart = prefsAfterRestart.getString('auth_user');
    final phoneAfterRestart = prefsAfterRestart.getString('auth_phone');

    print('🔑 Token AFTER RESTART: $tokenAfterRestart');
    print('👤 User AFTER RESTART: $userAfterRestart');
    print('📱 Phone AFTER RESTART: $phoneAfterRestart');

    // Final analysis
    print('\n📊 ==> ANALYSIS:');

    if (tokenAfterLogin != null && tokenAfterRestart == null) {
      print('❌ ISSUE FOUND: Token was stored but lost after restart!');
      print(
        '   This suggests SharedPreferences is not persisting data properly',
      );
    } else if (tokenAfterLogin == null) {
      print('❌ ISSUE FOUND: Token was never stored in the first place!');
      print('   This suggests an issue in the _storeSession method');
    } else if (tokenAfterRestart != null) {
      print('✅ SUCCESS: Token persisted through restart');
    }
  } catch (e, stackTrace) {
    print('❌ ERROR during debug test: $e');
    print('Stack trace: $stackTrace');
  }
}

// Helper function to bind widgets (mock)
class WidgetsFlutterBinding {
  static void ensureInitialized() {}
}

class ServicesBinding {
  static const MethodChannel defaultBinaryMessenger = MethodChannel('mock');
}
