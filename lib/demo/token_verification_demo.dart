import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../core/utils/logger.dart';

class TokenVerificationDemo extends StatelessWidget {
  const TokenVerificationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Verification Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authentication Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              authProvider.isLoggedIn 
                                  ? Icons.check_circle 
                                  : Icons.cancel,
                              color: authProvider.isLoggedIn 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              authProvider.isLoggedIn 
                                  ? 'Authenticated' 
                                  : 'Not Authenticated',
                              style: TextStyle(
                                color: authProvider.isLoggedIn 
                                    ? Colors.green 
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (authProvider.currentUser != null) ...[
                          const SizedBox(height: 8),
                          Text('User: ${authProvider.currentUser!.name}'),
                          Text('Phone: ${authProvider.currentUser!.phone}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (authProvider.isLoggedIn) ...[
                  ElevatedButton.icon(
                    onPressed: authProvider.isLoading 
                        ? null 
                        : () => _verifyToken(context, authProvider),
                    icon: authProvider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user),
                    label: Text(authProvider.isLoading 
                        ? 'Verifying...' 
                        : 'Verify Token'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: authProvider.isLoading 
                        ? null 
                        : () => _checkSession(context, authProvider),
                    icon: const Icon(Icons.security),
                    label: const Text('Check Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: authProvider.isLoading 
                        ? null 
                        : () => _logout(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Please login to test token verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Go to Login'),
                  ),
                ],
                
                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error: ${authProvider.error}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _verifyToken(BuildContext context, AuthProvider authProvider) async {
    Logger.info('🧪 TokenVerificationDemo: Starting token verification test');
    
    try {
      final isValid = await authProvider.verifyToken();
      
      if (!context.mounted) return;
      
      final message = isValid 
          ? 'Token is valid and active ✅'
          : 'Token verification failed ❌';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isValid ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      Logger.info('🧪 TokenVerificationDemo: Token verification result: $isValid');
    } catch (e) {
      Logger.error('🧪 TokenVerificationDemo: Token verification error', 'TokenVerificationDemo', e);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Token verification failed')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkSession(BuildContext context, AuthProvider authProvider) async {
    Logger.info('🧪 TokenVerificationDemo: Starting session check test');
    
    try {
      final isValid = await authProvider.checkSession();
      
      if (!context.mounted) return;
      
      final message = isValid 
          ? 'Session is valid ✅'
          : 'Session is invalid ❌';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isValid ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      Logger.info('🧪 TokenVerificationDemo: Session check result: $isValid');
    } catch (e) {
      Logger.error('🧪 TokenVerificationDemo: Session check error', 'TokenVerificationDemo', e);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Session check failed')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    Logger.info('🧪 TokenVerificationDemo: Starting logout test');
    
    try {
      await authProvider.logout();
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Logged out successfully ✅')),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      Logger.info('🧪 TokenVerificationDemo: Logout successful');
    } catch (e) {
      Logger.error('🧪 TokenVerificationDemo: Logout error', 'TokenVerificationDemo', e);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Logout failed')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
