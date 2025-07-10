// Modelo EstadostBD
class EstadostBD {
  String estadoPrincipal;
  String codigo;
  String tipoEstado;
  String categoria;
  String proceso; // Nuevo campo agregado

  EstadostBD({
    required this.estadoPrincipal,
    required this.codigo,
    required this.tipoEstado,
    required this.categoria,
    required this.proceso, // Nuevo campo agregado
  });

  // Convertir de un Map (SQLite) a un objeto `EstadostBD`
  factory EstadostBD.fromMap(Map<String, dynamic> map) {
    return EstadostBD(
      estadoPrincipal: map['estado_principal'],
      codigo: map['codigo'],
      tipoEstado: map['tipo_estado'],
      categoria: map['categoria'],
      proceso: map['proceso'], // Nuevo campo agregado
    );
  }

  // Convertir un objeto `EstadostBD` a un Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'estado_principal': estadoPrincipal,
      'codigo': codigo,
      'tipo_estado': tipoEstado,
      'categoria': categoria,
      'proceso': proceso, // Nuevo campo agregado
    };
  }

  // Convertir de JSON a un objeto `EstadostBD` (desde API)
  factory EstadostBD.fromJson(Map<String, dynamic> json) {
    return EstadostBD(
      estadoPrincipal: json['estado_principal'],
      codigo: json['codigo'],
      tipoEstado: json['tipo_estado'],
      categoria: json['categoria'],
      proceso: json['proceso'], // Nuevo campo agregado
    );
  }
}
