import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/mina%201/models/FechasPlanMensual.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class FechasPlanMensualService {

  // Obtener la última fecha registrada
  Future<FechasPlanMensual> getUltimaFecha() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.fechasPlanMensualEndpoint}ultima'));
      if (response.statusCode == 200) {
        return FechasPlanMensual.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener la última fecha');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
