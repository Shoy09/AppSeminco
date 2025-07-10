import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../database/database_helper.dart';
import '../models/TipoPerforacion.dart';

class ApiServiceTipoPerforacion {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los tipos de perforación desde la API
  Future<List<TipoPerforacion>> fetchTiposPerforacion(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tipoPerforacionEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token', // Token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<TipoPerforacion> tiposPerforacion = responseData
            .map((data) => TipoPerforacion.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('TipoPerforacion');

        // Guardar los datos en la base de datos local
        await saveTiposToLocalDB(tiposPerforacion);

        return tiposPerforacion;
      } else {
        throw Exception('Error al obtener los tipos de perforación. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar tipos de perforación en la base de datos local
  Future<void> saveTiposToLocalDB(List<TipoPerforacion> tiposPerforacion) async {
    for (var tipo in tiposPerforacion) {
      Map<String, dynamic> tipoData = tipo.toMap();
      tipoData.remove('id'); // Asegurar que no se inserte el id para evitar conflictos
      await _dbHelper.insert('TipoPerforacion', tipoData);
    }
  }
}
