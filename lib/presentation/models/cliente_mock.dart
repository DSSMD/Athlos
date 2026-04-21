// ============================================================================
// cliente_mock.dart
// Ubicación: lib/presentation/models/cliente_mock.dart
// Descripción: Modelo temporal para el cliente en modo edición.
// Cubre los datos visibles del mockup de Figma (crear/editar cliente).
// @denshel: reemplazar por ClienteModel real al conectar con Supabase.
// ============================================================================

enum ClienteFormMode {
  crear,
  editar,
}

enum TipoCliente {
  empresa,
  persona,
}

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

class OrdenResumen {
  const OrdenResumen({
    required this.numero,
    required this.total,
    required this.tipoPago,
    required this.estado,
  });

  final String numero; // ej: 'ORD-2847'
  final double total;
  final String tipoPago; // 'Contado' | 'Crédito'
  final String estado; // 'Completada' | 'En proceso' | etc
}

class ClienteMock {
  ClienteMock({
    this.nitCi,
    this.tipoCliente = TipoCliente.empresa,
    this.razonSocial,
    this.representanteLegal,
    this.telefono,
    this.telefonoSecundario,
    this.email,
    this.direccion,
    this.permiteCredito = false,
    this.limiteCredito = 0,
    this.diasPlazoPago = 30,
    this.notas,
    this.clientePrioritario = false,
    this.facturacionElectronica = false,
    // Solo modo editar:
    this.totalComprado = 0,
    this.totalPagado = 0,
    this.deudaActual = 0,
    this.creditoDisponible = 0,
    this.ticketPromedio = 0,
    this.cantidadOrdenes = 0,
    this.clienteDesde,
    this.activo = true,
    this.ultimasOrdenes = const [],
  });

  String? nitCi;
  TipoCliente tipoCliente;
  String? razonSocial;
  String? representanteLegal;
  String? telefono;
  String? telefonoSecundario;
  String? email;
  String? direccion;

  // Órdenes a crédito
  bool permiteCredito;
  double limiteCredito;
  int diasPlazoPago;
  String? notas;

  // Preferencias
  bool clientePrioritario;
  bool facturacionElectronica;

  // Solo visible en modo editar (historial):
  double totalComprado;
  double totalPagado;
  double deudaActual;
  double creditoDisponible;
  double ticketPromedio;
  int cantidadOrdenes;
  DateTime? clienteDesde;
  bool activo;
  List<OrdenResumen> ultimasOrdenes;

  /// Iniciales para el avatar (ej: "ML" para María López)
  String get iniciales {
    final nombre = razonSocial ?? representanteLegal ?? '';
    if (nombre.isEmpty) return '?';
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Nombre corto para mostrar en el panel derecho
  String get nombreCorto {
    return representanteLegal ?? razonSocial ?? 'Sin nombre';
  }
}

/// Cliente de ejemplo para probar el modo "Editar" visualmente,
/// basado en el mockup de Figma.
ClienteMock ejemploClienteMaria() {
  return ClienteMock(
    nitCi: null,
    tipoCliente: TipoCliente.empresa,
    razonSocial: 'Confecciones López S.R.L.',
    representanteLegal: 'María López Gutierrez',
    telefono: '+591 712 345 67',
    telefonoSecundario: null,
    email: 'maria@confeccioneslopez.com',
    direccion: 'Av. Blanco Galindo #1234, Cochabamba',
    permiteCredito: true,
    limiteCredito: 5000.00,
    diasPlazoPago: 30,
    notas:
        'Cliente frecuente desde 2023. Prefiere entregas los viernes. '
        'Descuento del 5% en pedidos mayores a \$2,000.',
    clientePrioritario: true,
    facturacionElectronica: false,
    totalComprado: 28450,
    totalPagado: 28450,
    deudaActual: 0,
    creditoDisponible: 5000,
    ticketPromedio: 1185,
    cantidadOrdenes: 24,
    clienteDesde: DateTime(2023, 1, 15),
    activo: true,
    ultimasOrdenes: const [
      OrdenResumen(numero: 'ORD-2847', total: 1250, tipoPago: 'Contado', estado: 'Completada'),
      OrdenResumen(numero: 'ORD-2835', total: 2800, tipoPago: 'Crédito', estado: 'Completada'),
      OrdenResumen(numero: 'ORD-2820', total: 980, tipoPago: 'Contado', estado: 'Completada'),
    ],
  );
}