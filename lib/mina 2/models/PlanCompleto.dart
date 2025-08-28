class PlanCompleto {
  final String zona;
  final String tipoLabor;
  final String labor;
  final String ala;
  final String estructuraVeta;
  final String nivel;

  PlanCompleto({
    required this.zona,
    required this.tipoLabor,
    required this.labor,
    required this.ala,
    required this.estructuraVeta,
    required this.nivel,
  });

  Map<String, dynamic> toMap() {
    return {
      'zona': zona,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'estructura_veta': estructuraVeta,
      'nivel': nivel,
    };
  }
}
