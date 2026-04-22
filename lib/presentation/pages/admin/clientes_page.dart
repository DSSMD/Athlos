import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("Gestión de Clientes"),
          subtitle: const Text("Visualiza y registra los clientes comerciales"),
          trailing: ElevatedButton.icon(
            onPressed: () => context.push('/admin/clientes/nuevo'), 
            icon: const Icon(Icons.add),
            label: const Text("Nuevo Cliente"),
          ),
        ),
        const Expanded(
          child: Center(child: Text("Aquí irá la tabla de clientes")),
        ),
      ],
    );
  }
}