class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? tenantName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.tenantName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Mapping based on your Next.js response structure
    final userData = json['user'];
    return UserModel(
      id: userData['id'],
      name: userData['name'],
      email: userData['email'],
      role: userData['role'],
      tenantName: userData['tenant']?['name'],
    );
  }
}
