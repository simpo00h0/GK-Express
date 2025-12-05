class ParcelStatusHistory {
  final String id;
  final String parcelId;
  final String? oldStatus;
  final String newStatus;
  final String? changedByUserId;
  final String changedByUserName;
  final String? changedByUserEmail;
  final String? officeId;
  final String? officeName;
  final String? officeCountry;
  final String? notes;
  final DateTime changedAt;

  ParcelStatusHistory({
    required this.id,
    required this.parcelId,
    this.oldStatus,
    required this.newStatus,
    this.changedByUserId,
    required this.changedByUserName,
    this.changedByUserEmail,
    this.officeId,
    this.officeName,
    this.officeCountry,
    this.notes,
    required this.changedAt,
  });

  factory ParcelStatusHistory.fromJson(Map<String, dynamic> json) {
    return ParcelStatusHistory(
      id: json['id'],
      parcelId: json['parcelId'],
      oldStatus: json['oldStatus'],
      newStatus: json['newStatus'],
      changedByUserId: json['changedByUserId'],
      changedByUserName: json['changedByUserName'] ?? 'Utilisateur inconnu',
      changedByUserEmail: json['changedByUserEmail'],
      officeId: json['officeId'],
      officeName: json['officeName'],
      officeCountry: json['officeCountry'],
      notes: json['notes'],
      changedAt: DateTime.parse(json['changedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcelId': parcelId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'changedByUserId': changedByUserId,
      'changedByUserName': changedByUserName,
      'changedByUserEmail': changedByUserEmail,
      'officeId': officeId,
      'officeName': officeName,
      'officeCountry': officeCountry,
      'notes': notes,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  // Get status label in French
  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return 'Créé';
      case 'intransit':
        return 'En Transit';
      case 'arrived':
        return 'Arrivé';
      case 'delivered':
        return 'Livré';
      case 'issue':
        return 'Problème';
      default:
        return status;
    }
  }

  // Get status emoji
  String getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return '🆕';
      case 'intransit':
        return '🚚';
      case 'arrived':
        return '📍';
      case 'delivered':
        return '✅';
      case 'issue':
        return '⚠️';
      default:
        return '📦';
    }
  }
}

