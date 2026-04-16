import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../providers/user_provider.dart';

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUserForm(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contenido
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF0000)),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar usuarios',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(usersProvider.notifier).refresh(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                data: (users) {
                  if (users.isEmpty) {
                    return _buildEmptyState(context, ref);
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 700) {
                        return _buildTable(context, ref, users);
                      } else {
                        return _buildCards(context, ref, users);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ESTADO VACÍO
  // ============================================
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showUserForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Crear primer usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // VISTA TABLA (Desktop)
  // ============================================
  Widget _buildTable(
      BuildContext context, WidgetRef ref, List<UserModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            headingRowColor:
                WidgetStateProperty.all(const Color(0xFFFAFAFA)),
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF737373),
              letterSpacing: 0.3,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF262626),
            ),
            columns: const [
              DataColumn(label: Text('USUARIO')),
              DataColumn(label: Text('EMAIL')),
              DataColumn(label: Text('ROL')),
              DataColumn(label: Text('ESTADO')),
              DataColumn(label: Text('ACCIONES')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  // Nombre con avatar
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAvatar(user.nombre, user.rol),
                        const SizedBox(width: 10),
                        Text(
                          user.nombre.isEmpty ? 'Sin nombre' : user.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Email
                  DataCell(Text(
                    user.email,
                    style: const TextStyle(
                        color: Color(0xFF737373), fontSize: 12),
                  )),
                  // Rol con badge
                  DataCell(_buildRoleBadge(user.rol)),
                  // Toggle activo
                  DataCell(
                    Switch(
                      value: user.activo,
                      activeColor: const Color(0xFFFF0000),
                      onChanged: (value) {
                        ref
                            .read(usersProvider.notifier)
                            .toggleActive(user.id, value);
                      },
                    ),
                  ),
                  // Acciones
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFFFF0000)),
                          tooltip: 'Editar',
                          onPressed: () =>
                              _showUserForm(context, ref, user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFDC2626)),
                          tooltip: 'Eliminar',
                          onPressed: () =>
                              _confirmDelete(context, ref, user),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================
  // VISTA TARJETAS (Mobile)
  // ============================================
  Widget _buildCards(
      BuildContext context, WidgetRef ref, List<UserModel> users) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
          ),
          child: Column(
            children: [
              // Top: avatar + nombre + rol badge
              Row(
                children: [
                  _buildAvatar(user.nombre, user.rol, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nombre.isEmpty ? 'Sin nombre' : user.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF737373),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildRoleBadge(user.rol),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom: toggle + acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: user.activo,
                        activeColor: const Color(0xFFFF0000),
                        onChanged: (value) {
                          ref
                              .read(usersProvider.notifier)
                              .toggleActive(user.id, value);
                        },
                      ),
                      Text(
                        user.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          color: user.activo
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF737373),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showUserForm(context, ref, user: user),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF0000),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // AVATAR CON INICIALES
  // ============================================
  Widget _buildAvatar(String nombre, String rol, {double size = 32}) {
    final initials = nombre.isNotEmpty
        ? nombre
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    final color = _getRoleColor(rol);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }

  // ============================================
  // BADGE DE ROL
  // ============================================
  Widget _buildRoleBadge(String rol) {
    Color bgColor;
    Color textColor;
    String label;

    switch (rol.toLowerCase()) {
      case 'super_admin':
        bgColor = const Color(0xFF0A0A0A);
        textColor = Colors.white;
        label = 'Super Admin';
        break;
      case 'admin':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        label = 'Administrador';
        break;
      case 'produccion':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFF92710C);
        label = 'Producción';
        break;
      case 'ventas':
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF7C3AED);
        label = 'Ventas';
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF737373);
        label = rol;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Color _getRoleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'super_admin':
        return const Color(0xFF0A0A0A);
      case 'admin':
        return const Color(0xFF2563EB);
      case 'produccion':
        return const Color(0xFFEAB308);
      case 'ventas':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF737373);
    }
  }

  // ============================================
  // FORMULARIO CREAR / EDITAR
  // ============================================
  void _showUserForm(BuildContext context, WidgetRef ref,
      {UserModel? user}) {
    final isEditing = user != null;
    final nombreController =
        TextEditingController(text: user?.nombre ?? '');
    final emailController =
        TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    String selectedRol = user?.rol ?? 'produccion';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.person_add,
                color: const Color(0xFFFF0000),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Editar usuario' : 'Nuevo usuario',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  const Text('Nombre completo',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF525252))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nombreController,
                    decoration: _inputDecoration('Ej: Rosa Mamani'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingresa el nombre' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  const Text('Correo electrónico',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF525252))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration('Ej: rosa@athlos.com'),
                    enabled: !isEditing,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa el email';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña (solo al crear)
                  if (!isEditing) ...[
                    const Text('Contraseña',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF525252))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration('Mínimo 6 caracteres'),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa una contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rol (Dropdown)
                  const Text('Rol',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF525252))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedRol,
                    decoration: _inputDecoration(''),
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(
                          value: 'produccion', child: Text('Producción')),
                      DropdownMenuItem(
                          value: 'ventas', child: Text('Ventas')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRol = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF737373))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.of(context).pop();

                try {
                  if (isEditing) {
                    await ref.read(usersProvider.notifier).updateUser(
                          userId: user.id,
                          nombre: nombreController.text.trim(),
                          email: emailController.text.trim(),
                          rol: selectedRol,
                        );
                  } else {
                    await ref.read(usersProvider.notifier).createUser(
                          nombre: nombreController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          rol: selectedRol,
                        );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isEditing ? 'Guardar cambios' : 'Crear usuario'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: Color(0xFFFF0000), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  // ============================================
  // CONFIRMAR ELIMINACIÓN
  // ============================================
  void _confirmDelete(
      BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Estás seguro de eliminar a ${user.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF737373))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final service = ref.read(userServiceProvider);
              await service.deleteUser(user.id);
              ref.read(usersProvider.notifier).refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
