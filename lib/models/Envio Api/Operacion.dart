class Operacion {
  int? id;
  String turno;
  String equipo;
  String codigo;
  String empresa;
  String fecha;
  String tipoOperacion;
  String estado;
  int envio;

  Operacion({
    this.id,
    required this.turno,
    required this.equipo,
    required this.codigo,
    required this.empresa,
    required this.fecha,
    required this.tipoOperacion,
    this.estado = 'activo',
    this.envio = 0,
  });

  factory Operacion.fromMap(Map<String, dynamic> map) {
    return Operacion(
      id: map['id'],
      turno: map['turno'],
      equipo: map['equipo'],
      codigo: map['codigo'],
      empresa: map['empresa'],
      fecha: map['fecha'],
      tipoOperacion: map['tipo_operacion'],
      estado: map['estado'],
      envio: map['envio'],
    );
  }
}

class Horometro {
  int? id;
  int operacionId;
  String nombre;
  double inicial;
  double finalValor;
  int estaOP;
  int estaINOP;

  Horometro({
    this.id,
    required this.operacionId,
    required this.nombre,
    required this.inicial,
    required this.finalValor,
    this.estaOP = 0,
    this.estaINOP = 0,
  });

  factory Horometro.fromMap(Map<String, dynamic> map) {
    return Horometro(
      id: map['id'],
      operacionId: map['operacion_id'],
      nombre: map['nombre'],
      inicial: map['inicial'],
      finalValor: map['final'],
      estaOP: map['EstaOP'],
      estaINOP: map['EstaINOP'],
    );
  }
}

class PerforacionTaladroLargo {
  int? id;
  String zona;
  String tipoLabor;
  String labor;
  String veta;
  String nivel;
  String tipoPerforacion;
  int operacionId;

  PerforacionTaladroLargo({
    this.id,
    required this.zona,
    required this.tipoLabor,
    required this.labor,
    required this.veta,
    required this.nivel,
    required this.tipoPerforacion,
    required this.operacionId,
  });

  factory PerforacionTaladroLargo.fromMap(Map<String, dynamic> map) {
    return PerforacionTaladroLargo(
      id: map['id'],
      zona: map['zona'],
      tipoLabor: map['tipo_labor'],
      labor: map['labor'],
      veta: map['veta'],
      nivel: map['nivel'],
      tipoPerforacion: map['tipo_perforacion'],
      operacionId: map['operacion_id'],
    );
  }
}

class InterPerforacionTaladroLargo {
  int? id;
  String codigoActividad;
  String nivel;
  String tajo;
  int nbroca;
  int ntaladro;
  int nbarras;
  double longitudPerforacion;
  double anguloPerforacion;
  String nfilasDeHasta;
  String detallesTrabajoRealizado;
  int perforacionTaladroLargoId;

  InterPerforacionTaladroLargo({
    this.id,
    required this.codigoActividad,
    required this.nivel,
    required this.tajo,
    required this.nbroca,
    required this.ntaladro,
    required this.nbarras,
    required this.longitudPerforacion,
    required this.anguloPerforacion,
    required this.nfilasDeHasta,
    required this.detallesTrabajoRealizado,
    required this.perforacionTaladroLargoId,
  });

  factory InterPerforacionTaladroLargo.fromMap(Map<String, dynamic> map) {
    return InterPerforacionTaladroLargo(
      id: map['id'],
      codigoActividad: map['codigo_actividad'],
      nivel: map['nivel'],
      tajo: map['tajo'],
      nbroca: map['nbroca'],
      ntaladro: map['ntaladro'],
      nbarras: map['nbarras'],
      longitudPerforacion: map['longitud_perforacion'],
      anguloPerforacion: map['angulo_perforacion'],
      nfilasDeHasta: map['nfilas_de_hasta'],
      detallesTrabajoRealizado: map['detalles_trabajo_realizado'],
      perforacionTaladroLargoId: map['perforaciontaladrolargo_id'],
    );
  }
}
