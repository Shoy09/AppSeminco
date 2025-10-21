class OperadorAcero {
  int? id;
  String operador;
  bool activo;
  String? turno;

  OperadorAcero({
    this.id,
    required this.operador,
    required this.activo,
    this.turno,
  });

  // Convertir de JSON a Objeto
  factory OperadorAcero.fromJson(Map<String, dynamic> json) {
    return OperadorAcero(
      id: json['id'],
      operador: json['operador'],
      activo: json['activo'] == 1 || json['activo'] == true,
      turno: json['turno'],
    );
  }

  // Convertir de Objeto a Map (para BD local)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operador': operador,
      'activo': activo ? 1 : 0, // Convertir boolean a int para SQLite
      'turno': turno,
    };
  }

  // Para enviar a la API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'operador': operador,
      'activo': activo,
      'turno': turno,
    };
  }
}