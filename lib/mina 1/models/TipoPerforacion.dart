class TipoPerforacion {
  int? id;
  String nombre;
  String? proceso; // Nuevo campo opcional

  TipoPerforacion({this.id, required this.nombre, this.proceso});

  // Convertir de JSON a Objeto
  factory TipoPerforacion.fromJson(Map<String, dynamic> json) {
    return TipoPerforacion(
      id: json['id'],
      nombre: json['nombre'],
      proceso: json['proceso'], // Obtener el valor de `proceso`
    );
  }

  // Convertir de Objeto a Map (para BD o API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'proceso': proceso, 
    };
  }
}
