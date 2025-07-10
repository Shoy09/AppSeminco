import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import '../models/Empresa.dart';

class ApiServiceEmpresa {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // Método para obtener las empresas desde la API
  Future<List<Empresa>> fetchEmpresa(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.EmpresaEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token', // Token en la cabecera
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<Empresa> empresas = responseData
            .map((data) => Empresa.fromJson(data))
            .toList();

        // Eliminar los datos antiguos antes de insertar los nuevos
        await _dbHelper.deleteAll('Empresa');

        // Guardar los datos en la base de datos local
        await saveEmpresasToLocalDB(empresas);

        return empresas;
      } else {
        throw Exception('Error al obtener las empresas. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  // Guardar empresas en la base de datos local
  Future<void> saveEmpresasToLocalDB(List<Empresa> empresas) async {
    for (var empresa in empresas) {
      Map<String, dynamic> empresaData = empresa.toMap();
      empresaData.remove('id'); // Asegurar que no se inserte el id para evitar conflictos
      await _dbHelper.insert('Empresa', empresaData);
    }
  }
}
