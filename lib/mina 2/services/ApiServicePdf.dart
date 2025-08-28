import 'dart:convert';
import 'dart:io';
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/PdfModel.dart';

class ApiServicePdf {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

Future<List<PdfModel>> fetchPdfsPorMes(String token, String mes) async {
  try {
    final url = '${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.pdfEndpoint}/mes/$mes';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);

      // 🔍 Ver lo que llega de la API
      print('📥 Respuesta de API:');
      for (var item in responseData) {
        print(jsonEncode(item));
      }

      List<PdfModel> pdfs = responseData.map((data) => PdfModel.fromJson(data)).toList();

      await _dbHelper.deleteAll('PdfModel');
      await savePdfsToLocalDB(pdfs);

      return pdfs;
    } else {
      throw Exception('Error al cargar los PDFs. Código: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Error en la solicitud: $error');
  }
}

Future<void> savePdfsToLocalDB(List<PdfModel> pdfs) async {
  for (var pdf in pdfs) {
    String localPath = await _downloadPdfAndSaveLocally(pdf);

    if (localPath.isNotEmpty) {
      Map<String, dynamic> pdfData = {
        'id': pdf.id,
        'proceso': pdf.proceso,
        'mes': pdf.mes,
        'url_pdf': localPath,
        'tipo_labor': pdf.tipoLabor,
        'labor': pdf.labor,
        'ala': pdf.ala,
        'createdAt': pdf.createdAt.toIso8601String(),
        'updatedAt': pdf.updatedAt.toIso8601String(),
      };

      // 🔍 Ver lo que se guarda en la base de datos
      print('💾 Guardando en DB local: ${jsonEncode(pdfData)}');

      await _dbHelper.insert('PdfModel', pdfData);
    } else {
      print('❌ No se guardó el PDF con ID ${pdf.id} por fallo de descarga');
    }
  }
}



  /// 📥 Descarga PDF y devuelve la ruta local
  Future<String> _downloadPdfAndSaveLocally(PdfModel pdf) async {
    try {
      final response = await http.get(Uri.parse(pdf.urlPdf));
      if (response.statusCode == 200) {
        // Obtener carpeta local para almacenar
        final directory = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${directory.path}/pdf');

        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final filename = 'pdf_${pdf.id}_${pdf.mes.toLowerCase()}.pdf';
        final filePath = path.join(pdfDir.path, filename);
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        return file.path; // 👉 Retornamos ruta local
      } else {
        throw Exception('Error al descargar PDF');
      }
    } catch (e) {
      print('Error al guardar PDF local: $e');
      return ''; // Devuelve vacío si falla
    }
  }
}
  