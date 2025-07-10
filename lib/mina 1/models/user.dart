class User {
  int id;
  String codigoDni;
  String apellidos;
  String nombres;
  String? cargo;
  String? empresa;
  String? guardia;
  String? autorizadoEquipo;
  String? area;
  String? clasificacion;
  String? correo;
  String password;
  String? firma;
  String createdAt;
  String updatedAt;
  String token;
  String rol;
  Map<String, dynamic>? operacionesAutorizadas; // <-- nuevo campo

  User({
    required this.id,
    required this.codigoDni,
    required this.apellidos,
    required this.nombres,
    this.cargo,
    this.empresa,
    this.guardia,
    this.autorizadoEquipo,
    this.area,
    this.clasificacion,
    this.correo,
    required this.password,
    this.firma,
    required this.createdAt,
    required this.updatedAt,
    required this.token,
    required this.rol,
    this.operacionesAutorizadas,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      codigoDni: json['codigo_dni'],
      apellidos: json['apellidos'],
      nombres: json['nombres'],
      cargo: json['cargo'],
      empresa: json['empresa'],
      guardia: json['guardia'],
      autorizadoEquipo: json['autorizado_equipo'],
      area: json['area'],
      clasificacion: json['clasificacion'],
      correo: json['correo'],
      password: json['password'],
      firma: json['firma'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      token: json['token'],
      rol: json['rol'],
      operacionesAutorizadas: json['operaciones_autorizadas'], // <-- nuevo
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_dni': codigoDni,
      'apellidos': apellidos,
      'nombres': nombres,
      'cargo': cargo,
      'empresa': empresa,
      'guardia': guardia,
      'autorizado_equipo': autorizadoEquipo,
      'area': area,
      'clasificacion': clasificacion,
      'correo': correo,
      'password': password,
      'firma': firma ?? '',
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'token': token,
      'rol': rol,
      'operaciones_autorizadas': operacionesAutorizadas, // <-- nuevo
    };
  }
}
