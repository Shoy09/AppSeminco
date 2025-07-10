import 'dart:convert';
import 'package:app_seminco/mina%202/models/EstadostBD.dart';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class ApiServiceEstado {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Método para obtener los estados desde la API, con el token en las cabeceras
  Future<List<EstadostBD>> fetchEstados(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.estadosEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token', // Token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        final List<dynamic> responseData = json.decode(response.body);
        List<EstadostBD> estados = responseData
            .map((data) => EstadostBD.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('EstadostBD');

        // Guardar los datos en la base de datos local sin el id
        await saveEstadosToLocalDB(estados);

        return estados;
      } else {
        throw Exception('Error al cargar los estados. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Método para guardar los Estados en la base de datos local
  Future<void> saveEstadosToLocalDB(List<EstadostBD> estados) async {
    for (var estado in estados) {
      Map<String, dynamic> estadoData = estado.toMap();
      estadoData.remove('id'); // Asegurar que no se inserte el id
      await _dbHelper.insert('EstadostBD', estadoData);
    } 
  }
}
