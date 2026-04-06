import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/layouts/main_layout.dart'; // Asegúrate de crear este archivo en el paso 2

void main() {
runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athlos Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Montserrat', 
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      // Aquí conectamos tu tema principal con el layout responsivo
      home: const MainLayout(), 
    );
  }
}