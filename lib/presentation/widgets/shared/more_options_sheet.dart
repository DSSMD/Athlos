// lib/presentation/widgets/shared/more_options_sheet.dart

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Opción en la sheet "Más" del bottom navigation.
class MoreOption {
  const MoreOption({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.description,
    required this.originalIndex,
  });

  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String description;
  final int originalIndex;
}

/// Muestra un bottom sheet con opciones secundarias del bottom nav.
/// Cuando el usuario selecciona una, [onSelected] recibe el `originalIndex`
/// del item para que el caller actualice el estado de navegación.
Future<void> showMoreOptionsSheet({
  required BuildContext context,
  required List<MoreOption> options,
  required ValueChanged<int> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Más opciones',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ...options.map(
              (opt) => _MoreOptionCard(
                option: opt,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(opt.originalIndex);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
}

class _MoreOptionCard extends StatelessWidget {
  const _MoreOptionCard({required this.option, required this.onTap});

  final MoreOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.iconBgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(option.icon, color: option.iconBgColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(option.description, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
