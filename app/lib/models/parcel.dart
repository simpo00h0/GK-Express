enum ParcelStatus {
  created,
  inTransit,
  arrived,
  delivered,
  issue,
}

class Parcel {
  final String id;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String destination;
  final ParcelStatus status;
  final DateTime createdAt;
  final double price;
  final bool isPaid;
  final String? originOfficeId;
  final String? destinationOfficeId;
  final String? paidAtOfficeId;

  Parcel({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.destination,
    this.status = ParcelStatus.created,
    required this.createdAt,
    this.price = 0.0,
    this.isPaid = false,
    this.originOfficeId,
    this.destinationOfficeId,
    this.paidAtOfficeId,
  });

  // From JSON
  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'],
      senderName: json['senderName'],
      senderPhone: json['senderPhone'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      destination: json['destination'],
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      price: (json['price'] ?? 0).toDouble(),
      isPaid: json['isPaid'] ?? false,
      originOfficeId: json['originOfficeId'],
      destinationOfficeId: json['destinationOfficeId'],
      paidAtOfficeId: json['paidAtOfficeId'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'destination': destination,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'price': price,
      'isPaid': isPaid,
      'originOfficeId': originOfficeId,
      'destinationOfficeId': destinationOfficeId,
      'paidAtOfficeId': paidAtOfficeId,
    };
  }

  static ParcelStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'intransit':
        return ParcelStatus.inTransit;
      case 'arrived':
        return ParcelStatus.arrived;
      case 'delivered':
        return ParcelStatus.delivered;
      case 'issue':
        return ParcelStatus.issue;
      default:
        return ParcelStatus.created;
    }
  }
}
