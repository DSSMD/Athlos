// lib/core/utils/app_validators.dart

class AppValidators {
  static String? validarRequerido(String? value, String nombreCampo) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $nombreCampo es obligatorio';
    }
    return null;
  }

  static String? validarCI(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Si decides que sea opcional
    
    final ciLimpio = value.trim();
    if (ciLimpio.length < 5) {
      return 'Debe tener al menos 5 caracteres';
    }
    // Permite letras, números y guiones (para los TEMP- o extensiones LP)
    final regex = RegExp(r'^[0-9A-Za-z -]+$');
    if (!regex.hasMatch(ciLimpio)) {
      return 'Formato inválido';
    }
    return null;
  }

  static String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Es opcional
    
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? validarLimiteCredito(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un límite';
    }
    final monto = double.tryParse(value.trim());
    if (monto == null) return 'Debe ser un número';
    if (monto < 0) return 'No puede ser negativo';
    if (monto > 500000) return 'Máximo permitido Bs. 500,000';
    return null;
  }

  static String? validarDiasPlazo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa los días';
    final dias = int.tryParse(value.trim());
    if (dias == null) return 'Debe ser un número entero';
    if (dias <= 0) return 'Debe ser mayor a 0';
    return null;
  }
}