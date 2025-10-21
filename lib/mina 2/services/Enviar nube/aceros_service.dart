import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_seminco/config/api_config.dart';

class AcerosService {
  /// 📌 POST Ingresos (un solo registro)
  Future<bool> enviarIngresos(Map<String, dynamic> ingresoData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ingresosAcerosEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode([ingresoData]), // 👈 convertir a lista
      );

      if (response.statusCode == 201) {
        print("✅ Ingreso enviado correctamente");
        return true;
      } else {
        print("❌ Error al enviar ingreso. Código: ${response.statusCode}");
        print("Respuesta: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Excepción al enviar ingreso: $e");
      return false;
    }
  }

  /// 📌 POST Salidas (un solo registro)
  Future<bool> enviarSalidas(Map<String, dynamic> salidaData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salidasAcerosEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode([salidaData]), // 👈 convertir a lista
      );

      if (response.statusCode == 201) {
        print("✅ Salida enviada correctamente");
        return true;
      } else {
        print("❌ Error al enviar salida. Código: ${response.statusCode}");
        print("Respuesta: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Excepción al enviar salida: $e");
      return false;
    }
  }

  /// 📌 POST Ingresos (lista completa) - método adicional si lo necesitas
  Future<bool> enviarIngresosBatch(List<Map<String, dynamic>> ingresosData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ingresosAcerosEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(ingresosData),
      );

      if (response.statusCode == 201) {
        print("✅ ${ingresosData.length} ingresos enviados correctamente");
        return true;
      } else {
        print("❌ Error al enviar ingresos. Código: ${response.statusCode}");
        print("Respuesta: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Excepción al enviar ingresos: $e");
      return false;
    }
  }

  /// 📌 POST Salidas (lista completa) - método adicional si lo necesitas
  Future<bool> enviarSalidasBatch(List<Map<String, dynamic>> salidasData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.salidasAcerosEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(salidasData),
      );

      if (response.statusCode == 201) {
        print("✅ ${salidasData.length} salidas enviadas correctamente");
        return true;
      } else {
        print("❌ Error al enviar salidas. Código: ${response.statusCode}");
        print("Respuesta: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Excepción al enviar salidas: $e");
      return false;
    }
  }
}