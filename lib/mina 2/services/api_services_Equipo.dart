import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import '../models/Equipo.dart';

class ApiServiceEquipo {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Método para obtener los equipos desde la API
  Future<List<Equipo>> fetchEquipos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.EquipoEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token', // Token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<Equipo> equipos = responseData
            .map((data) => Equipo.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('Equipo');

        // Guardar los datos en la base de datos local
        await saveEquiposToLocalDB(equipos);

        return equipos;
      } else {
        throw Exception('Error al obtener los equipos. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar equipos en la base de datos local
   Future<void> saveEquiposToLocalDB(List<Equipo> equipos) async {
    for (var equipo in equipos) {
      Map<String, dynamic> equipoData = equipo.toMap();
      equipoData.remove('id'); // Asegurar que no se inserte el id para evitar conflictos
      await _dbHelper.insert('Equipo', equipoData);
    }
  }
}
