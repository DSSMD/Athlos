import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveCsvFile({
  required BuildContext context,
  required String fileName,
  required String csvContent,
}) async {
  try {
    Directory? targetDir;
    
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsPath = '$userProfile\\Downloads';
        final dir = Directory(downloadsPath);
        if (await dir.exists()) {
          targetDir = dir;
        }
      }
    }
    
    // Fallback a documentos del usuario si no estamos en Windows o no hay Downloads
    targetDir ??= await getApplicationDocumentsDirectory();

    final filePath = '${targetDir.path}/$fileName';
    final file = File(filePath);

    // Escribimos con el UTF-8 BOM (\uFEFF) para compatibilidad perfecta con Excel en Windows
    final bytes = utf8.encode('\uFEFF$csvContent');
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportado con éxito en: $filePath'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar el archivo: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
