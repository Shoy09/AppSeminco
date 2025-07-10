class NubeDatosTrabajoExploraciones {
  int? id;
  String? fecha;
  String? turno;
  String? taladro;
  String? piesPorTaladro;
  String? zona;
  String? tipoLabor;
  String? labor;
  String? ala;
  String? veta;
  String? nivel;
  String? tipoPerforacion;
  String? estado;
  int? cerrado;
  int? envio;
  String? semanaDefault;
  String? semanaSelect;
  String? empresa;
  String? seccion;
  String? idnube;
  int? medicion;

  NubeDatosTrabajoExploraciones({
    this.id,
    this.fecha,
    this.turno,
    this.taladro,
    this.piesPorTaladro,
    this.zona,
    this.tipoLabor,
    this.labor,
    this.ala,
    this.veta,
    this.nivel,
    this.tipoPerforacion,
    this.estado = 'Creado',
    this.cerrado = 0,
    this.envio = 0,
    this.semanaDefault,
    this.semanaSelect,
    this.empresa,
    this.seccion,
    this.idnube,
    this.medicion = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'turno': turno,
      'taladro': taladro,
      'pies_por_taladro': piesPorTaladro,
      'zona': zona,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'veta': veta,
      'nivel': nivel,
      'tipo_perforacion': tipoPerforacion,
      'estado': estado,
      'cerrado': cerrado,
      'envio': envio,
      'semanaDefault': semanaDefault,
      'semanaSelect': semanaSelect,
      'empresa': empresa,
      'seccion': seccion,
      'idnube': idnube,
      'medicion': medicion,
    };
  }

  factory NubeDatosTrabajoExploraciones.fromMap(Map<String, dynamic> map) {
    return NubeDatosTrabajoExploraciones(
      id: map['id'],
      fecha: map['fecha'],
      turno: map['turno'],
      taladro: map['taladro'],
      piesPorTaladro: map['pies_por_taladro'],
      zona: map['zona'],
      tipoLabor: map['tipo_labor'],
      labor: map['labor'],
      ala: map['ala'],
      veta: map['veta'],
      nivel: map['nivel'],
      tipoPerforacion: map['tipo_perforacion'],
      estado: map['estado'],
      cerrado: map['cerrado'],
      envio: map['envio'],
      semanaDefault: map['semanaDefault'],
      semanaSelect: map['semanaSelect'],
      empresa: map['empresa'],
      seccion: map['seccion'],
      idnube: map['idnube'],
      medicion: map['medicion'],
    );
  }
}


class NubeDespacho {
  int? id;
  int? datosTrabajoId;
  double? miliSegundo;
  double? medioSegundo;
  String? observaciones;

  NubeDespacho({
    this.id,
    this.datosTrabajoId,
    this.miliSegundo,
    this.medioSegundo,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'datos_trabajo_id': datosTrabajoId,
      'mili_segundo': miliSegundo,
      'medio_segundo': medioSegundo,
      'observaciones': observaciones,
    };
  }

  factory NubeDespacho.fromMap(Map<String, dynamic> map) {
    return NubeDespacho(
      id: map['id'],
      datosTrabajoId: map['datos_trabajo_id'],
      miliSegundo: map['mili_segundo'],
      medioSegundo: map['medio_segundo'],
      observaciones: map['observaciones'],
    );
  }
}

class NubeDespachoDetalle {
  int? id;
  int? despachoId;
  String? nombreMaterial;
  String? cantidad;

  NubeDespachoDetalle({
    this.id,
    this.despachoId,
    this.nombreMaterial,
    this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'despacho_id': despachoId,
      'nombre_material': nombreMaterial,
      'cantidad': cantidad,
    };
  }

  factory NubeDespachoDetalle.fromMap(Map<String, dynamic> map) {
    return NubeDespachoDetalle(
      id: map['id'],
      despachoId: map['despacho_id'],
      nombreMaterial: map['nombre_material'],
      cantidad: map['cantidad'],
    );
  }
}

class NubeDevoluciones {
  int? id;
  int? datosTrabajoId;
  double? miliSegundo;
  double? medioSegundo;
  String? observaciones;

  NubeDevoluciones({
    this.id,
    this.datosTrabajoId,
    this.miliSegundo,
    this.medioSegundo,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'datos_trabajo_id': datosTrabajoId,
      'mili_segundo': miliSegundo,
      'medio_segundo': medioSegundo,
      'observaciones': observaciones,
    };
  }

  factory NubeDevoluciones.fromMap(Map<String, dynamic> map) {
    return NubeDevoluciones(
      id: map['id'],
      datosTrabajoId: map['datos_trabajo_id'],
      miliSegundo: map['mili_segundo'],
      medioSegundo: map['medio_segundo'],
      observaciones: map['observaciones'],
    );
  }
}

class NubeDevolucionDetalle {
  int? id;
  int? devolucionId;
  String? nombreMaterial;
  String? cantidad;

  NubeDevolucionDetalle({
    this.id,
    this.devolucionId,
    this.nombreMaterial,
    this.cantidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'devolucion_id': devolucionId,
      'nombre_material': nombreMaterial,
      'cantidad': cantidad,
    };
  }

  factory NubeDevolucionDetalle.fromMap(Map<String, dynamic> map) {
    return NubeDevolucionDetalle(
      id: map['id'],
      devolucionId: map['devolucion_id'],
      nombreMaterial: map['nombre_material'],
      cantidad: map['cantidad'],
    );
  }
}

class NubeDetalleDespachoExplosivos {
  int? id;
  int? idDespacho;
  int? numero;
  String? msCant1;
  String? lpCant1;

  NubeDetalleDespachoExplosivos({
    this.id,
    this.idDespacho,
    this.numero,
    this.msCant1,
    this.lpCant1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_despacho': idDespacho,
      'numero': numero,
      'ms_cant1': msCant1,
      'lp_cant1': lpCant1,
    };
  }

  factory NubeDetalleDespachoExplosivos.fromMap(Map<String, dynamic> map) {
    return NubeDetalleDespachoExplosivos(
      id: map['id'],
      idDespacho: map['id_despacho'],
      numero: map['numero'],
      msCant1: map['ms_cant1'],
      lpCant1: map['lp_cant1'],
    );
  }
}

class NubeDetalleDevolucionesExplosivos {
  int? id;
  int? idDevolucion;
  int? numero;
  String? msCant1;
  String? lpCant1;

  NubeDetalleDevolucionesExplosivos({
    this.id,
    this.idDevolucion,
    this.numero,
    this.msCant1,
    this.lpCant1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_devolucion': idDevolucion,
      'numero': numero,
      'ms_cant1': msCant1,
      'lp_cant1': lpCant1,
    };
  }

  factory NubeDetalleDevolucionesExplosivos.fromMap(Map<String, dynamic> map) {
    return NubeDetalleDevolucionesExplosivos(
      id: map['id'],
      idDevolucion: map['id_devolucion'],
      numero: map['numero'],
      msCant1: map['ms_cant1'],
      lpCant1: map['lp_cant1'],
    );
  }
}