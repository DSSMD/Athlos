import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

Future<void> saveCsvFile({
  required BuildContext context,
  required String fileName,
  required String csvContent,
}) async {
  try {
    // Escribimos con el UTF-8 BOM (\uFEFF) para compatibilidad perfecta con Excel
    final bytes = utf8.encode('\uFEFF' + csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archivo "$fileName" descargado correctamente.'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al exportar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
