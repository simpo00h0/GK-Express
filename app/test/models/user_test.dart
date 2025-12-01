import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('User should be created with all required fields', () {
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        fullName: 'John Doe',
        role: 'agent',
        officeId: 'office-1',
      );

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'John Doe');
      expect(user.role, 'agent');
      expect(user.officeId, 'office-1');
    });

    test('User.fromJson should parse JSON correctly', () {
      final json = {
        'id': 'user-456',
        'email': 'boss@example.com',
        'fullName': 'Jane Smith',
        'role': 'boss',
        'officeId': 'office-2',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-456');
      expect(user.email, 'boss@example.com');
      expect(user.fullName, 'Jane Smith');
      expect(user.role, 'boss');
      expect(user.officeId, 'office-2');
    });

    test('User.toJson should serialize correctly', () {
      final user = User(
        id: 'user-789',
        email: 'agent@example.com',
        fullName: 'Alice Johnson',
        role: 'agent',
        officeId: 'office-3',
      );

      final json = user.toJson();

      expect(json['id'], 'user-789');
      expect(json['email'], 'agent@example.com');
      expect(json['fullName'], 'Alice Johnson');
      expect(json['role'], 'agent');
      expect(json['officeId'], 'office-3');
    });

    test('User role should be either agent or boss', () {
      final agent = User(
        id: '1',
        email: 'a@test.com',
        fullName: 'Agent',
        role: 'agent',
        officeId: 'o1',
      );

      final boss = User(
        id: '2',
        email: 'b@test.com',
        fullName: 'Boss',
        role: 'boss',
        officeId: 'o2',
      );

      expect(agent.role, 'agent');
      expect(boss.role, 'boss');
    });

    test('User email should be valid format', () {
      final user = User(
        id: '1',
        email: 'valid.email@domain.com',
        fullName: 'Test User',
        role: 'agent',
        officeId: 'office-1',
      );

      expect(user.email.contains('@'), true);
      expect(user.email.contains('.'), true);
    });
  });
}
