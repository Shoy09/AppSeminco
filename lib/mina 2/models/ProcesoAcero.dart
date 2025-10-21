class ProcesoAcero {
  int? id;
  String proceso;
  String tipoAcero;
  String? descripcion;
  double precio;

  ProcesoAcero({
    this.id,
    required this.proceso,
    required this.tipoAcero,
    this.descripcion,
    required this.precio,
  });

  // Convertir de JSON a Objeto
  factory ProcesoAcero.fromJson(Map<String, dynamic> json) {
    return ProcesoAcero(
      id: json['id'],
      proceso: json['proceso'],
      tipoAcero: json['tipo_acero'],
      descripcion: json['descripcion'],
      precio: json['precio']?.toDouble() ?? 0.0,
    );
  }

  // Convertir de Objeto a Map (para BD local)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso': proceso,
      'tipo_acero': tipoAcero,
      'descripcion': descripcion,
      'precio': precio,
    };
  }

  // Para enviar a la API
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'proceso': proceso,
      'tipo_acero': tipoAcero,
      'descripcion': descripcion,
      'precio': precio,
    };
  }
}