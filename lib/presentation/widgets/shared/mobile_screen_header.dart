// lib/presentation/widgets/shared/mobile_screen_header.dart

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'mobile_notification_avatar.dart';

class MobileScreenHeader extends StatelessWidget {
  const MobileScreenHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showAvatar = true,
    this.trailing,
    this.bottom,
  });

  final String title;
  final bool showBackButton;
  final bool showAvatar;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (showBackButton)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.brandWhite,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Atrás',
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.brandWhite,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                  if (showAvatar) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const MobileNotificationAvatar(),
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: AppSpacing.md),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
