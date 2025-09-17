import 'dart:convert';
import 'package:app_seminco/config/api_config.dart';
import 'package:app_seminco/mina%201/models/Envio%20Api/medicion_horizontal.dart';
import 'package:http/http.dart' as http;

class ApiServiceMedicionesHorizontal {
  Future<bool> postMedicionHorizontal(Map<String, dynamic> medicionData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.medicionesHorizontalEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(medicionData), // Ya viene como Map correcto
      );

      if (response.statusCode == 201) {
        print('✅ Medición Horizontal creada con éxito.');
        return true;
      } else if (response.statusCode == 409) {
        print('⚠️ Ya existe una medición horizontal con ese idnube.');
        return false;
      } else {
        print('❌ Error al crear medición horizontal. Código: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error en postMedicionHorizontal: $error');
      return false;
    }
  }

  Future<bool> putMedicionHorizontal(dynamic medicionData) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.medicionesHorizontalEndpoint}/update'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(medicionData),
    );

    if (response.statusCode == 200) {
      print('✅ Medición(es) Horizontal actualizada(s) con éxito.');
      print('Respuesta: ${response.body}');
      return true;
    } else {
      print('❌ Error al actualizar medición horizontal. Código: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return false;
    }
  } catch (error) {
    print('❌ Error en putMedicionHorizontal: $error');
    return false;
  }
}
}