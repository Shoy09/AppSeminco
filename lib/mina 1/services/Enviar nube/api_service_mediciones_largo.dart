import 'dart:convert';
import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/mina%201/models/Envio%20Api/medicion_largo.dart';
import 'package:http/http.dart' as http;

class ApiServiceMedicionesLargo {
  Future<bool> postMedicionLargo(Map<String, dynamic> medicionData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.medicionesLargoEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(medicionData),
      );

      if (response.statusCode == 201) {
        print('✅ Medición Largo creada con éxito.');
        return true;
      } else if (response.statusCode == 409) {
        print('⚠️ Ya existe una medición largo con ese idnube.');
        return false;
      } else {
        print('❌ Error al crear medición largo. Código: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error en postMedicionLargo: $error');
      return false;
    }
  }
}