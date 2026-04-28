class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final TenantModel tenant;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.tenant,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      tenant: TenantModel.fromJson(json['tenant']),
    );
  }
}

class TenantModel {
  final String id;
  final String name;
  final String slug;
  final String status;

  TenantModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      status: json['status'],
    );
  }
}
