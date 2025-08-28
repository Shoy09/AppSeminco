class PdfModel {
  final int id;
  final String proceso;
  final String mes;
  final String urlPdf;
  final String? tipoLabor;
  final String? labor;
  final String? ala;
  final DateTime createdAt;
  final DateTime updatedAt;

  PdfModel({
    required this.id,
    required this.proceso,
    required this.mes,
    required this.urlPdf,
    this.tipoLabor,
    this.labor,
    this.ala,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PdfModel.fromJson(Map<String, dynamic> json) {
    return PdfModel(
      id: json['id'],
      proceso: json['proceso'],
      mes: json['mes'],
      urlPdf: json['url_pdf'],
      tipoLabor: json['tipo_labor']?.trim().isEmpty ?? true ? null : json['tipo_labor'],
      labor: json['labor']?.trim().isEmpty ?? true ? null : json['labor'],
      ala: json['ala']?.trim().isEmpty ?? true ? null : json['ala'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proceso': proceso,
      'mes': mes,
      'url_pdf': urlPdf,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
