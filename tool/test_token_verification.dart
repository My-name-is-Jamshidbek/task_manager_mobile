import 'package:flutter/material.dart';
import '../lib/core/utils/logger.dart';
import '../lib/data/services/auth_service.dart';
import '../lib/presentation/providers/auth_provider.dart';

/// Test token verification with POST method fix
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.enable();
  Logger.info('🧪 Testing token verification with POST method');

  try {
    await testTokenVerificationFlow();
    Logger.info('✅ Token verification test completed');
  } catch (e, stackTrace) {
    Logger.error('❌ Test failed', 'TokenVerifyTest', e, stackTrace);
  }
}

/// Test the token verification after mock login
Future<void> testTokenVerificationFlow() async {
  Logger.info('🧪 Testing token verification flow...');

  // Step 1: Initialize services
  final authService = AuthService();
  final authProvider = AuthProvider();

  await authService.initialize();
  await authProvider.initialize();

  // Step 2: Simulate successful verification (which stores tokens)
  Logger.info('📱 Simulating SMS verification (which stores tokens)...');
  final testPhone = '+998901234567';
  final testCode = '123456';

  final verifySuccess = await authProvider.verifyCode(testPhone, testCode);
  Logger.info('🔍 Verification result: $verifySuccess');
  Logger.info('🔍 AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}');

  if (!verifySuccess) {
    Logger.error(
      '❌ SMS verification failed, cannot test token verification',
      'TokenVerifyTest',
    );
    return;
  }

  // Step 3: Test token verification directly
  Logger.info('🔐 Testing token verification with server...');
  final tokenValid = await authProvider.verifyToken();
  Logger.info('🔍 Token verification result: $tokenValid');
  Logger.info(
    '🔍 After verification - AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}',
  );

  // Step 4: Test session check
  Logger.info('🔍 Testing session validity check...');
  final sessionValid = await authProvider.checkSession();
  Logger.info('🔍 Session check result: $sessionValid');
  Logger.info(
    '🔍 After session check - AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}',
  );
}
