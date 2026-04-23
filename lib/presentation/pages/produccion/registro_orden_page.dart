import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/orden_form_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegistroOrdenPage extends ConsumerWidget {
  const RegistroOrdenPage({super.key});

  // CA 1: Cargar imagen desde galería o cámara
  Future<void> _seleccionarImagen(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      ref.read(ordenFormProvider.notifier).updateImagePath(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos los cambios de estado en tiempo real
    final formState = ref.watch(ordenFormProvider);
    final formNotifier = ref.read(ordenFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Orden')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector de Cliente (UUID manual por ahora)
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'ID del Cliente (UUID de Supabase)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              onChanged: (val) =>
                  ref.read(ordenFormProvider.notifier).updateIdCliente(val),
            ),
            const SizedBox(height: 20),

            // 2. Selector de Fecha de Entrega
            ListTile(
              title: const Text('Fecha de Entrega Pactada'),
              subtitle: Text(
                formState.fechaEntrega == null
                    ? 'Presione para seleccionar'
                    : '${formState.fechaEntrega!.day}/${formState.fechaEntrega!.month}/${formState.fechaEntrega!.year}',
              ),
              leading: const Icon(Icons.calendar_month),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  ref.read(ordenFormProvider.notifier).updateFechaEntrega(date);
                }
              },
            ),
            const SizedBox(height: 20),

            // CA 2: Nombre del modelo
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nombre del Modelo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checkroom),
              ),
              onChanged: formNotifier.updateNombreModelo,
            ),
            const SizedBox(height: 24),

            // Selector de Imagen
            InkWell(
              onTap: () => _seleccionarImagen(ref),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: formState.imagePath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tocar para adjuntar foto (Obligatorio)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                formState.imagePath!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(formState.imagePath!),
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Desglose de Tallas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // CA 2: Matriz de Tallas generada dinámicamente
            ...formState.tallas.keys.map((talla) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        talla,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final cantidad = int.tryParse(val) ?? 0;
                          formNotifier.updateCantidadTalla(talla, cantidad);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 48),

            // CA 3: Visor del Total Automático
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: formState.totalPrendas > 0
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total de Prendas:',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${formState.totalPrendas}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: formState.totalPrendas > 0
                          ? Colors.green.shade700
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // CA 4: Botón de guardado con validación estricta
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                // Si formState.esValido es falso, onPressed es null y el botón se deshabilita
                onPressed: formState.esValido
                    ? () => formNotifier.guardarOrden()
                    : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Registrar Orden en Sistema',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
