class OrigenDestino {
  int? id;
  String operacion;
  String tipo;
  String nombre;

  OrigenDestino({
    this.id,
    required this.operacion,
    required this.tipo,
    required this.nombre,
  });

  // Convertir de JSON a Objeto
  factory OrigenDestino.fromJson(Map<String, dynamic> json) {
    return OrigenDestino(
      id: json['id'],
      operacion: json['operacion'] ?? 'CARGUÍO', // valor por defecto
      tipo: json['tipo'],
      nombre: json['nombre'],
    );
  }

  // Convertir de Objeto a Map (para enviar a API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operacion': operacion,
      'tipo': tipo,
      'nombre': nombre,
    };
  }
}
