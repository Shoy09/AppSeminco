import 'dart:convert';
import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/ProcesoAcero.dart';
import 'package:http/http.dart' as http;

class ApiServiceProcesoAcero {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los procesos de acero desde la API
  Future<List<ProcesoAcero>> fetchProcesosAcero(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ProcesoAceroEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<ProcesoAcero> procesosAcero = responseData
            .map((data) => ProcesoAcero.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('procesos_acero');

        // Guardar los datos en la base de datos local
        await saveProcesosAceroToLocalDB(procesosAcero);

        return procesosAcero;
      } else {
        throw Exception('Error al obtener los procesos de acero. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar procesos de acero en la base de datos local
  Future<void> saveProcesosAceroToLocalDB(List<ProcesoAcero> procesosAcero) async {
    for (var proceso in procesosAcero) {
      Map<String, dynamic> procesoData = proceso.toMap();
      procesoData.remove('id'); // Remover id para evitar conflictos
      await _dbHelper.insert('procesos_acero', procesoData);
    }
  }

}