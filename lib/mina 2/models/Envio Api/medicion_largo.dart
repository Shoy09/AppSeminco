class MedicionLargo {
  final int? id; // ID local (no se enviará a la API)
  final String fecha;
  final String? turno;
  final String? empresa;
  final String? zona;
  final String? labor;
  final String? veta;
  final String? tipoPerforacion;
  final double? kgExplosivos;
  final double? toneladas;
  final int? envio;
  final int? idExplosivo;
  final int? idnube;

  MedicionLargo({
    this.id,
    required this.fecha,
    this.turno,
    this.empresa,
    this.zona,
    this.labor,
    this.veta,
    this.tipoPerforacion,
    this.kgExplosivos,
    this.toneladas,
    this.envio,
    this.idExplosivo,
    this.idnube,
  });

  // Constructor fromJson para crear instancia desde Map
  factory MedicionLargo.fromJson(Map<String, dynamic> json) {
    return MedicionLargo(
      id: json['id'],
      fecha: json['fecha'],
      turno: json['turno'],
      empresa: json['empresa'],
      zona: json['zona'],
      labor: json['labor'],
      veta: json['veta'],
      tipoPerforacion: json['tipo_perforacion'],
      kgExplosivos: json['kg_explosivos']?.toDouble(),
      toneladas: json['toneladas']?.toDouble(),
      envio: json['envio'],
      idExplosivo: json['id_explosivo'],
      idnube: json['idnube'],
    );
  }

  // Método para enviar a la API (excluye el ID local)
  Map<String, dynamic> toApiJson() => {
        'fecha': fecha,
        if (turno != null) 'turno': turno,
        if (empresa != null) 'empresa': empresa,
        if (zona != null) 'zona': zona,
        if (labor != null) 'labor': labor,
        if (veta != null) 'veta': veta,
        if (tipoPerforacion != null) 'tipo_perforacion': tipoPerforacion,
        if (kgExplosivos != null) 'kg_explosivos': kgExplosivos,
        if (toneladas != null) 'toneladas': toneladas,
        if (envio != null) 'envio': envio,
        if (idExplosivo != null) 'id_explosivo': idExplosivo,
        if (idnube != null) 'idnube': idnube,
      };

  // Método para uso local (incluye el ID)
  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'fecha': fecha,
        'turno': turno,
        'empresa': empresa,
        'zona': zona,
        'labor': labor,
        'veta': veta,
        'tipo_perforacion': tipoPerforacion,
        'kg_explosivos': kgExplosivos,
        'toneladas': toneladas,
        'envio': envio,
        'id_explosivo': idExplosivo,
        'idnube': idnube,
      };
}