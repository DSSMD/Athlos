import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AthlosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AthlosAppBar({super.key, this.title = 'Athlos Workspace'});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}