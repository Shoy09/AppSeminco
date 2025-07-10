import 'dart:convert';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/formato_plan_mineral.dart';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
class ApiServiceFor {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Método para obtener los Formatos de Plan Mineral desde la API, con el token en las cabeceras
  Future<List<FormatoPlanMineral>> fetchFormatosPlanMineral(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.formatoPlanMineralEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',  // Añadimos el token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        // Parsear la respuesta JSON si la petición fue exitosa
        final List<dynamic> responseData = json.decode(response.body);
        List<FormatoPlanMineral> formatos = responseData
            .map((data) => FormatoPlanMineral.fromJson(data))
            .toList();
        
        // Eliminar los datos antiguos de la base de datos local antes de insertar los nuevos
        await _dbHelper.deleteAll('FormatoPlanMineral');
        
        // Guardar los datos en la base de datos local
        await saveFormatosToLocalDB(formatos);
        
        return formatos;
      } else {
        // Lanzar una excepción si el servidor responde con un código de error
        throw Exception('Failed to load Formatos de Plan Mineral, Status Code: ${response.statusCode}');
      }
    } catch (error) {
      // Manejar errores de la petición (por ejemplo, problemas de conexión)
      throw Exception('Error al hacer la solicitud: $error');
    }
  }

  // Método para guardar los Formatos de Plan Mineral en la base de datos local
  Future<void> saveFormatosToLocalDB(List<FormatoPlanMineral> formatos) async {
    for (var formato in formatos) {
      // Convertir cada FormatoPlanMineral a Map<String, dynamic>
      Map<String, dynamic> formatoData = formato.toJson();
      // Insertar el dato en la tabla correspondiente usando el método general de inserción
      await _dbHelper.insert('FormatoPlanMineral', formatoData);
    }
  }
}
