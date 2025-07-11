import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../database/database_helper.dart';
import '../models/Toneladas.dart';

class ApiServiceToneladas {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Obtener todas las toneladas
  Future<List<Toneladas>> fetchToneladas(String token) async { 
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.toneladasEndpoint}'),
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
