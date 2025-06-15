import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/services/api_service.dart';

class ExploracionService {
  final ApiService _apiService = ApiService();

  // Crear una exploración completa
  Future<bool> crearExploracionCompleta(Map<String, dynamic> exploracionData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.datosExploracionesEndpoint,
        exploracionData,
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error al crear exploración: $e');
      return false;
    }
  }

} 