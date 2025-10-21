class JefeGuardiaAcero {
  int? id;
  String jefeDeGuardia;
  bool activo;
  String? turno;

  JefeGuardiaAcero({
    this.id,
    required this.jefeDeGuardia,
    required this.activo,
    this.turno,
  });

  // Convertir de JSON a Objeto
  factory JefeGuardiaAcero.fromJson(Map<String, dynamic> json) {
    return JefeGuardiaAcero(
      id: json['id'],
      jefeDeGuardia: json['jefe_de_guardia'],
      activo: json['activo'] == 1 || json['activo'] == true,
      turno: json['turno'],
    );
  }

  // Convertir de Objeto a Map (para BD local)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jefe_de_guardia': jefeDeGuardia,
      'activo': activo ? 1 : 0, // Convertir boolean a int para SQLite
      'turno': turno,
    };
  }

  // Para enviar a la API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'jefe_de_guardia': jefeDeGuardia,
      'activo': activo,
      'turno': turno,
    };
  }
}