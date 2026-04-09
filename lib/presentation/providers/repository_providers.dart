import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/tela_repository.dart';
import '../../data/repositories/tela_repository_impl.dart';

// Proveedor global del cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Proveedor del Repositorio de Telas
final telaRepositoryProvider = Provider<TelaRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return TelaRepositoryImpl(supabaseClient);
});