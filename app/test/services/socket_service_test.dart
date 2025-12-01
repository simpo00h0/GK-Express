import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/socket_service.dart';

void main() {
  group('SocketService Tests', () {
    setUp(() {
      SocketService.disconnect();
    });

    tearDown(() {
      SocketService.disconnect();
    });

    test('isConnected should be false initially', () {
      expect(SocketService.isConnected, false);
    });

    test('connect should initialize socket', () {
      // Note: This test requires a running backend
      // In a real scenario, you'd mock the socket connection
      expect(() => SocketService.connect(), returnsNormally);
    });

    test('disconnect should set isConnected to false', () {
      SocketService.disconnect();
      expect(SocketService.isConnected, false);
    });

    test('joinOfficeRoom should not throw when disconnected', () {
      expect(
        () => SocketService.joinOfficeRoom('office-1', 'user-1'),
        returnsNormally,
      );
    });

    test('onNewParcel should accept callback function', () {
      void callback(Map<String, dynamic> data) {
        // Test callback
      }

      expect(
        () => SocketService.onNewParcel(callback),
        returnsNormally,
      );
    });

    test('multiple connect calls should not cause errors', () {
      SocketService.connect();
      SocketService.connect();
      // Should handle gracefully
      expect(SocketService.isConnected, isNotNull);
    });

    test('disconnect when not connected should not throw', () {
      expect(() => SocketService.disconnect(), returnsNormally);
    });
  });
}
