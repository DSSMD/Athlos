// ============================================================================
// user_mock.dart
// Ubicación sugerida: lib/presentation/components/user_mock.dart
// Descripción: Modelo TEMPORAL para maquetado visual. Contiene los datos que
// el listado de Usuarios necesita renderizar. NO ES UN MODELO DE DOMINIO.
// @denshel: este archivo se elimina cuando conectes la página a user_model.dart
// real. El mapping debería ser 1:1 con los campos de abajo.
// ============================================================================

/*
import '../../widgets/users/role_badge.dart';
import '../../widgets/users/status_badge.dart';

class UserMock {
  const UserMock({
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    //required this.status,
    required this.lastAccess,
  });

  final String name;
  final String email;
  final UserRole role;
  final List<String> permissions;
  //final UserStatus status;
  final String lastAccess; // ej: "Ahora", "Hace 30 min", "Hoy, 09:15"
}

/// Lista de prueba para poblar el listado y validar overflow con textos largos
/// y listas de permisos extensas (punto 4 del checklist de JIRA).
const List<UserMock> mockUsers = [
  UserMock(
    name: 'Nombre Apellido',
    email: 'np@athlos.com',
    role: UserRole.superAdmin,
    permissions: ['Todo'],
    status: UserStatus.enLinea,
    lastAccess: 'Ahora',
  ),
  UserMock(
    name: 'Jorge Ramirez',
    email: 'jorge@athlos.com',
    role: UserRole.administrador,
    permissions: ['Órdenes', 'Inventario', 'Clientes', 'Pagos', 'Balance'],
    status: UserStatus.enLinea,
    lastAccess: 'Ahora',
  ),
  UserMock(
    name: 'Ana Ticona',
    email: 'ana@athlos.com',
    role: UserRole.administrador,
    permissions: ['Órdenes', 'Clientes', 'Pagos'],
    status: UserStatus.enLinea,
    lastAccess: 'Hace 30 min',
  ),
  UserMock(
    name: 'Rosa Mamani',
    email: 'rosa@athlos.com',
    role: UserRole.produccion,
    permissions: ['Producción', 'Inventario (ver)'],
    status: UserStatus.activo,
    lastAccess: 'Hace 1 hora',
  ),
  UserMock(
    name: 'Juan Poma',
    email: 'juan@athlos.com',
    role: UserRole.produccion,
    permissions: ['Producción', 'Inventario (ver)'],
    status: UserStatus.activo,
    lastAccess: 'Hace 2 horas',
  ),
  UserMock(
    name: 'Luisa Calle',
    email: 'luisa@athlos.com',
    role: UserRole.produccion,
    permissions: ['Producción', 'Inventario (ver)'],
    status: UserStatus.activo,
    lastAccess: 'Hace 3 horas',
  ),
  UserMock(
    name: 'Carmen Flores',
    email: 'carmen@athlos.com',
    role: UserRole.ventas,
    permissions: ['Órdenes', 'Clientes', 'Pagos (ver)'],
    status: UserStatus.activo,
    lastAccess: 'Hoy, 09:15',
  ),
  UserMock(
    name: 'Ricardo Paredes',
    email: 'ricardo@athlos.com',
    role: UserRole.ventas,
    permissions: ['Órdenes', 'Clientes'],
    status: UserStatus.inactivo,
    lastAccess: 'Hace 5 días',
  ),
  // Caso de prueba: nombre y email largos + muchos permisos
  UserMock(
    name: 'Maria Fernanda Gutierrez Villalobos',
    email: 'maria.fernanda.gutierrez@athlos-textiles.com',
    role: UserRole.administrador,
    permissions: [
      'Órdenes', 'Inventario', 'Clientes',
      'Pagos', 'Balance', 'Producción', 'Usuarios',
    ],
    status: UserStatus.activo,
    lastAccess: 'Hace 10 min',
  ),
];

*/