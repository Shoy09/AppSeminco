import 'dart:convert';
import 'package:app_seminco/mina%201/models/MedicionesHorizontalModel%20.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../database/database_helper.dart';

class ApiServiceMedicionesHorizontal {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  Future<List<MedicionesHorizontalModel>> fetchMedicionesConRemanente(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.medicionesHorizontalEndpointRemanente}'), // GET /yyy
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        final List<MedicionesHorizontalModel> mediciones = jsonData
            .map((e) => MedicionesHorizontalModel.fromJson(e))
            .toList();

        // Limpia antes de insertar (opcional, depende de si quieres merge)
        await _dbHelper.deleteAll('mediciones_horizontal');

        // Guarda en local
        await saveMedicionesToLocalDB(mediciones);

        return mediciones;
      } else {
        throw Exception('Error al obtener mediciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en fetchMedicionesConRemanente: $e');
    }
  }

  Future<void> saveMedicionesToLocalDB(List<MedicionesHorizontalModel> mediciones) async {
    for (var m in mediciones) {
      final data = m.toMap();
      data.remove('id'); // evitar conflicto con autoincrement
      await _dbHelper.insert('mediciones_horizontal', data);
    }
  }
}
