// lib/presentation/pages/admin/usuarios_page.dart

// Página principal de gestión de usuarios para el admin. Contiene:
// - Header con título, buscador y botón de nuevo usuario
// - KPI cards con conteos por rol
// - Filtros por estado (todos/activos/inactivos)
// - Listado de usuarios en formato tabla (desktop) o cards (mobile)
// - Paginación (desktop) o botón "Cargar más" (mobile)
// El diseño es responsive y se adapta a diferentes tamaños de pantalla, siguiendo el estilo de Athlos.
// NOTA: Este código asume que ya tienes implementados los modelos, servicios y proveedores necesarios para manejar los datos reales de usuarios desde Supabase.
// Las funciones de filtrado y conteo se basan en esos datos reales, y el estado de carga/error se maneja con Riverpod.
// ============================================================================
// IMPORTANTE: Este código es un ejemplo completo y funcional de la página de usuarios,
// pero necesitarás adaptar algunos detalles para que encaje con tu estructura actual de modelos, servicios y proveedores.
// Asegúrate de tener implementados los métodos necesarios en tu UsuarioService para obtener los datos reales desde Supabase,
// y de que tu UsuarioModel tenga las propiedades correctas (name, email, role, status, etc.) para que los filtros y conteos funcionen correctamente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/export_helper.dart';
import '../../components/users/user_form_drawer.dart';
import '../../components/users/user_card.dart';
import '../../components/users/user_list_row.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';

import '../../widgets/users/kpi_card.dart';
import '../../widgets/shared/compact_new_button.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/filter_chips.dart';
import '../../widgets/shared/mobile_screen_header.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/search_input.dart';
import '../../widgets/shared/sticky_topbar.dart';

