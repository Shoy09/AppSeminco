// lib/services/user_service.dart
import 'package:app_seminco/mina%201/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';

class UserService_mina1 {
  final ApiService_Mina1 _apiService = ApiService_Mina1();
  final String baseUrl = ApiConfig.baseUrl;
  Future<String> login(String codigoDni, String password) async {
    return await _apiService.login(codigoDni, password);  // Ahora retorna el token
  }


   Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener el perfil del usuario');
    }
  }
}
