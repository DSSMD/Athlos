import '../../data/models/tela_model.dart';

abstract class TelaRepository {
  Future<List<TelaModel>> getTelas();
}