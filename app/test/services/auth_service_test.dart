import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthService Tests', () {
    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      await AuthService.logout(); // Clear any existing state
    });

    test('isLoggedIn should return false when no token', () async {
      expect(await AuthService.isLoggedIn(), false);
    });

    test('currentUser should be null initially after logout', () async {
      await AuthService.logout();
      expect(AuthService.currentUser, null);
    });

    test('logout should clear token and user', () async {
      // After logout, everything should be null
      await AuthService.logout();

      expect(AuthService.token, null);
      expect(AuthService.currentUser, null);
      expect(await AuthService.isLoggedIn(), false);
    });

    test('token getter should return null when not logged in', () {
      expect(AuthService.token, null);
    });

    test('isLoggedIn should be consistent with token state', () async {
      final hasToken = AuthService.token != null;
      expect(await AuthService.isLoggedIn(), hasToken);
    });

    test('logout should be idempotent', () async {
      await AuthService.logout();
      await AuthService.logout();

      expect(AuthService.token, null);
      expect(AuthService.currentUser, null);
    });

    test('AuthService should handle multiple logout calls', () async {
      for (int i = 0; i < 5; i++) {
        await AuthService.logout();
      }

      expect(await AuthService.isLoggedIn(), false);
    });
  });
}
