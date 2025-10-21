import 'dart:convert';
import 'package:app_seminco/mina%201/services/api_service.dart';
import 'package:app_seminco/config/api_config.dart';

class CarguioService {
  final ApiService_Mina1 _apiService = ApiService_Mina1();
  /// 📦 POST: Enviar un solo registro de Carguío
  Future<List<int>?> enviarCarguio(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.post(
      ApiConfig.carguioEndpoint,
      operacionData,
    );
    
    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final ids = List<int>.from(responseData['operaciones_ids'] ?? []);
      return ids;
    }
    return null;
  } catch (e) {
    print('Error al crear operación horizontal: $e');
    return null;
  }
}

  Future<bool> actualizarCarguio(dynamic data) async {
    try {
      // data puede ser un objeto o lista, igual que el backend
      final response = await _apiService.put(
        ApiConfig.carguioEndpoint,
        data,
      );

      if (response.statusCode == 200) {
        print('✅ Todas las operaciones actualizadas correctamente.');
        return true;
      } else if (response.statusCode == 207) {
        // 207 Multi-Status → algunas operaciones fallaron
        final responseData = json.decode(response.body);
        print('⚠️ Algunas operaciones no se actualizaron correctamente:');
        print('Errores: ${responseData['errores']}');
        return false;
      } else {
        print('❌ Error al actualizar carguío: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Error en actualizarCarguio(): $e');
      return false;
    }
  }
}

