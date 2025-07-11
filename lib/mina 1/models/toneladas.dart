class Toneladas {
  int? id;
  String fecha;
  String? turno;
  String zona;
  String tipo;
  String labor;
  double toneladas;

  Toneladas({
    this.id,
    required this.fecha,
    this.turno,
    required this.zona,
    required this.tipo,
    required this.labor,
    required this.toneladas,
  });

  // Convertir de JSON a Objeto
  factory Toneladas.fromJson(Map<String, dynamic> json) {
    return Toneladas(
      id: json['id'],
      fecha: json['fecha'],
      turno: json['turno'],
      zona: json['zona'],
      tipo: json['tipo'],
      labor: json['labor'],
      toneladas: (json['toneladas'] is int)
          ? (json['toneladas'] as int).toDouble()
          : json['toneladas'], // para manejar int o double
    );
  }

  // Convertir de Objeto a Map (para BD o API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'turno': turno,
      'zona': zona,
      'tipo': tipo,
      'labor': labor,
      'toneladas': toneladas,
    };
  }
}
