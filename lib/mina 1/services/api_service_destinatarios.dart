import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../database/database_helper.dart';
import '../models/destinatario_correo.dart';

class ApiServiceDestinatarios {
  final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // Método para obtener los destinatarios desde la API
  Future<List<DestinatarioCorreo>> fetchDestinatarios(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.destinatarioCorreoEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<DestinatarioCorreo> destinatarios = responseData
            .map((data) => DestinatarioCorreo.fromJson(data))
            .toList();

        // Eliminar datos antiguos antes de insertar nuevos
        await _dbHelper.deleteAll('destinatarios_correo');

        // Guardar en la base de datos local
        await saveDestinatariosToLocalDB(destinatarios);

        return destinatarios;
      } else {
        throw Exception('Error al obtener los destinatarios. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar destinatarios en la base de datos local
  Future<void> saveDestinatariosToLocalDB(List<DestinatarioCorreo> destinatarios) async {
    for (var destinatario in destinatarios) {
      Map<String, dynamic> destinatarioData = destinatario.toJson();
      destinatarioData.remove('id'); // Evitar conflictos con el ID
      await _dbHelper.insert('destinatarios_correo', destinatarioData);
    }
  }
}
