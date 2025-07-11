import 'dart:convert';

import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/mina%202/services/api_service.dart';

class OperacionService {
  final ApiService_Mina2 _apiService = ApiService_Mina2();

  // Operaciones de Taladro Largo
Future<List<int>?> crearOperacionLargo(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.post(
      ApiConfig_mina2.operacionLargoEndpoint,
      operacionData,
    );
    
    if (response.statusCode == 201) {
      // Parsear el cuerpo de la respuesta como JSON
      final responseData = json.decode(response.body);
      final ids = List<int>.from(responseData['operaciones_ids'] ?? []);
      return ids;
    }
    return null;
  } catch (e) {
    print('Error al crear operación larga: $e');
    return null;
  }
}

Future<bool> actualizarOperacionLargo(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.put(
      ApiConfig_mina2.operacionLargoEndpointactua,
      operacionData, // Ahora sí es Map<String, dynamic>
    );

    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return true;
    } else if (statusCode == 207) {
      print('Operación actualizada parcialmente: ${response.body}');
      return false;
    } else {
      print('Error del servidor ($statusCode): ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error al actualizar operación larga: $e');
    return false;
  }
}

  // Operaciones Horizontales
Future<List<int>?> crearOperacionHorizontal(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.post(
      ApiConfig_mina2.operacionHorizontalEndpoint,
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

  Future<bool> actualizarOperacionHorizontal(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.put(
      ApiConfig_mina2.operacionHorizontalEndpointActualiza,
      operacionData,
    );

    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return true;
    } else if (statusCode == 207) {
      print('Operación horizontal actualizada parcialmente: ${response.body}');
      return false;
    } else {
      print('Error del servidor al actualizar horizontal ($statusCode): ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error al actualizar operación horizontal: $e');
    return false;
  }
}

  // Operaciones de Sostenimiento
Future<List<int>?> crearOperacionSostenimiento(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.post(
      ApiConfig_mina2.operacionSostenimientoEndpoint,
      operacionData,
    );
    
    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final ids = List<int>.from(responseData['operaciones_ids'] ?? []);
      return ids;
    }
    return null;
  } catch (e) {
    print('Error al crear operación de sostenimiento: $e');
    return null;
  }
}

  Future<bool> actualizarOperacionSostenimiento(Map<String, dynamic> operacionData) async {
  try {
    final response = await _apiService.put(
      ApiConfig_mina2.operacionSostenimientoEndpointActualiza,
      operacionData,
    );

    final statusCode = response.statusCode;

    if (statusCode == 200) {
      return true;
    } else if (statusCode == 207) {
      print('Operación de sostenimiento actualizada parcialmente: ${response.body}');
      return false;
    } else {
      print('Error del servidor al actualizar sostenimiento ($statusCode): ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error al actualizar operación de sostenimiento: $e');
    return false;
  }
}
}