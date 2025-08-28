import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config_min02.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/checklist_item.dart';

class ApiServiceCheckList {
  final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  /// Obtener checklist desde la API y guardarlo localmente
  Future<List<CheckListItem>> fetchCheckList(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig_mina2.baseUrl}${ApiConfig_mina2.checklistEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<CheckListItem> items = responseData
            .map((data) => CheckListItem.fromJson(data))
            .toList();

        // Eliminar datos antiguos antes de insertar nuevos
        await _dbHelper.deleteAll('checklist_items');

        // Guardar en DB local sin el id
        await saveCheckListToLocalDB(items);

        return items;
      } else {
        throw Exception('Error al cargar el checklist. Código: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error en la solicitud: $error');
    }
  }

  /// Guardar checklist en la base de datos local
  Future<void> saveCheckListToLocalDB(List<CheckListItem> items) async {
    for (var item in items) {
      Map<String, dynamic> itemData = item.toMap();
      itemData.remove('id'); // No insertar id si es autoincremental local
      await _dbHelper.insert('checklist_items', itemData);
    }
  }
}
