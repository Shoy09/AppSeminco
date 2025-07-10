class FormatoPlanMineral {
  final int id;
  final String mina;
  final String zona;
  final String estructura;
  final String tipoMaterial;
  final String nivel;
  final String block;
  final String labor;
  final String metodoMinado;
  final double metros;
  final double densidad;
  final double toneladas;
  final double ag;
  final double au;
  final double pb;
  final double zn;
  final double cu;
  final double vpt;

  FormatoPlanMineral({
    required this.id,
    required this.mina,
    required this.zona,
    required this.estructura,
    required this.tipoMaterial,
    required this.nivel,
    required this.block,
    required this.labor,
    required this.metodoMinado,
    required this.metros,
    required this.densidad,
    required this.toneladas,
    required this.ag,
    required this.au,
    required this.pb,
    required this.zn,
    required this.cu,
    required this.vpt,
  });

  // Factory method to create an instance from JSON
  factory FormatoPlanMineral.fromJson(Map<String, dynamic> json) {
    return FormatoPlanMineral(
      id: json['id'],
      mina: json['mina'],
      zona: json['zona'],
      estructura: json['estructura'],
      tipoMaterial: json['tipo_material'],
      nivel: json['nivel'],
      block: json['block'],
      labor: json['labor'],
      metodoMinado: json['metodo_minado'],
      metros: json['metros'].toDouble(),
      densidad: json['densidad'].toDouble(),
      toneladas: json['toneladas'].toDouble(),
      ag: json['ag'].toDouble(),
      au: json['au'].toDouble(),
      pb: json['pb'].toDouble(),
      zn: json['zn'].toDouble(),
      cu: json['cu'].toDouble(),
      vpt: json['vpt'].toDouble(),
    );
  }

  // Method to convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mina': mina,
      'zona': zona,
      'estructura': estructura,
      'tipo_material': tipoMaterial,
      'nivel': nivel,
      'block': block,
      'labor': labor,
      'metodo_minado': metodoMinado,
      'metros': metros,
      'densidad': densidad,
      'toneladas': toneladas,
      'ag': ag,
      'au': au,
      'pb': pb,
      'zn': zn,
      'cu': cu,
      'vpt': vpt,
    };
  }
}
