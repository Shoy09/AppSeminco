import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

void showPdfDialog(
  BuildContext context, 
  String tipoOperacion, {
  String? tipoLabor,
  String? labor,
  String? ala,
}) async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

  // Obtener PDF filtrado por proceso y otros parámetros
  // Mostrar los filtros en consola
  print('📄 Buscando PDF con los siguientes filtros:');
  print('🛠️ Proceso: $tipoOperacion');
  print('🔧 Tipo de labor: ${tipoLabor ?? "null"}');
  print('🔨 Labor: ${labor ?? "null"}');
  print('🕊️ Ala: ${ala?.isEmpty ?? true ? "vacío o null" : ala}');

  // Obtener PDF filtrado por proceso y otros parámetros
  Map<String, dynamic>? pdfData = await dbHelper.getPdfByProceso(
    proceso: tipoOperacion,
    tipoLabor: tipoLabor,
    labor: labor,
    ala: ala,
  );

  if (pdfData != null) {
    print("✅ PDF encontrado: ${pdfData['url_pdf']}");
    // Aquí puedes seguir mostrando el PDF como ya haces
  } else {
    print("❌ No se encontró ningún PDF con los filtros aplicados.");
  }

  
  String? pdfPath = pdfData?['url_pdf'];

  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Calcula tamaños proporcionales
  final dialogWidth = screenWidth * 0.9;
  final dialogHeight = screenHeight * 0.7;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          tipoOperacion,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: pdfPath != null && File(pdfPath).existsSync()
              ? SfPdfViewer.file(File(pdfPath))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo cargar el PDF.',
                      style: TextStyle(color: Colors.red),
                    ),
                    if (pdfData == null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Filtros aplicados:',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text('Proceso: $tipoOperacion'),
                      if (tipoLabor != null) Text('Tipo labor: $tipoLabor'),
                      if (labor != null) Text('Labor: $labor'),
                      if (ala != null) Text('Ala: $ala'),
                    ],
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}