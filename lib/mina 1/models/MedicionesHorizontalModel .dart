class MedicionesHorizontalModel {
  final int? id;              // id local (autoincrement)
  final String fecha;
  final String? turno;
  final String? empresa;
  final String? zona;
  final String? labor;
  final String? veta;
  final String? tipoPerforacion;
  final double? kgExplosivos;
  final double? avanceProgramado;
  final double? ancho;
  final double? alto;
  final int envio;
  final int? idExplosivo;
  final int? idnube;          // tal cual llega de la API
  final int? idNubeMedicion;  // id remoto, se guarda aquí
  final int noAplica;
  final int remanente;

  MedicionesHorizontalModel({
    this.id,
    required this.fecha,
    this.turno,
    this.empresa,
    this.zona,
    this.labor,
    this.veta,
    this.tipoPerforacion,
    this.kgExplosivos,
    this.avanceProgramado,
    this.ancho,
    this.alto,
    this.envio = 0,
    this.idExplosivo,
    this.idnube,
    this.idNubeMedicion,
    this.noAplica = 0,
    this.remanente = 0,
  });

  factory MedicionesHorizontalModel.fromJson(Map<String, dynamic> json) {
    return MedicionesHorizontalModel(
      idNubeMedicion: json['id'], // 🔹 el id de la API se guarda aquí
      fecha: json['fecha'] ?? '',
      turno: json['turno'],
      empresa: json['empresa'],
      zona: json['zona'],
      labor: json['labor'],
      veta: json['veta'],
      tipoPerforacion: json['tipo_perforacion'],
      kgExplosivos: (json['kg_explosivos'] as num?)?.toDouble(),
      avanceProgramado: (json['avance_programado'] as num?)?.toDouble(),
      ancho: (json['ancho'] as num?)?.toDouble(),
      alto: (json['alto'] as num?)?.toDouble(),
      envio: json['envio'] ?? 0,
      idExplosivo: json['id_explosivo'],
      idnube: json['idnube'], // se mantiene tal cual
      noAplica: json['no_aplica'] ?? 0,
      remanente: json['remanente'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,  // no insertamos id local
      'fecha': fecha,
      'turno': turno,
      'empresa': empresa,
      'zona': zona,
      'labor': labor,
      'veta': veta,
      'tipo_perforacion': tipoPerforacion,
      'kg_explosivos': kgExplosivos,
      'avance_programado': avanceProgramado,
      'ancho': ancho,
      'alto': alto,
      'envio': envio,
      'id_explosivo': idExplosivo,
      'idnube': idnube,
      'idNube_medicion': idNubeMedicion,
      'no_aplica': noAplica,
      'remanente': remanente,
    };
  }
}
