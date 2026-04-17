// ============================================================================
// usuarios_page.dart
// Ubicación sugerida: lib/presentation/pages/admin/usuarios_page.dart
// Descripción: Listado de usuarios del panel administrativo.
//
// IMPORTANTE: Esta página NO tiene Scaffold ni AppBar — el MainLayout los
// provee según la arquitectura definida. Solo contiene la UI del contenido.
//
// Esta versión es 100% visual con datos mock (ver components/user_mock.dart).
// NO contiene lógica de Supabase ni Riverpod. @denshel: cuando integres la
// data real, reemplazá `mockUsers` por un ref.watch() de tu user_provider
// y mapeá UserModel → UserMock (o adaptá los componentes si preferís).
//
// Incluye: pestañas Usuarios / Pagos a trabajadores, búsqueda, KPIs por rol,
// filtros por estado, tabla desktop responsive a cards mobile, paginación.
// ============================================================================
import '../components/user_form_drawer.dart';
import 'package:flutter/material.dart';
import '../components/user_card.dart';
import '../components/user_list_row.dart';
import '../components/user_mock.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/kpi_card.dart';
import '../widgets/role_badge.dart';
import '../widgets/search_input.dart';
import '../widgets/status_badge.dart';


class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  // Breakpoint entre desktop y mobile
  static const double _mobileBreakpoint = 900;

  int _selectedTab = 0; // 0 = Usuarios, 1 = Pagos a trabajadores
  int _selectedFilter = 0; // 0 = Todos, 1 = Activos, 2 = Inactivos
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserMock> get _filteredUsers {
    final query = _searchController.text.toLowerCase().trim();
    return mockUsers.where((u) {
      // Filtro por estado
      if (_selectedFilter == 1 && u.status == UserStatus.inactivo) return false;
      if (_selectedFilter == 2 && u.status != UserStatus.inactivo) return false;
      // Filtro por búsqueda
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  }

  int _countByRole(UserRole role) =>
      mockUsers.where((u) => u.role == role).length;

  int _countByFilter(int filter) {
    switch (filter) {
      case 1:
        return mockUsers.where((u) => u.status != UserStatus.inactivo).length;
      case 2:
        return mockUsers.where((u) => u.status == UserStatus.inactivo).length;
      default:
        return mockUsers.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;
        return Align(
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedTab == 0
                ? _buildUsuariosTab(isMobile, key: const ValueKey('usuarios'))
                : _buildPagosTab(isMobile, key: const ValueKey('pagos')),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────── USUARIOS TAB ──

  Widget _buildUsuariosTab(bool isMobile, {Key? key}) {
    final users = _filteredUsers;
    return Column(
      key: key,
      children: [
        // Topbar sticky con línea separadora
        _StickyTopbar(
          isMobile: isMobile,
          searchController: _searchController,
          onSearchChanged: (_) => setState(() {}),
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
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: AppSpacing.xl),
                _KpiRow(
                  isMobile: isMobile,
                  counts: {
                    UserRole.superAdmin: _countByRole(UserRole.superAdmin),
                    UserRole.administrador: _countByRole(UserRole.administrador),
                    UserRole.produccion: _countByRole(UserRole.produccion),
                    UserRole.ventas: _countByRole(UserRole.ventas),
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                _FilterChips(
                  selected: _selectedFilter,
                  counts: [
                    _countByFilter(0),
                    _countByFilter(1),
                    _countByFilter(2),
                  ],
                  onChanged: (i) => setState(() => _selectedFilter = i),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (users.isEmpty)
                  const _EmptyState()
                else if (isMobile)
                  _MobileList(users: users)
                else
                  _DesktopTable(users: users),
                const SizedBox(height: AppSpacing.xl),
                if (isMobile)
                  const _LoadMoreButton()
                else
                  _DesktopPagination(total: users.length, totalAll: mockUsers.length),
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
                      const Icon(Icons.payments_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Pagos a trabajadores',
                        style: AppTypography.h3,
                      ),
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
              Expanded(
                child: Text('Usuarios', style: AppTypography.h1),
              ),
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
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
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
      _kpi(UserRole.superAdmin, 'Super Admin', 'Acceso total al sistema',
          AppColors.neutral950),
      _kpi(UserRole.administrador, 'Administrador', 'Gestión y reportes',
          AppColors.info),
      _kpi(UserRole.produccion, 'Producción', 'Lotes y tareas',
          const Color(0xFFA16207)),
      _kpi(UserRole.ventas, 'Ventas', 'Órdenes y clientes',
          const Color(0xFF7C3AED)),
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
  final List<UserMock> users;

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
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                _col('USUARIO', 3),
                _col('ROL', 2),
                _col('PERMISOS', 3),
                _col('ESTADO', 2),
                _col('ÚLTIMO ACCESO', 2),
                const SizedBox(width: 80),
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
  final List<UserMock> users;

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
// DESKTOP PAGINATION
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopPagination extends StatelessWidget {
  const _DesktopPagination({required this.total, required this.totalAll});
  final int total;
  final int totalAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Mostrando 1-$total de $totalAll registros',
          style: AppTypography.small,
        ),
        const Spacer(),
        _pageBtn('1', selected: true),
        _pageBtn('2'),
        _pageBtn('3'),
        _pageBtn('...'),
        _pageBtn('6'),
      ],
    );
  }

  Widget _pageBtn(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
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
                color: selected
                    ? AppColors.brandWhite
                    : AppColors.textPrimary,
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
// MOBILE "CARGAR MÁS..."
// ══════════════════════════════════════════════════════════════════════════════

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {},
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
          const Icon(Icons.search_off,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text('No se encontraron usuarios',
              style: AppTypography.body
                  .copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Probá con otro término o filtro.',
              style: AppTypography.small),
        ],
      ),
    );
  }
}