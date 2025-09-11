// Test to trace the complete login flow
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🔍 TRACING LOGIN FLOW ISSUE...\n');

  // Simulate user's current state - no tokens stored
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  print('📱 INITIAL STATE (app restart):');
  print('All keys: ${prefs.getKeys()}');
  print('Token: ${prefs.getString('auth_token')}');
  print('User: ${prefs.getString('auth_user')}');
  print('Phone: ${prefs.getString('auth_phone')}');
  print('');

  // Simulate what happens when user clicks login button
  print('🚀 USER CLICKS LOGIN...');
  print('1. Login API call happens (phone + password)');
  print('2. Login returns success = true');
  print('3. Phone number gets stored for verification');

  // This is what happens in AuthService.login()
  await prefs.setString('auth_phone', '+998901234567');
  print('✅ Phone stored: ${prefs.getString('auth_phone')}');
  print('');

  print('📱 USER SEES SMS VERIFICATION SCREEN');
  print('⚠️ AT THIS POINT: No tokens stored yet!');
  print('Token: ${prefs.getString('auth_token')}');
  print('User: ${prefs.getString('auth_user')}');
  print('');

  print('🤔 WHAT MIGHT HAPPEN NEXT:');
  print('Option A: User enters SMS code → tokens get stored ✅');
  print('Option B: User exits app → NO tokens stored ❌');
  print('Option C: SMS verification fails → NO tokens stored ❌');
  print('Option D: User never reaches SMS screen → NO tokens stored ❌');
  print('');

  // Check if user exits at this point
  print('❌ IF USER EXITS NOW (before SMS verification):');
  print('On app restart: No tokens found → Login screen shows');
  print('This matches your reported behavior!');
  print('');

  // Now simulate successful SMS verification
  print('✅ IF USER COMPLETES SMS VERIFICATION:');
  final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
  final mockUser = '{"id":1,"name":"Test User","phone":"+998901234567"}';

  await prefs.setString('auth_token', mockToken);
  await prefs.setString('auth_user', mockUser);

  print('Token stored: ${prefs.getString('auth_token')?.substring(0, 20)}...');
  print('User stored: ${prefs.getString('auth_user')}');
  print('');

  print('📊 ANALYSIS:');
  print('The login flow requires TWO steps:');
  print('1. Login with phone/password → stores phone only');
  print('2. SMS verification → stores token and user');
  print('');
  print('🔍 CONCLUSION:');
  print('Users are probably NOT completing SMS verification!');
  print('They see login success, then exit before entering SMS code.');
}
