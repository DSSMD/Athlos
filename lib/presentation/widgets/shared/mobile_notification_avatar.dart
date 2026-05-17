// lib/presentation/widgets/shared/mobile_notification_avatar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth_profile_menu.dart';
import '../user_avatar.dart';

class MobileNotificationAvatar extends ConsumerWidget {
  const MobileNotificationAvatar({super.key, this.hasNotifications = true});

  final bool hasNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final nombre = profileAsync.value?['nombre'] ?? 'Usuario';

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showAuthProfileSheet(context, ref),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.center,
                child: UserAvatar(name: nombre, size: 36),
              ),
              if (hasNotifications)
                const Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(child: _NotificationDot()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sidebarDark, width: 2),
      ),
    );
  }
}
