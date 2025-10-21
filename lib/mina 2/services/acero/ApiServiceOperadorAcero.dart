import 'dart:convert';
import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%202/models/OperadorAcero.dart';
import 'package:http/http.dart' as http;


class ApiServiceOperadorAcero {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los operadores desde la API
  Future<List<OperadorAcero>> fetchOperadores(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.OperadorAceroEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<OperadorAcero> operadores = responseData
            .map((data) => OperadorAcero.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('OPERADOR_Acero');

        // Guardar los datos en la base de datos local
        await saveOperadoresToLocalDB(operadores);

        return operadores;
      } else {
        throw Exception('Error al obtener los operadores. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar operadores en la base de datos local
  Future<void> saveOperadoresToLocalDB(List<OperadorAcero> operadores) async {
    for (var operador in operadores) {
      Map<String, dynamic> operadorData = operador.toMap();
      operadorData.remove('id'); // Remover id para evitar conflictos
      await _dbHelper.insert('OPERADOR_Acero', operadorData);
    }
  }

}