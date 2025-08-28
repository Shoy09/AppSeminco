import 'dart:convert';
import 'package:app_seminco/mina%202/models/EstadostBD.dart';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class ApiServiceEstado {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Obtener estados con subestados desde la API
  Future<List<EstadostBD>> fetchEstados(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.estadosEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<EstadostBD> estados = responseData
            .map((data) => EstadostBD.fromJson(data))
            .toList();

        // 🔹 Limpiar ambas tablas antes de insertar los nuevos datos
        await _dbHelper.deleteAll('SubEstadoBD');
        await _dbHelper.deleteAll('EstadostBD');

        // Guardar estados y subestados
        await saveEstadosToLocalDB(estados);

        return estados;
      } else {
        throw Exception('Error al cargar los estados. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar estados y sus subestados en la BD local
  Future<void> saveEstadosToLocalDB(List<EstadostBD> estados) async {
    for (var estado in estados) {
      // Insertar Estado
      Map<String, dynamic> estadoData = estado.toMap();
      estadoData.remove('id'); // dejamos que SQLite autogenere el id
      int estadoId = await _dbHelper.insert('EstadostBD', estadoData);

      // Insertar SubEstados vinculados
      if (estado.subEstados != null) {
        for (var sub in estado.subEstados!) {
          Map<String, dynamic> subData = sub.toMap();
          subData.remove('id');
          subData['estadoId'] = estadoId; // 🔑 clave foránea real en SQLite
          await _dbHelper.insert('SubEstadoBD', subData);
        }
      }
    }
  }
}
