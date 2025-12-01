class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'boss' or 'agent'
  final String? officeId;
  final String? officeName;
  final DateTime? createdAt;
  bool isOnline;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.officeId,
    this.officeName,
    this.createdAt,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      officeId: json['officeId'],
      officeName: json['officeName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'officeId': officeId,
      'officeName': officeName,
      'createdAt': createdAt?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  bool get isBoss => role == 'boss';
  bool get isAgent => role == 'agent';
}
