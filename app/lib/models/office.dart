class Office {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String? address;
  final String? phone;

  Office({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    this.address,
    this.phone,
  });

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      countryCode: json['countryCode'],
      address: json['address'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'countryCode': countryCode,
      'address': address,
      'phone': phone,
    };
  }

  String get flag {
    switch (countryCode) {
      case 'TR':
        return '🇹🇷';
      case 'FR':
        return '🇫🇷';
      case 'US':
        return '🇺🇸';
      case 'CA':
        return '🇨🇦';
      case 'CN':
        return '🇨🇳';
      default:
        return '🌍';
    }
  }
}
