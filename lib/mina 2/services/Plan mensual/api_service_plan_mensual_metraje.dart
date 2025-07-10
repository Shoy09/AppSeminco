import 'dart:convert';
import 'package:app_seminco/mina%202/models/PlanMetraje.dart';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class ApiServicePlanMetraje {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  Future<List<PlanMetraje>> fetchPlanesMetraje(
      String token, int anio, String mes) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.PlanMetrajeEndpoint}anio/$anio/mes/$mes'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<PlanMetraje> planes =
            responseData.map((data) => PlanMetraje.fromJson(data)).toList();

        await _dbHelper.deleteAll('PlanMetraje');
        await savePlanesToLocalDB(planes);

        return planes;
      } else {
        throw Exception(
            'Error al obtener los planes de metraje. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  Future<void> savePlanesToLocalDB(List<PlanMetraje> planes) async {
    for (var plan in planes) {
      Map<String, dynamic> planData = plan.toMap();
      planData.remove('id');
      await _dbHelper.insert('PlanMetraje', planData);
    }
  }
}
