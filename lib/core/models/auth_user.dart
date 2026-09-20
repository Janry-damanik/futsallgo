class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'pelanggan',
  });

  final String id;
  final String name;
  final String email;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'pelanggan',
    );
  }
}
