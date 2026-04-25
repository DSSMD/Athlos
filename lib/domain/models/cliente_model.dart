// lib/domain/models/cliente_model.dart

/// Representa los tipos de cliente normalizados en la base de datos.
enum TipoCliente { empresa, persona }

enum ClienteFormMode { crear, editar }

extension TipoClienteLabel on TipoCliente {
  String get label {
    switch (this) {
      case TipoCliente.empresa:
        return 'Empresa';
      case TipoCliente.persona:
        return 'Persona';
    }
  }
}

class ClienteModel {
  final String? idCliente;
  final String ciCliente;
  final String nomCliente;
  final String apellidoCliente;
  final String? razonSocial; // Nuevo: para empresas
  final String? email; // Nuevo
  final String? numTelefono;
  final String? numTelefono2; // Nuevo: teléfono secundario
  final String? direccion;
  final int idTipoCliente; // Normalizado: 1 para Empresa, 2 para Persona

  // Lógica de Crédito
  final bool permiteCredito;
  final double limiteCredito;
  final int diasPlazoPago;

  // Preferencias y Estado
  final bool esPrioritario;
  final String? notas;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClienteModel({
    this.idCliente,
    required this.ciCliente,
    required this.nomCliente,
    required this.apellidoCliente,
    this.razonSocial,
    this.email,
    this.numTelefono,
    this.numTelefono2,
    this.direccion,
    this.idTipoCliente = 2, // Por defecto Persona
    this.permiteCredito = false,
    this.limiteCredito = 0.0,
    this.diasPlazoPago = 30,
    this.esPrioritario = false,
    this.notas,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Convierte el entero de la BD al Enum de Flutter para facilitar la lógica de UI
  TipoCliente get tipoEnum =>
      idTipoCliente == 1 ? TipoCliente.empresa : TipoCliente.persona;

  /// Retorna el nombre que debe verse en listas (Razón Social si es empresa, Nombre si es persona)
  String get nombreMostrable {
    if (tipoEnum == TipoCliente.empresa &&
        razonSocial != null &&
        razonSocial!.isNotEmpty) {
      return razonSocial!;
    }
    return '$nomCliente $apellidoCliente';
  }

  /// Genera iniciales para el Avatar (ej: "ML" para María López)
  String get iniciales {
    final base = (tipoEnum == TipoCliente.empresa && razonSocial != null)
        ? razonSocial!
        : nomCliente;
    if (base.isEmpty) return '?';
    return base[0].toUpperCase();
  }

  // ────────────── MAPEO DE DATOS (JSON) ─────────────────────────

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      idCliente: json['id_cliente'],
      ciCliente: json['ci_cliente'] ?? '',
      nomCliente: json['nom_cliente'] ?? '',
      apellidoCliente: json['apellido_cliente'] ?? '',
      razonSocial: json['razon_social'],
      email: json['email'],
      numTelefono: json['num_telefono'],
      numTelefono2: json['num_telefono_2'],
      direccion: json['direccion'],
      idTipoCliente: json['id_tipo_cliente'] ?? 2,
      permiteCredito: json['permite_credito'] ?? false,
      limiteCredito: (json['limite_credito'] ?? 0).toDouble(),
      diasPlazoPago: json['dias_plazo_pago'] ?? 30,
      esPrioritario: json['es_prioritario'] ?? false,
      notas: json['notas'],
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  String? get nitCi => null;

  Map<String, dynamic> toJson() {
    return {
      if (idCliente != null) 'id_cliente': idCliente,
      'ci_cliente': ciCliente,
      'nom_cliente': nomCliente,
      'apellido_cliente': apellidoCliente,
      'razon_social': razonSocial,
      'email': email,
      'num_telefono': numTelefono,
      'num_telefono_2': numTelefono2,
      'direccion': direccion,
      'id_tipo_cliente': idTipoCliente,
      'permite_credito': permiteCredito,
      'limite_credito': limiteCredito,
      'dias_plazo_pago': diasPlazoPago,
      'es_prioritario': esPrioritario,
      'notas': notas,
      'activo': activo,
    };
  }
}
