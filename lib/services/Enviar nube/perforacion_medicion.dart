import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/services/api_service.dart';

class PerforacionMedicionService {
  final ApiService _apiService = ApiService();

  // Crear nueva perforación con detalles
  Future<bool> crearPerforacion(Map<String, dynamic> perforacionData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.perforacionEndpoint, // Asegúrate que esté en ApiConfig
        perforacionData,
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error al crear perforación: $e');
      return false;
    }
  }
}
