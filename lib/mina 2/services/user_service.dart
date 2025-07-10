// lib/services/user_service.dart
import 'package:app_seminco/mina%202/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app_seminco/config/api_config_min02.dart';

class UserService_mina2 {
  final ApiService_Mina2 _ApiService_Mina2 = ApiService_Mina2();
  final String baseUrl = ApiConfig_mina2.baseUrl;
  Future<String> login(String codigoDni, String password) async {
    return await _ApiService_Mina2.login(codigoDni, password);  // Ahora retorna el token
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
