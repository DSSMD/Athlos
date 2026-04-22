// lib/domain/models/usuario_model.dart  

enum UserRole { administrador, produccion, cajas, invitado }

enum UserStatus { activo, inactivo }

class UsuarioModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final DateTime? lastAccess;

  UsuarioModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.lastAccess,
  });

  // Getter que genera la lista hardcodeada según el rol actual
  List<String> get permissions {
    switch (role) {
      case UserRole.administrador:
        return ['Usuarios', 'Inventario', 'Ventas', 'Producción', 'Reportes'];
      case UserRole.produccion:
        return ['Producción', 'Inventario'];
      case UserRole.cajas:
        return ['Caja', 'Ventas', 'Clientes'];
      case UserRole.invitado:
        return ['Consulta', 'Dashboard'];
    }
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rolNombre = json['roles']?['nombre_rol']?.toString() ?? '';
    final bool isActivo = json['activo'] ?? true;
    final String nombre = json['nombre']?.toString() ?? '';
    final String apellido = json['apellido']?.toString() ?? '';
    final String nombreCompleto = '$nombre $apellido'.trim();
    final rawPhone = json['telefono']?.toString();

    return UsuarioModel(
      id: json['id'] as String,
      name: nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto,
      email: json['email'] ?? 'Sin email',
      phone: (rawPhone == null || rawPhone.trim().isEmpty) ? null : rawPhone,
      role: _mapRole(rolNombre),
      status: isActivo ? UserStatus.activo : UserStatus.inactivo,
      lastAccess: json['ultimo_acceso'] != null
          ? DateTime.tryParse(json['ultimo_acceso'].toString())
          : null,
    );
  }

  static UserRole _mapRole(String rolBd) {
    switch (rolBd.toLowerCase().trim()) {
      case 'administrador':
        return UserRole.administrador;
      case 'produccion':
      case 'producción':
        return UserRole.produccion;
      case 'cajas':
        return UserRole.cajas;
      case 'invitado':
      default:
        return UserRole.invitado;
    }
  }
}
