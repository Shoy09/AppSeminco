import 'dart:convert';
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/toneladas.dart';
import 'package:http/http.dart' as http;



class ApiServiceToneladas {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Obtener todas las toneladas
  Future<List<Toneladas>> fetchToneladas(String token) async { 
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.toneladasEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<Toneladas> toneladas = responseData
            .map((data) => Toneladas.fromJson(data))
            .toList();

        // Limpiar tabla antes de insertar nuevos datos
        await _dbHelper.deleteAll('toneladas');

        // Guardar en la base de datos local
        await saveToneladasToLocalDB(toneladas);

        return toneladas;
      } else {
        throw Exception('Error al obtener toneladas. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar toneladas en la base de datos local
  Future<void> saveToneladasToLocalDB(List<Toneladas> toneladas) async {
    for (var t in toneladas) {
      Map<String, dynamic> toneladaData = t.toMap();
      toneladaData.remove('id'); // Evitar conflictos de id autoincremental
      await _dbHelper.insert('toneladas', toneladaData);
    }
  }


}
