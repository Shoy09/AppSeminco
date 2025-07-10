import 'dart:convert';

import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/mina%201/services/api_service.dart';

class ExploracionService {
  final ApiService_Mina1 _apiService = ApiService_Mina1();

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

    // Método actualizado para marcar múltiples IDs como usados en mediciones
  Future<bool> marcarComoUsadosEnMediciones(List<int> ids) async {
    try {
      final response = await _apiService.put(
        ApiConfig.datosExploracionesmedionesEndpoint, // Endpoint específico
        {'ids': ids}, // Enviamos array de IDs
      );
      
      if (response.statusCode == 200) {
        print('✅ ${ids.length} registros marcados como usados en mediciones');
        return true;
      } else {
        print('❌ Error al marcar mediciones. Código: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en marcarComoUsadosEnMediciones: $e');
      return false;
    }
  }
}
