class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'boss' or 'agent'
  final String? officeId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.officeId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      officeId: json['officeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'officeId': officeId,
    };
  }

  bool get isBoss => role == 'boss';
  bool get isAgent => role == 'agent';
}
