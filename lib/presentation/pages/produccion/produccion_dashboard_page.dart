// lib/presentation/pages/produccion/produccion_dashboard_page.dart

import 'package:flutter/material.dart';

class ProduccionDashboardPage extends StatelessWidget {
  const ProduccionDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚨 NOTA: ¡Ya no usamos Scaffold ni AppBar aquí!
    // Solo devolvemos el contenido que irá en el centro de la pantalla.
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Taller', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),
          // Aquí pondrías tus tarjetas de resumen, gráficos, etc.
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: const [
                Card(child: Center(child: Text('Órdenes Pendientes: 12'))),
                Card(child: Center(child: Text('Telas Agotadas: 3'))),
              ],
            ),
          )
        ],
      ),
    );
  }
}