class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'doctor' or 'patient'
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
