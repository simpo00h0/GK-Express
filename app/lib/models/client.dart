class Client {
  final String phone;
  final String name;
  final int totalParcels;
  final int paidAtSending; // Nombre de colis payés à l'envoi
  final int paidAtReception; // Nombre de colis payés à la réception
  final int unpaid; // Nombre de colis non payés
  final double totalAmount;
  final double paidAmount;
  final List<ClientReceiver> receivers;
  final DateTime lastActivity;

  Client({
    required this.phone,
    required this.name,
    required this.totalParcels,
    required this.paidAtSending,
    required this.paidAtReception,
    required this.unpaid,
    required this.totalAmount,
    required this.paidAmount,
    required this.receivers,
    required this.lastActivity,
  });

  double get unpaidAmount => totalAmount - paidAmount;
  double get paymentRate => totalParcels > 0 ? (paidAtSending + paidAtReception) / totalParcels * 100 : 0;
}

class ClientReceiver {
  final String name;
  final String phone;
  final int parcelCount;
  final double totalAmount;

  ClientReceiver({
    required this.name,
    required this.phone,
    required this.parcelCount,
    required this.totalAmount,
  });
}

