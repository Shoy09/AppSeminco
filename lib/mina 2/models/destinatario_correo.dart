class DestinatarioCorreo {
  final int id;
  final String nombre;
  final String correo;

  DestinatarioCorreo({
    required this.id,
    required this.nombre,
    required this.correo,
  });

  // Convertir JSON a objeto
  factory DestinatarioCorreo.fromJson(Map<String, dynamic> json) {
    return DestinatarioCorreo(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
    );
  }

  // Convertir objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
    };
  }
}
