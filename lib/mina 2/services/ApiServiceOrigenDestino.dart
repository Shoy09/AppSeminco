import 'dart:convert';
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:http/http.dart' as http;

import '../models/OrigenDestino.dart';

class ApiServiceOrigenDestino {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Obtener todos los registros de OrigenDestino desde API
  Future<List<OrigenDestino>> fetchOrigenDestino(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.origenDestinoEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        List<OrigenDestino> origenesDestinos = responseData
            .map((data) => OrigenDestino.fromJson(data))
            .toList();

        // Limpiar tabla local antes de insertar nuevos datos
        await _dbHelper.deleteAll('OrigenDestino');

        // Guardar en la base de datos local
        await saveOrigenDestinoToLocalDB(origenesDestinos);

        return origenesDestinos;
      } else {
        throw Exception(
            'Error al obtener OrigenDestino. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar registros en la base de datos local
  Future<void> saveOrigenDestinoToLocalDB(List<OrigenDestino> lista) async {
    for (var item in lista) {
      Map<String, dynamic> data = item.toMap();
      data.remove('id'); // Evitar conflictos de id autoincremental
      await _dbHelper.insert('OrigenDestino', data);
    }
  }

  // Crear un nuevo registro en la API y guardar localmente
  Future<OrigenDestino> createOrigenDestino(OrigenDestino nuevo, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.origenDestinoEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(nuevo.toMap()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        OrigenDestino registro = OrigenDestino.fromJson(data);

        // Guardar localmente
        Map<String, dynamic> localData = registro.toMap();
        localData.remove('id');
        await _dbHelper.insert('OrigenDestino', localData);

        return registro;
      } else {
        throw Exception(
            'Error al crear OrigenDestino. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Eliminar registro en API y BD local
  Future<void> deleteOrigenDestino(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.origenDestinoEndpoint}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminar localmente
        await _dbHelper.delete('OrigenDestino', id);
      } else {
        throw Exception(
            'Error al eliminar OrigenDestino. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }
}
