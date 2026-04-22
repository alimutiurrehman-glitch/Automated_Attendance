enum UserRole { admin, instructor }

class UserModel {
  final String userId;
  final String name;
  final String email;
  final UserRole role;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.instructor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'instructor',
    };
  }
}