import '../../../domain/models/usuario_model.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/pago_provider.dart'; // 💰 Saldos de trabajadores
import '../../../domain/models/pago_trabajador_model.dart'; // ResumenPagoProduccionModel
import '../../components/produccion/pago_trabajador_dialog.dart'; // Diálogo de pago

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  int _selectedTab = 0;
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportarUsuarios(List<UsuarioModel> allUsers) {
    if (allUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuarios para exportar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    // Semicolon is the default delimiter in Spanish regional settings so Excel opens it correctly
    buffer.writeln('ID;Nombre;Email;Rol;Estado;Trabajador');

    for (final u in allUsers) {
      final id = u.id;
      final nombre = u.name.replaceAll(';', ',');
      final email = u.email.replaceAll(';', ',');
      
      String rol = 'Invitado';
      switch (u.role) {
        case UserRole.administrador:
          rol = 'Administrador';
          break;
        case UserRole.produccion:
          rol = 'Producción';
          break;
        case UserRole.cajas:
          rol = 'Cajas';
          break;
        case UserRole.invitado:
          rol = 'Invitado';
          break;
      }

      final estado = u.status == UserStatus.activo ? 'Activo' : 'Inactivo';
      final esTrabajador = u.isTrabajador ? 'Sí' : 'No';

      buffer.writeln('$id;$nombre;$email;$rol;$estado;$esTrabajador');
    }

    final String csvContent = buffer.toString();
    final String timestamp = DateTime.now().toIso8601String().substring(0, 10);
    saveCsvFile(
      context: context,
      fileName: 'Usuarios_Athlos_$timestamp.csv',
      csvContent: csvContent,
    );
  }

  void _exportarTrabajadores(List<UsuarioModel> allUsers) {
    final trabajadores = allUsers.where((u) => u.isTrabajador).toList();
    if (trabajadores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay trabajadores para exportar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID;Nombre;Email;Rol;Estado');

    for (final t in trabajadores) {
      final id = t.id;
      final nombre = t.name.replaceAll(';', ',');
      final email = t.email.replaceAll(';', ',');
      
      String rol = 'Invitado';
      switch (t.role) {
        case UserRole.administrador:
          rol = 'Administrador';
          break;
        case UserRole.produccion:
          rol = 'Producción';
          break;
        case UserRole.cajas:
          rol = 'Cajas';
          break;
        case UserRole.invitado:
          rol = 'Invitado';
          break;
      }

      final estado = t.status == UserStatus.activo ? 'Activo' : 'Inactivo';

      buffer.writeln('$id;$nombre;$email;$rol;$estado');
    }

    final String csvContent = buffer.toString();
    final String timestamp = DateTime.now().toIso8601String().substring(0, 10);
    saveCsvFile(
      context: context,
      fileName: 'Trabajadores_Athlos_$timestamp.csv',
      csvContent: csvContent,
    );
  }

  // 3. ADAPTAMOS TUS FUNCIONES PARA QUE RECIBAN LA LISTA REAL EN LUGAR DE mockUsers
  List<UsuarioModel> _getFilteredUsers(List<UsuarioModel> allUsers) {
    final query = _searchController.text.toLowerCase().trim();
    return allUsers.where((u) {
      // Filtro por estado
      if (_selectedFilter == 1 && u.status == UserStatus.inactivo) return false;
      if (_selectedFilter == 2 && u.status != UserStatus.inactivo) return false;
      // Filtro por búsqueda
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  }

  int _countByRole(List<UsuarioModel> allUsers, UserRole role) =>
      allUsers.where((u) => u.role == role).length;

  int _countByFilter(List<UsuarioModel> allUsers, int filter) {
    switch (filter) {
      case 1:
        return allUsers.where((u) => u.status != UserStatus.inactivo).length;
      case 2:
        return allUsers.where((u) => u.status == UserStatus.inactivo).length;
      default:
        return allUsers.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. ¡AQUÍ ESTÁ LA MAGIA DE RIVERPOD! Escuchamos a Supabase
    final usuariosAsync = ref.watch(usuariosProvider);

    // Migrated to AppBreakpoints.mobile (1100). Was previously: 900.
    final isMobile = context.isMobile;

    return usuariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error al cargar usuarios: $error')),
      data: (usuariosReales) {
        final filteredUsers = _getFilteredUsers(usuariosReales);

        return Align(
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedTab == 0
                ? _buildUsuariosTab(
                    isMobile,
                    filteredUsers,
                    usuariosReales,
                    key: const ValueKey('usuarios'),
                  )
                // AÑADE EL ARGUMENTO FALTANTE AQUÍ (ejemplo: usuariosReales o filteredUsers)
                : _buildPagosTab(
                    isMobile,
                    usuariosReales, // <--- Aquí pasas el segundo argumento posicional
                    key: const ValueKey('pagos'),
                  ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCIONES DE FILTRADO Y CONTEO
  // ─────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────── USUARIOS ──

  Widget _buildUsuariosTab(
    bool isMobile,
    List<UsuarioModel> filteredUsers,
    List<UsuarioModel> allUsers, {
    Key? key,
  }) {
    // Usamos los usuarios que ya vienen filtrados desde el método build()
    final users = filteredUsers;

    // 💡 NUEVO: Cálculos matemáticos de la paginación
    final totalItems = users.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    // Cortamos la lista dependiendo de si es celular (stack) o PC (10 exactos)
    final paginatedUsers = isMobile
        ? users.take(_currentPage * _itemsPerPage).toList()
        : users
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    return Column(
      key: key,
      children: [
        // Header — mobile usa MobileScreenHeader (con search en bottom),
        // desktop mantiene StickyTopbar.
        if (isMobile)
          MobileScreenHeader(
            title: 'Usuarios',
            trailing: CompactNewButton(
              label: 'Nuevo',
              onPressed: () => showUserFormDrawer(context),
            ),
            bottom: SearchInput(
              hintText: 'Buscar usuario...',
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
            ),
          )
        else
          StickyTopbar(
            title: 'Usuarios',
            searchHint: 'Buscar usuario...',
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {
              _currentPage = 1;
            }),
            newButtonLabelDesktop: 'Nuevo usuario',
            onNewPressed: () => showUserFormDrawer(context),
            newButtonColor: AppColors.primary500,
            newTextColor: Colors.white,
          ),
        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TabSelector(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() {
                    _selectedTab = i;
                    _currentPage = 1;
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                _KpiRow(
                  isMobile: isMobile,
                  counts: {
                    UserRole.administrador: _countByRole(
                      allUsers,
                      UserRole.administrador,
                    ),
                    UserRole.produccion: _countByRole(
                      allUsers,
                      UserRole.produccion,
                    ),
                    UserRole.cajas: _countByRole(allUsers, UserRole.cajas),
                    UserRole.invitado: _countByRole(
                      allUsers,
                      UserRole.invitado,
                    ),
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                if (isMobile) ...[
                  FilterChips(
                    labels: const ['Todos', 'Activos', 'Inactivos'],
                    selected: _selectedFilter,
                    counts: [
                      _countByFilter(allUsers, 0),
                      _countByFilter(allUsers, 1),
                      _countByFilter(allUsers, 2),
                    ],
                    onChanged: (i) => setState(() {
                      _selectedFilter = i;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportarUsuarios(allUsers),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Exportar'),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: FilterChips(
                          labels: const ['Todos', 'Activos', 'Inactivos'],
                          selected: _selectedFilter,
                          counts: [
                            _countByFilter(allUsers, 0),
                            _countByFilter(allUsers, 1),
                            _countByFilter(allUsers, 2),
                          ],
                          onChanged: (i) => setState(() {
                            _selectedFilter = i;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => _exportarUsuarios(allUsers),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: const Text('Exportar'),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),

                if (users.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No se encontraron usuarios',
                    subtitle: 'Probá con otro término o filtro.',
                  )
                else if (isMobile)
                  _MobileList(users: paginatedUsers)
                else
                  _DesktopTable(users: paginatedUsers),

                const SizedBox(height: AppSpacing.xl),

                if (isMobile)
                  LoadMoreButton(
                    hasMore: _currentPage < totalPages,
                    onPressed: () => setState(() => _currentPage++),
                  )
                else
                  DesktopPagination(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    totalItems: totalItems,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    recordsLabel: 'usuarios',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────── PAGOS TRABAJADORES ──

  Widget _buildPagosTab(
    bool isMobile,
    List<UsuarioModel> allUsers, {
    Key? key,
  }) {
    var trabajadores = allUsers.where((u) => u.isTrabajador).toList();

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      trabajadores = trabajadores
          .where((t) => t.name.toLowerCase().contains(query))
          .toList();
    }

    return Column(
      key: key,
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Usuarios',
            trailing: CompactNewButton(
              label: 'Nuevo',
              onPressed: () => showUserFormDrawer(context),
            ),
            bottom: SearchInput(
              hintText: 'Buscar trabajador...',
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
          )
        else
          StickyTopbar(
            title: 'Usuarios',
            searchHint: 'Buscar trabajador...',
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {}),
            newButtonLabelDesktop: 'Nuevo usuario',
            onNewPressed: () => showUserFormDrawer(context),
            newButtonColor: AppColors.primary500,
            newTextColor: Colors.white,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TabSelector(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() {
                    _selectedTab = i;
                    _searchController.clear();
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 💰 Tarjeta de resumen RRHH
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.people_outline,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trabajadores activos',
                              style: AppTypography.small.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '${trabajadores.length}',
                              style: AppTypography.h3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportarTrabajadores(allUsers),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Exportar trabajadores'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 💰 Tabla de saldos de trabajadores (usa la VIEW de Supabase)
                // TODO:(PAGOS) Este bloque requiere que la VIEW vista_pagos_produccion_por_orden
                // esté creada en Supabase. Si no, mostrará error o lista vacía.
                _SaldosTrabajadoresTable(
                  trabajadores: trabajadores,
                  query: query,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB SELECTOR — pestañas Usuarios / Pagos a trabajadores
// ══════════════════════════════════════════════════════════════════════════════

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabPill(
          label: 'Usuarios',
          selected: selected == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: AppSpacing.sm),
        _TabPill(
          label: 'Trabajadores',
          selected: selected == 1,
          onTap: () => onChanged(1),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary500 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: selected ? AppColors.brandWhite : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KPI ROW — 4 tarjetas con conteos por rol
// ══════════════════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.isMobile, required this.counts});

  final bool isMobile;
  final Map<UserRole, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      _kpi(
        UserRole.administrador,
        'Administrador',
        'Acceso total y gestión',
        AppColors.neutral950,
      ),
      _kpi(
        UserRole.produccion,
        'Producción',
        'Lotes y tareas',
        const Color(0xFFA16207),
      ),
      _kpi(
        UserRole.cajas,
        'Cajas',
        'Transacciones y cierre de caja',
        const Color(0xFF7C3AED),
      ),
      _kpi(
        UserRole.invitado,
        'Invitado',
        'Consulta y lectura',
        AppColors.neutral500, // Un gris para los invitados
      ),
    ];

    // MOBILE: grilla 2x2 con altura uniforme (IntrinsicHeight)
    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: items[1]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: items[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: items[3]),
              ],
            ),
          ),
        ],
      );
    }

    // DESKTOP: 4 columnas
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }

  KpiCard _kpi(UserRole role, String label, String desc, Color color) =>
      KpiCard(
        value: '${counts[role] ?? 0}',
        label: label,
        description: desc,
        valueColor: color,
      );
}
// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE — header + filas
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.users});
  final List<UsuarioModel> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _col('USUARIO', 3),
                _col('ROL', 2),
                _col('PERMISOS', 3),
                _col('ESTADO', 2),
                _col('ÚLTIMO ACCESO', 2),
                SizedBox(
                  width: 80,
                  child: Text(
                    'ACCIONES',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filas
          for (var i = 0; i < users.length; i++) ...[
            UserListRow(
              user: users[i],
              onEdit: () => showUserFormDrawer(context, initialUser: users[i]),
            ),
            if (i < users.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _col(String label, int flex) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LIST — stack vertical de cards
// ══════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({required this.users});
  final List<UsuarioModel> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < users.length; i++) ...[
          UserCard(
            user: users[i],
            onTap: () => showUserFormDrawer(context, initialUser: users[i]),
          ),
          if (i < users.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TABLA DE SALDOS DE TRABAJADORES (pestaña Trabajadores)
// Muestra los saldos globales de todos los trabajadores usando la VIEW de Supabase
// ══════════════════════════════════════════════════════════════════════════════

class _SaldosTrabajadoresTable extends ConsumerWidget {
  final List<UsuarioModel> trabajadores;
  final String query;

  const _SaldosTrabajadoresTable({
    required this.trabajadores,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saldosAsync = ref.watch(saldosGlobalesTrabajadoresProvider);

    // Si no hay trabajadores registrados, mostramos estado vacío simple
    if (trabajadores.isEmpty) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No hay trabajadores',
        subtitle: 'Los usuarios con rol de Producción o Cajas aparecerán aquí.',
      );
    }

    return saldosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        // Fallback: si la VIEW no existe aún, mostramos solo la lista de usuarios
        // TODO:(PAGOS) Si ves "relation vista_pagos_produccion_por_orden does not exist",
        // es que no creaste la VIEW en Supabase todavía. Hazlo y este error desaparece.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'La VIEW de saldos no está disponible aún. '
                      'Crea vista_pagos_produccion_por_orden en Supabase.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DesktopTable(users: trabajadores),
          ],
        );
      },
      data: (saldos) {
        // Cruzamos saldos de la VIEW con la lista de trabajadores del provider de usuarios
        // para mostrar solo los que pasaron el filtro de búsqueda
        final idsTrabajadoresFiltrados =
            trabajadores.map((t) => t.idTrabajador).whereType<String>().toSet();

        final saldosFiltrados = saldos
            .where((s) => idsTrabajadoresFiltrados.contains(s.idTrabajador))
            .toList();

        // Si ningún trabajador tiene saldos, mostramos la lista normal
        if (saldosFiltrados.isEmpty) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Ningún trabajador tiene asignaciones con monto acordado aún.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DesktopTable(users: trabajadores),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Header de la tabla
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _th('TRABAJADOR', flex: 3),
                    _th('ÁREA', flex: 2),
                    _th('LOTES', flex: 1),
                    _th('PACTADO', flex: 2),
                    _th('PAGADO', flex: 2),
                    _th('SALDO', flex: 2),
                    _th('ESTADO', flex: 2),
                    const SizedBox(width: 80),
                  ],
                ),
              ),
              // Filas
              for (var i = 0; i < saldosFiltrados.length; i++) ...[
                _SaldoRow(
                  saldo: saldosFiltrados[i],
                  onPagoRegistrado: () =>
                      ref.invalidate(saldosGlobalesTrabajadoresProvider),
                ),
                if (i < saldosFiltrados.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// Fila individual de la tabla de saldos
class _SaldoRow extends StatelessWidget {
  final ResumenPagoProduccionModel saldo;
  final VoidCallback onPagoRegistrado;

  const _SaldoRow({
    required this.saldo,
    required this.onPagoRegistrado,
  });

  @override
  Widget build(BuildContext context) {
    final Color estadoColor = switch (saldo.estadoPagoGlobal) {
      'Liquidado' => const Color(0xFF16A34A),
      'Con Adelantos' => const Color(0xFF2563EB),
      _ => const Color(0xFFD97706),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // TRABAJADOR
          Expanded(
            flex: 3,
            child: Text(
              saldo.trabajadorNombre,
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ÁREA
          Expanded(
            flex: 2,
            child: Text(
              saldo.area,
              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // LOTES
          Expanded(
            flex: 1,
            child: Text(
              '${saldo.lotesAsignados}',
              style: AppTypography.small,
            ),
          ),
          // PACTADO
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${saldo.totalPactado.toStringAsFixed(2)}',
              style: AppTypography.small,
            ),
          ),
          // PAGADO
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${saldo.totalAdelantos.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(
                color: const Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // SALDO
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${saldo.saldoPendiente.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(
                color: saldo.saldoPendiente <= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // ESTADO badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: estadoColor.withOpacity(0.3)),
              ),
              child: Text(
                saldo.estadoPagoGlobal,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: estadoColor,
                ),
              ),
            ),
          ),
          // Botón pagar
          SizedBox(
            width: 80,
            child: saldo.estadoPagoGlobal != 'Liquidado'
                ? TextButton(
                    onPressed: () async {
                      final pagado = await showDialog<bool>(
                        context: context,
                        builder: (_) => PagoTrabajadorDialog(
                          idTrabajador: saldo.idTrabajador,
                          nombreTrabajador: saldo.trabajadorNombre,
                          numOrden: saldo.numOrden,
                          saldoPendiente: saldo.saldoPendiente,
                        ),
                      );
                      if (pagado == true) onPagoRegistrado();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Pagar', style: TextStyle(fontSize: 13)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

