import 'dart:convert';
import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%202/models/JefeGuardiaAcero.dart';
import 'package:http/http.dart' as http;


class ApiServiceJefeGuardiaAcero {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los jefes de guardia desde la API
  Future<List<JefeGuardiaAcero>> fetchJefesGuardia(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.JefeGuardiaAceroEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<JefeGuardiaAcero> jefesGuardia = responseData
            .map((data) => JefeGuardiaAcero.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('JEFE_DE_GUARDIA_Acero');

        // Guardar los datos en la base de datos local
        await saveJefesGuardiaToLocalDB(jefesGuardia);

        return jefesGuardia;
      } else {
        throw Exception('Error al obtener los jefes de guardia. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar jefes de guardia en la base de datos local
  Future<void> saveJefesGuardiaToLocalDB(List<JefeGuardiaAcero> jefesGuardia) async {
    for (var jefe in jefesGuardia) {
      Map<String, dynamic> jefeData = jefe.toMap();
      jefeData.remove('id'); // Remover id para evitar conflictos
      await _dbHelper.insert('JEFE_DE_GUARDIA_Acero', jefeData);
    }
  }

}