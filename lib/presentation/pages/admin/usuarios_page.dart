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

import '../../components/users/user_form_drawer.dart';
import '../../components/users/user_card.dart';
import '../../components/users/user_list_row.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/users/kpi_card.dart';
import '../../widgets/users/search_input.dart';

import '../../../domain/models/usuario_model.dart';
import '../../providers/usuario_provider.dart';

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  static const double _mobileBreakpoint = 900;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        // 5. MANEJAMOS LOS 3 ESTADOS (Cargando, Error, Datos reales)
        return usuariosAsync.when(
          loading: () => const Center(
            child:
                CircularProgressIndicator(), // Muestra un spinner mientras carga
          ),
          error: (error, stack) =>
              Center(child: Text('Error al cargar usuarios: $error')),
          data: (usuariosReales) {
            // Cuando hay datos, aplicamos tus filtros
            final filteredUsers = _getFilteredUsers(usuariosReales);

            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedTab == 0
                    // NOTA: Tendrás que actualizar _buildUsuariosTab para que acepte
                    // filteredUsers y usuariosReales como parámetros en lugar de usar getters globales
                    ? _buildUsuariosTab(
                        isMobile,
                        filteredUsers,
                        usuariosReales,
                        key: const ValueKey('usuarios'),
                      )
                    : _buildPagosTab(isMobile, key: const ValueKey('pagos')),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────── USUARIOS TAB ──

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
        // Topbar sticky con línea separadora
        _StickyTopbar(
          isMobile: isMobile,
          searchController: _searchController,
          onSearchChanged: (_) => setState(() {
            _currentPage = 1; // 💡 Reiniciamos a pag 1 al buscar
          }),
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
                    _currentPage = 1; // 💡 Reiniciamos al cambiar pestaña
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
                _FilterChips(
                  selected: _selectedFilter,
                  counts: [
                    _countByFilter(allUsers, 0),
                    _countByFilter(allUsers, 1),
                    _countByFilter(allUsers, 2),
                  ],
                  onChanged: (i) => setState(() {
                    _selectedFilter = i;
                    _currentPage = 1; // 💡 Reiniciamos al usar los filtros
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 💡 NUEVO: Pasamos paginatedUsers en lugar de la lista completa
                if (users.isEmpty)
                  const _EmptyState()
                else if (isMobile)
                  _MobileList(users: paginatedUsers)
                else
                  _DesktopTable(users: paginatedUsers),

                const SizedBox(height: AppSpacing.xl),

                // 💡 NUEVO: Llamamos a los widgets con sus nuevas variables
                if (isMobile)
                  _LoadMoreButton(
                    hasMore: _currentPage < totalPages,
                    onPressed: () => setState(() => _currentPage++),
                  )
                else
                  _DesktopPagination(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    totalItems: totalItems,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────── PAGOS TRABAJADORES ──

  Widget _buildPagosTab(bool isMobile, {Key? key}) {
    return Column(
      key: key,
      children: [
        _StickyTopbar(
          isMobile: isMobile,
          searchController: _searchController,
          onSearchChanged: (_) => setState(() {}),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TabSelector(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: AppSpacing.xl3),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl3),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Pagos a trabajadores', style: AppTypography.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Pendiente de diseño en Figma.',
                        style: AppTypography.small,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
// HEADER — título + buscador + botón nuevo
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.isMobile,
    required this.searchController,
    required this.onSearchChanged,
  });

  final bool isMobile;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Usuarios', style: AppTypography.h1)),
              ElevatedButton.icon(
                onPressed: () => showUserFormDrawer(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SearchInput(
            hintText: 'Buscar usuario...',
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      );
    }
    // Desktop
    return Row(
      children: [
        Text('Usuarios', style: AppTypography.h1),
        const Spacer(),
        SizedBox(
          width: 320,
          child: SearchInput(
            hintText: 'Buscar usuario...',
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => showUserFormDrawer(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo usuario'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STICKY TOPBAR — wrapper del header con línea separadora, siempre visible
// ══════════════════════════════════════════════════════════════════════════════

class _StickyTopbar extends StatelessWidget {
  const _StickyTopbar({
    required this.isMobile,
    required this.searchController,
    required this.onSearchChanged,
  });

  final bool isMobile;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xl,
      ),
      child: _Header(
        isMobile: isMobile,
        searchController: searchController,
        onSearchChanged: onSearchChanged,
      ),
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
          label: 'Pagos a trabajadores',
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
// FILTER CHIPS — Todos / Activos / Inactivos
// ══════════════════════════════════════════════════════════════════════════════

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final int selected;
  final List<int> counts;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Todos', 'Activos', 'Inactivos'];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(labels.length, (i) {
        final isSelected = selected == i;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(i),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.primary500 : AppColors.border,
                ),
              ),
              child: Text(
                '${labels[i]} (${counts[i]})',
                style: AppTypography.small.copyWith(
                  color: isSelected
                      ? AppColors.brandWhite
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
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
// DESKTOP PAGINATION — Dinámico
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopPagination extends StatelessWidget {
  const _DesktopPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Si no hay ítems o solo hay 1 página, no mostramos la paginación
    if (totalItems == 0 || totalPages <= 1) return const SizedBox.shrink();

    // Calculamos los números a mostrar (ej. 1-10, 11-20)
    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Row(
      children: [
        Text(
          'Mostrando $startItem-$endItem de $totalItems registros',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
        const Spacer(),
        // Genera los botones numéricos automáticamente según las páginas
        for (int i = 1; i <= totalPages; i++)
          _pageBtn(
            i.toString(),
            selected: currentPage == i,
            onTap: () => onPageChanged(i),
          ),
      ],
    );
  }

  Widget _pageBtn(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary500 : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: AppTypography.small.copyWith(
                color: selected ? AppColors.brandWhite : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE "CARGAR MÁS..." — Dinámico
// ══════════════════════════════════════════════════════════════════════════════

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.hasMore, required this.onPressed});

  final bool hasMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Si ya no hay más páginas, ocultamos el botón
    if (!hasMore) return const SizedBox.shrink();

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          'Cargar más...',
          style: AppTypography.small.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE — cuando filtro/búsqueda no devuelve resultados
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No se encontraron usuarios',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text('Probá con otro término o filtro.', style: AppTypography.small),
        ],
      ),
    );
  }
}
