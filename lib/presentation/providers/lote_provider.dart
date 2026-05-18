import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/lote_service.dart';
import '../../domain/models/lote_model.dart';

// 1. Inyectamos el Servicio
final loteServiceProvider = Provider<LoteService>((ref) {
  return LoteService();
});

// 2. Provider que obtiene la lista de lotes
final lotesListProvider = FutureProvider<List<LoteModel>>((ref) async {
  final service = ref.watch(loteServiceProvider);
  return await service.getLotes();
});
