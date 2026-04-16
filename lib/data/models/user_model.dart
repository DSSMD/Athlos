class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final DateTime? creadoEn;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.activo = true,
    this.creadoEn,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? 'produccion',
      activo: map['activo'] ?? true,
      creadoEn: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo,
    };
  }

  UserModel copyWith({
    String? nombre,
    String? email,
    String? rol,
    bool? activo,
  }) {
    return UserModel(
      id: id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      creadoEn: creadoEn,
    );
  }
}
