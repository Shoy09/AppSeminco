

import 'package:app_seminco/config/conect/mina%202/export_functions.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:flutter/material.dart';

class ConnectivityAutoSyncMina2 {
  static Future<void> tryAutoSync(BuildContext context, String dni) async {
    final dbHelper = DatabaseHelper_Mina2();

    // Buscar si hay registros pendientes en algún módulo
    final largosPendientes = await dbHelper.getOperacionPendienteByTipo("PERFORACIÓN TALADROS LARGOS");
    final horizontalesPendientes = await dbHelper.getOperacionPendienteByTipo("PERFORACIÓN HORIZONTAL");
    final sostenimientoPendientes = await dbHelper.getOperacionPendienteByTipo("SOSTENIMIENTO");
    final carguioPendientes = await dbHelper.getOperacionPendienteByTipo("CARGUÍO");
    final explosivosPendientes = await dbHelper.getExploracionesPendientes();
    // final medicionesPendientes = await dbHelper.getMedicionesPendientes(); // Descomenta cuando implementes

    final totalPendientes = largosPendientes.length +
        horizontalesPendientes.length +
        sostenimientoPendientes.length +
        carguioPendientes.length +
        explosivosPendientes.length;
        // + medicionesPendientes.length; // Agrega cuando implementes

    if (totalPendientes == 0) {
      print("✅ Mina 2: No hay registros pendientes. No se hace nada.");
      return;
    }

    print("📡 Mina 2: Conexión restablecida. Enviando $totalPendientes registros pendientes...");

    // Obtener los datos completos de cada módulo
    final largosCompletos = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN TALADROS LARGOS");
    final horizontalesCompletos = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN HORIZONTAL");
    final sostenimientoCompletos = await dbHelper.getOperacionBytipoOperacion("SOSTENIMIENTO");
    final carguioCompletos = await dbHelper.getOperacionBytipoOperacion("CARGUÍO");
    final explosivosCompletos = await dbHelper.getExploraciones();
    // final medicionesCompletos = await dbHelper.obtenerPerforacionesConDetalles(); // Descomenta cuando implementes

    // Filtrar solo los pendientes de cada módulo
    final largosIds = largosPendientes.map((e) => e['id'] as int).toList();
    final horizontalesIds = horizontalesPendientes.map((e) => e['id'] as int).toList();
    final sostenimientoIds = sostenimientoPendientes.map((e) => e['id'] as int).toList();
    final carguioIds = carguioPendientes.map((e) => e['id'] as int).toList();
    final explosivosIds = explosivosPendientes.map((e) => e['id'] as int).toList();
    // final medicionesIds = medicionesPendientes.map((e) => e['id'] as int).toList(); // Descomenta cuando implementes

    // Filtrar datos completos para incluir solo los pendientes
    final largosDataFiltrados = largosCompletos.where((op) => largosIds.contains(op['id'])).toList();
    final horizontalesDataFiltrados = horizontalesCompletos.where((op) => horizontalesIds.contains(op['id'])).toList();
    final sostenimientoDataFiltrados = sostenimientoCompletos.where((op) => sostenimientoIds.contains(op['id'])).toList();
    final carguioDataFiltrados = carguioCompletos.where((op) => carguioIds.contains(op['id'])).toList();

    // Llamar métodos de envío (sin mostrar diálogos)
    int enviados = 0;
    bool algunEnvioRealizado = false;

    try {
      if (largosIds.isNotEmpty) {
        final success = await ExportFunctionsminaw2.exportLargoAuto(context, largosIds, largosDataFiltrados);
        if (success) {
          enviados += largosIds.length;
          algunEnvioRealizado = true;
          print("✅ Mina 2 - Largos enviados: ${largosIds.length}");
        }
      }

      if (horizontalesIds.isNotEmpty) {
        final success = await ExportFunctionsminaw2.exportHorizontalAuto(context, horizontalesIds, horizontalesDataFiltrados);
        if (success) {
          enviados += horizontalesIds.length;
          algunEnvioRealizado = true;
          print("✅ Mina 2 - Horizontales enviados: ${horizontalesIds.length}");
        }
      }

      if (sostenimientoIds.isNotEmpty) {
        final success = await ExportFunctionsminaw2.exportSostenimientoAuto(context, sostenimientoIds, sostenimientoDataFiltrados);
        if (success) {
          enviados += sostenimientoIds.length;
          algunEnvioRealizado = true;
          print("✅ Mina 2 - Sostenimiento enviados: ${sostenimientoIds.length}");
        }
      }

      if (carguioIds.isNotEmpty) {
        final success = await ExportFunctionsminaw2.exportCarguioAuto(context, carguioIds, carguioDataFiltrados);
        if (success) {
          enviados += carguioIds.length;
          algunEnvioRealizado = true;
          print("✅ Mina 2 - Carguío enviados: ${carguioIds.length}");
        }
      }

      if (explosivosIds.isNotEmpty) {
        final success = await ExportFunctionsminaw2.exportExplosivosAuto(context, explosivosIds);
        if (success) {
          enviados += explosivosIds.length;
          algunEnvioRealizado = true;
          print("✅ Mina 2 - Explosivos enviados: ${explosivosIds.length}");
        }
      }

      // Descomenta cuando implementes las mediciones
      // if (medicionesIds.isNotEmpty) {
      //   final success = await ExportFunctionsminaw2.exportMedicionesAuto(context, medicionesIds, medicionesCompletos);
      //   if (success) {
      //     enviados += medicionesIds.length;
      //     algunEnvioRealizado = true;
      //     print("✅ Mina 2 - Mediciones enviados: ${medicionesIds.length}");
      //   }
      // }

      // Mostrar resultado solo si realmente hubo envíos
      if (algunEnvioRealizado && context.mounted) {
        _mostrarDialogoExito(context, enviados);
      } else if (context.mounted) {
        _mostrarDialogoInfo(context, "No se pudieron enviar algunos registros. Revisa la conexión.");
      }

    } catch (e) {
      print("❌ Mina 2: Error durante la sincronización automática: $e");
      if (context.mounted) {
        _mostrarDialogoError(context, "Error durante la sincronización: $e");
      }
    }
  }

  static void _mostrarDialogoExito(BuildContext context, int enviados) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("✅ Sincronización completada - Mina 2"),
        content: Text("Se enviaron $enviados registros pendientes correctamente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  static void _mostrarDialogoInfo(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ℹ️ Información - Mina 2"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  static void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("❌ Error - Mina 2"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }
}