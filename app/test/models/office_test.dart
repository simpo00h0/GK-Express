import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/office.dart';

void main() {
  group('Office Model Tests', () {
    test('Office should be created with required fields', () {
      final office = Office(
        id: 'office-1',
        name: 'Bureau Turquie',
        country: 'Turquie',
        countryCode: 'TR',
      );

      expect(office.id, 'office-1');
      expect(office.name, 'Bureau Turquie');
      expect(office.country, 'Turquie');
      expect(office.countryCode, 'TR');
    });

    test('Office should support optional fields', () {
      final office = Office(
        id: 'office-2',
        name: 'Bureau France',
        country: 'France',
        countryCode: 'FR',
        address: '123 Rue de Paris',
        phone: '+33123456789',
      );

      expect(office.address, '123 Rue de Paris');
      expect(office.phone, '+33123456789');
    });

    test('Office.fromJson should parse JSON correctly', () {
      final json = {
        'id': 'office-3',
        'name': 'Bureau USA',
        'country': 'United States',
        'countryCode': 'US',
        'address': '456 Main St',
        'phone': '+1234567890',
      };

      final office = Office.fromJson(json);

      expect(office.id, 'office-3');
      expect(office.name, 'Bureau USA');
      expect(office.country, 'United States');
      expect(office.countryCode, 'US');
      expect(office.address, '456 Main St');
      expect(office.phone, '+1234567890');
    });

    test('Office.toJson should serialize correctly', () {
      final office = Office(
        id: 'office-4',
        name: 'Bureau Canada',
        country: 'Canada',
        countryCode: 'CA',
        address: '789 Maple Ave',
      );

      final json = office.toJson();

      expect(json['id'], 'office-4');
      expect(json['name'], 'Bureau Canada');
      expect(json['country'], 'Canada');
      expect(json['countryCode'], 'CA');
      expect(json['address'], '789 Maple Ave');
    });

    test('Office flag getter should return correct emoji', () {
      final turkey = Office(
        id: '1',
        name: 'Turkey',
        country: 'Turkey',
        countryCode: 'TR',
      );
      expect(turkey.flag, '🇹🇷');

      final france = Office(
        id: '2',
        name: 'France',
        country: 'France',
        countryCode: 'FR',
      );
      expect(france.flag, '🇫🇷');

      final usa = Office(
        id: '3',
        name: 'USA',
        country: 'USA',
        countryCode: 'US',
      );
      expect(usa.flag, '🇺🇸');

      final canada = Office(
        id: '4',
        name: 'Canada',
        country: 'Canada',
        countryCode: 'CA',
      );
      expect(canada.flag, '🇨🇦');

      final china = Office(
        id: '5',
        name: 'China',
        country: 'China',
        countryCode: 'CN',
      );
      expect(china.flag, '🇨🇳');
    });

    test('Office flag should return default for unknown country code', () {
      final unknown = Office(
        id: '6',
        name: 'Unknown',
        country: 'Unknown',
        countryCode: 'XX',
      );

      expect(unknown.flag, '🌍');
    });

    test('Office with null optional fields should work', () {
      final office = Office(
        id: 'test',
        name: 'Test Office',
        country: 'Test Country',
        countryCode: 'TC',
      );

      expect(office.address, null);
      expect(office.phone, null);
    });
  });
}
