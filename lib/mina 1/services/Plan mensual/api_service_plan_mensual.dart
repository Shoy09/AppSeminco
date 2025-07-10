import 'dart:convert';
import 'package:app_seminco/mina%201/models/PlanMensual.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../database/database_helper.dart';

class ApiServicePlanMensual {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los planes mensuales desde la API
  Future<List<PlanMensual>> fetchPlanesMensuales(String token, int anio, String mes) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.PlanMensualEndpoint}anio/$anio/mes/$mes'),
        headers: {
          'Authorization': 'Bearer $token', // Token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<PlanMensual> planes = responseData
            .map((data) => PlanMensual.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('PlanMensual');

        // Guardar los datos en la base de datos local
        await savePlanesToLocalDB(planes);

        return planes;
      } else {
        throw Exception('Error al obtener los planes mensuales. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar planes en la base de datos local
  Future<void> savePlanesToLocalDB(List<PlanMensual> planes) async {
    for (var plan in planes) {
      Map<String, dynamic> planData = plan.toMap();
      planData.remove('id'); // Asegurar que no se inserte el id para evitar conflictos
      await _dbHelper.insert('PlanMensual', planData);
    }
  }
}
