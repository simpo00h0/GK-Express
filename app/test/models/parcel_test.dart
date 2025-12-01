import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/parcel.dart';

void main() {
  group('Parcel Model Tests', () {
    test('Parcel should be created with all required fields', () {
      final parcel = Parcel(
        id: 'test-123',
        senderName: 'John Doe',
        senderPhone: '+1234567890',
        receiverName: 'Jane Smith',
        receiverPhone: '+0987654321',
        destination: 'Paris',
        status: ParcelStatus.created,
        createdAt: DateTime(2024, 1, 1),
        price: 50.0,
        isPaid: true,
      );

      expect(parcel.id, 'test-123');
      expect(parcel.senderName, 'John Doe');
      expect(parcel.receiverName, 'Jane Smith');
      expect(parcel.status, ParcelStatus.created);
      expect(parcel.price, 50.0);
      expect(parcel.isPaid, true);
    });

    test('Parcel should be created with optional office IDs', () {
      final parcel = Parcel(
        id: 'test-123',
        senderName: 'John',
        senderPhone: '123',
        receiverName: 'Jane',
        receiverPhone: '456',
        destination: 'Paris',
        status: ParcelStatus.inTransit,
        createdAt: DateTime.now(),
        price: 100.0,
        isPaid: false,
        originOfficeId: 'office-1',
        destinationOfficeId: 'office-2',
        paidAtOfficeId: 'office-1',
      );

      expect(parcel.originOfficeId, 'office-1');
      expect(parcel.destinationOfficeId, 'office-2');
      expect(parcel.paidAtOfficeId, 'office-1');
    });

    test('Parcel.fromJson should parse JSON correctly', () {
      final json = {
        'id': 'parcel-456',
        'senderName': 'Alice',
        'senderPhone': '+111',
        'receiverName': 'Bob',
        'receiverPhone': '+222',
        'destination': 'London',
        'status': 'inTransit',
        'createdAt': '2024-01-15T10:30:00.000Z',
        'price': 75.5,
        'isPaid': true,
        'originOfficeId': 'office-a',
        'destinationOfficeId': 'office-b',
        'paidAtOfficeId': 'office-a',
      };

      final parcel = Parcel.fromJson(json);

      expect(parcel.id, 'parcel-456');
      expect(parcel.senderName, 'Alice');
      expect(parcel.receiverName, 'Bob');
      expect(parcel.destination, 'London');
      expect(parcel.status, ParcelStatus.inTransit);
      expect(parcel.price, 75.5);
      expect(parcel.isPaid, true);
      expect(parcel.originOfficeId, 'office-a');
      expect(parcel.destinationOfficeId, 'office-b');
    });

    test('Parcel.toJson should serialize correctly', () {
      final parcel = Parcel(
        id: 'test-789',
        senderName: 'Charlie',
        senderPhone: '+333',
        receiverName: 'Diana',
        receiverPhone: '+444',
        destination: 'Berlin',
        status: ParcelStatus.delivered,
        createdAt: DateTime(2024, 2, 1, 12, 0),
        price: 120.0,
        isPaid: false,
        originOfficeId: 'office-x',
        destinationOfficeId: 'office-y',
      );

      final json = parcel.toJson();

      expect(json['id'], 'test-789');
      expect(json['senderName'], 'Charlie');
      expect(json['receiverName'], 'Diana');
      expect(json['destination'], 'Berlin');
      expect(json['status'], 'delivered');
      expect(json['price'], 120.0);
      expect(json['isPaid'], false);
      expect(json['originOfficeId'], 'office-x');
      expect(json['destinationOfficeId'], 'office-y');
    });

    test('ParcelStatus enum should have all statuses', () {
      expect(ParcelStatus.values.length, 5);
      expect(ParcelStatus.values, contains(ParcelStatus.created));
      expect(ParcelStatus.values, contains(ParcelStatus.inTransit));
      expect(ParcelStatus.values, contains(ParcelStatus.arrived));
      expect(ParcelStatus.values, contains(ParcelStatus.delivered));
      expect(ParcelStatus.values, contains(ParcelStatus.issue));
    });

    test('Parcel status should convert from string correctly', () {
      final createdParcel = Parcel.fromJson({
        'id': '1',
        'senderName': 'A',
        'senderPhone': '1',
        'receiverName': 'B',
        'receiverPhone': '2',
        'destination': 'C',
        'status': 'created',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'price': 0,
        'isPaid': false,
      });

      expect(createdParcel.status, ParcelStatus.created);
    });

    test('Parcel with null optional fields should work', () {
      final parcel = Parcel(
        id: 'test',
        senderName: 'Test',
        senderPhone: '123',
        receiverName: 'Test2',
        receiverPhone: '456',
        destination: 'Test City',
        status: ParcelStatus.created,
        createdAt: DateTime.now(),
        price: 0,
        isPaid: false,
      );

      expect(parcel.originOfficeId, null);
      expect(parcel.destinationOfficeId, null);
      expect(parcel.paidAtOfficeId, null);
    });
  });
}
