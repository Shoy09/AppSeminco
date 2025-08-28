// Modelo SubEstadoBD
class SubEstadoBD {
  int id;
  String codigo;
  String tipoEstado;
  int estadoId; // Relación con el estado principal

  SubEstadoBD({
    required this.id,
    required this.codigo,
    required this.tipoEstado,
    required this.estadoId,
  });

  // Convertir de Map (SQLite) a objeto
  factory SubEstadoBD.fromMap(Map<String, dynamic> map) {
    return SubEstadoBD(
      id: map['id'],
      codigo: map['codigo'],
      tipoEstado: map['tipo_estado'],
      estadoId: map['estadoId'],
    );
  }

  // Convertir a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'tipo_estado': tipoEstado,
      'estadoId': estadoId,
    };
  }

  // Convertir de JSON (desde API)
  factory SubEstadoBD.fromJson(Map<String, dynamic> json) {
    return SubEstadoBD(
      id: json['id'],
      codigo: json['codigo'],
      tipoEstado: json['tipo_estado'],
      estadoId: json['estadoId'],
    );
  }
}

// Modelo EstadoBD
class EstadostBD {
  int id;
  String estadoPrincipal;
  String codigo;
  String tipoEstado;
  String categoria;
  String proceso;
  List<SubEstadoBD>? subEstados; // Relación opcional

  EstadostBD({
    required this.id,
    required this.estadoPrincipal,
    required this.codigo,
    required this.tipoEstado,
    required this.categoria,
    required this.proceso,
    this.subEstados,
  });

  // Convertir de Map (SQLite)
  factory EstadostBD.fromMap(Map<String, dynamic> map) {
    return EstadostBD(
      id: map['id'],
      estadoPrincipal: map['estado_principal'],
      codigo: map['codigo'],
      tipoEstado: map['tipo_estado'],
      categoria: map['categoria'],
      proceso: map['proceso'],
    );
  }

  // Convertir a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estado_principal': estadoPrincipal,
      'codigo': codigo,
      'tipo_estado': tipoEstado,
      'categoria': categoria,
      'proceso': proceso,
    };
  }

  // Convertir de JSON (desde API)
  factory EstadostBD.fromJson(Map<String, dynamic> json) {
    return EstadostBD(
      id: json['id'],
      estadoPrincipal: json['estado_principal'],
      codigo: json['codigo'],
      tipoEstado: json['tipo_estado'],
      categoria: json['categoria'],
      proceso: json['proceso'],
      subEstados: json['subEstados'] != null
          ? (json['subEstados'] as List)
              .map((s) => SubEstadoBD.fromJson(s))
              .toList()
          : [],
    );
  }
}
