// lib/presentation/widgets/shared/mobile_notification_avatar.dart
//
// El nombre conserva "notification" por historia — antes este widget pintaba
// un dot rojo sobre el avatar para señalar notificaciones pendientes. Esa
// responsabilidad pasó a NotificationBell
// (widgets/notificaciones/notification_bell.dart). El nombre se mantiene
// para evitar cambios en cascada en los callers; este widget hoy es sólo el
// avatar tappable que abre el menú de perfil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../auth_profile_menu.dart';
import '../user_avatar.dart';

class MobileNotificationAvatar extends ConsumerWidget {
  const MobileNotificationAvatar({super.key});

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
          child: Align(
            alignment: Alignment.center,
            child: UserAvatar(name: nombre, size: 36),
          ),
        ),
      ),
    );
  }
}
