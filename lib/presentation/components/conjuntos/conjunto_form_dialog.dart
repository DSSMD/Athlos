import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import  '../../theme/app_spacing.dart';
import  '../../theme/app_typography.dart';
import '../../../../domain/models/conjunto_model.dart';
import '../../../../domain/models/conjunto_plantilla_model.dart';

class ConjuntoFormDialog extends StatefulWidget {
  final ConjuntoModel? conjunto; // Si viene, es edición. Si no, es creación.
  const ConjuntoFormDialog({super.key, this.conjunto});

  @override
  State<ConjuntoFormDialog> createState() => _ConjuntoFormDialogState();
}

class _ConjuntoFormDialogState extends State<ConjuntoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Lista temporal de plantillas (Local State)
  List<ConjuntoPlantillaModel> _tempPlantillas = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.conjunto != null) {
      _tempPlantillas = List.from(widget.conjunto!.plantillas);
    }
  }

  void _agregarPlantilla() {
    // TODO: Abrir un mini-selector o mostrar dropdown
    // Al seleccionar, se añade a _tempPlantillas y se llama a setState
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conjunto == null ? 'Nuevo Conjunto' : 'Editar Conjunto', style: AppTypography.h3),
                const Divider(),
                
                // Campos básicos
                TextFormField(decoration: const InputDecoration(labelText: 'Nombre del Conjunto')),
                
                const SizedBox(height: AppSpacing.lg),
                Text('SECCIÓN: PLANTILLAS DEL CONJUNTO', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                
                // Botón para agregar a la tabla dinámica
                OutlinedButton.icon(
                  onPressed: _agregarPlantilla,
                  icon: const Icon(Icons.add),
                  label: const Text('Seleccionar Plantilla'),
                ),

                // Tabla Dinámica
                Expanded(
                  child: ListView.builder(
                    itemCount: _tempPlantillas.length,
                    itemBuilder: (context, index) {
                      final item = _tempPlantillas[index];
                      return ListTile(
                        title: Text(item.nombrePlantilla),
                        subtitle: Text('Cantidad: ${item.cantidad}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _tempPlantillas.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                
                // Botones de Acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500),
                      onPressed: _tempPlantillas.isEmpty ? null : () {
                        // TODO: BACKEND - Enviar _tempPlantillas y datos del Form
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar Conjunto', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}