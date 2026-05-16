import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://txnmhtoczfgjdwdptrfl.supabase.co', 'sb_publishable_hZCE_7ITTUx2teLWHqB25A_j_6VCmoZ');
  try {
    final response = await supabase.from('insumo').select('id_insumo, nombre, activo');
    for (var row in response) {
      print('Insumo: ${row['nombre']} | Activo: ${row['activo']}');
    }
  } catch(e) {
    print('Error: $e');
  }
}
