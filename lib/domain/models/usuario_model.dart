// lib/domain/models/usuario_model.dart

// Este modelo representa a un usuario del sistema, incluyendo tanto su información básica

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

  // TODO (Permisos): Agregar campo "final List<String> permisosPersonales;" 
  // para leer los permisos guardados en la base de datos (requerirá nueva columna en Supabase).

  // ══════════════════════════════════════════════════════════════════════════
  // CAMPOS: DATOS DE TRABAJADOR (Recursos Humanos)
  // ══════════════════════════════════════════════════════════════════════════
  final String? idTrabajador;
  final int? idArea;
  final String? nombreArea;
  final double? tarifaPagoBase;
  final DateTime? fechaContratacion;

  UsuarioModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.lastAccess,

    this.idTrabajador,
    this.idArea,
    this.nombreArea,
    this.tarifaPagoBase,
    this.fechaContratacion,
  });

  // 💡 Getter útil para saber rápidamente si este usuario es de producción/trabajador
  bool get isTrabajador => idTrabajador != null;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rolNombre = json['roles']?['nombre_rol']?.toString() ?? '';
    final bool isActivo = json['activo'] ?? true;
    final String nombre = json['nombre']?.toString() ?? '';
    final String apellido = json['apellido']?.toString() ?? '';
    final String nombreCompleto = '$nombre $apellido'.trim();
    final rawPhone = json['telefono']?.toString();

    // ════════════════════════════════════════════════════════════════════════
    // EXTRACCIÓN DE DATOS DEL TRABAJADOR (Si existen)
    // Como la consulta principal será a "profiles", Supabase devolverá
    // la relación "trabajadores" como una lista (array) de objetos.
    // ════════════════════════════════════════════════════════════════════════
    String? tId;
    int? aId;
    String? aNombre;
    double? tTarifa;
    DateTime? tFecha;

    final trabajadoresData = json['trabajadores'];
    if (trabajadoresData != null && trabajadoresData is List && trabajadoresData.isNotEmpty) {
      final trabajador = trabajadoresData.first; // Tomamos el registro asociado
      
      tId = trabajador['id_trabajador']?.toString();
      tTarifa = trabajador['tarifa_pago_base'] != null 
          ? (trabajador['tarifa_pago_base'] as num).toDouble() 
          : null;
      tFecha = trabajador['fecha_contratacion'] != null 
          ? DateTime.tryParse(trabajador['fecha_contratacion'].toString()) 
          : null;

      aId = trabajador['id_area'] != null 
          ? int.tryParse(trabajador['id_area'].toString()) 
          : null;

      // Solo extraemos el nombre de la relación
      final areaData = trabajador['area_produccion'];
      if (areaData != null) {
        aNombre = areaData['nombre_area']?.toString();
      }
    }

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
      
      // Asignamos los datos del trabajador (serán null si no era trabajador)
      idTrabajador: tId,
      idArea: aId,
      nombreArea: aNombre,
      tarifaPagoBase: tTarifa,
      fechaContratacion: tFecha,
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

extension UserRolePermissions on UserRole {
    List<String> get defaultPermissions {
      switch (this) {
        case UserRole.administrador:
          return [
            'Usuarios',
            'Inventario',
            'Ventas',
            'Producción',
            'Reportes',
            'Caja',
            'Clientes',
            'Consulta',
            'Dashboard'
          ]; // Todos los permisos posibles
        case UserRole.produccion:
          return ['Producción', 'Inventario'];
        case UserRole.cajas:
          return ['Caja', 'Ventas', 'Clientes'];
        case UserRole.invitado:
          return ['Consulta', 'Dashboard'];
      }
    }
  }