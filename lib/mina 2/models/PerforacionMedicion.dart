class DetallePerforacionMedicion {
  final String labor;
  final int cantRegis;
  final double kgExplo;
  final double avance;
  final double ancho;
  final double alto;

  DetallePerforacionMedicion({
    required this.labor,
    required this.cantRegis,
    required this.kgExplo,
    required this.avance,
    required this.ancho,
    required this.alto,
  });

  Map<String, dynamic> toJson() {
    return {
      'labor': labor,
      'cant_regis': cantRegis,
      'kg_explo': kgExplo,
      'avance': avance,
      'ancho': ancho,
      'alto': alto,
    };
  }
}

class PerforacionMedicion {
  final String mes;
  final String semana;
  final String tipoPerforacion;
  final int envio;
  final List<DetallePerforacionMedicion> detalles;

  PerforacionMedicion({
    required this.mes,
    required this.semana,
    required this.tipoPerforacion,
    this.envio = 0,
    required this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      'mes': mes,
      'semana': semana,
      'tipo_perforacion': tipoPerforacion,
      'envio': envio,
      'detalles': detalles.map((d) => d.toJson()).toList(),
    };
  }
}
