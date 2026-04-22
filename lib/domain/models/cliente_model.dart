// lib/domain/models/cliente_model.dart

// 1. Modelo de Cliente
// Este modelo representa la estructura de datos de un cliente en nuestro sistema. Se alinea con la tabla 'clientes' en Supabase,
// pero también incluye lógica adicional para manejar campos opcionales y para generar el nombre completo del cliente a partir de su nombre y apellido.
// Además, el modelo incluye métodos para convertir entre JSON y el modelo, lo que facilita su uso tanto para leer datos de la base de datos como para enviar
// nuevos datos a la misma.  

class ClienteModel {
  final String? idCliente; // Opcional al crear
  final String ciCliente;
  final String nomCliente;
  final String apellidoCliente;
  final String? numTelefono;
  final String? direccion;
  final DateTime? createdAt;

  ClienteModel({
    this.idCliente,
    required this.ciCliente,
    required this.nomCliente,
    required this.apellidoCliente,
    this.numTelefono,
    this.direccion,
    this.createdAt,
  });

  // Para leer datos que vienen de Supabase
  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      idCliente: json['id_cliente'],
      ciCliente: json['ci_cliente'],
      nomCliente: json['nom_cliente'],
      apellidoCliente: json['apellido_cliente'],
      numTelefono: json['num_telefono'],
      direccion: json['direccion'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Para enviar datos nuevos a Supabase
  Map<String, dynamic> toJson() {
    return {
      if (idCliente != null) 'id_cliente': idCliente,
      'ci_cliente': ciCliente,
      'nom_cliente': nomCliente,
      'apellido_cliente': apellidoCliente,
      if (numTelefono != null) 'num_telefono': numTelefono,
      if (direccion != null) 'direccion': direccion,
      // No mandamos created_at porque la BD tiene 'default now()'
    };
  }

  String get nombreCompleto => '$nomCliente $apellidoCliente';
}