import 'package:app_seminco/config/conect/mina%201/export_functions.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper.dart';

class ConnectivityAutoSyncMina1 {
  static Future<void> tryAutoSync(BuildContext context, String dni) async {
    final dbHelper = DatabaseHelper_Mina1();

    // Buscar si hay registros pendientes en algún módulo
    final largosPendientes = await dbHelper.getOperacionPendienteByTipo("PERFORACIÓN TALADROS LARGOS");
    final horizontalesPendientes = await dbHelper.getOperacionPendienteByTipo("PERFORACIÓN HORIZONTAL");
    final sostenimientoPendientes = await dbHelper.getOperacionPendienteByTipo("SOSTENIMIENTO");
    final carguioPendientes = await dbHelper.getOperacionPendienteByTipo("CARGUÍO");
    final explosivosPendientes = await dbHelper.getExploracionesPendientes();
    final medicionesPendientes = await dbHelper.getMedicionesHorizontalPendientes();
    final ingresosPendientes = await dbHelper.getIngresosPendientes();
    final salidasPendientes = await dbHelper.getSalidasPendientes();

    final totalPendientes = largosPendientes.length +
        horizontalesPendientes.length +
        sostenimientoPendientes.length +
        carguioPendientes.length +
        explosivosPendientes.length +
        medicionesPendientes.length +
        ingresosPendientes.length +
        salidasPendientes.length;

    if (totalPendientes == 0) {
      print("✅ No hay registros pendientes. No se hace nada.");
      return;
    }

    print("📡 Conexión restablecida. Enviando $totalPendientes registros pendientes...");

    // Obtener los datos completos de cada módulo
    final largosCompletos = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN TALADROS LARGOS");
    final horizontalesCompletos = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN HORIZONTAL");
    final sostenimientoCompletos = await dbHelper.getOperacionBytipoOperacion("SOSTENIMIENTO");
    final carguioCompletos = await dbHelper.getOperacionBytipoOperacion("CARGUÍO");
    final explosivosCompletos = await dbHelper.getExploraciones();
    final ingresosCompletos = await dbHelper.getIngresosPendientes();
    final salidasCompletos = await dbHelper.getSalidasPendientes();

    // Filtrar solo los pendientes de cada módulo
    final largosIds = largosPendientes.map((e) => e['id'] as int).toList();
    final horizontalesIds = horizontalesPendientes.map((e) => e['id'] as int).toList();
    final sostenimientoIds = sostenimientoPendientes.map((e) => e['id'] as int).toList();
    final carguioIds = carguioPendientes.map((e) => e['id'] as int).toList();
    final explosivosIds = explosivosPendientes.map((e) => e['id'] as int).toList();
    final medicionesIds = medicionesPendientes.map((e) => e['id'] as int).toList();
    final ingresosIds = ingresosPendientes.map((e) => e['id'] as int).toList();
    final salidasIds = salidasPendientes.map((e) => e['id'] as int).toList();

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
        final success = await ExportFunctions.exportLargoAuto(context, largosIds, largosDataFiltrados);
        if (success) {
          enviados += largosIds.length;
          algunEnvioRealizado = true;
          print("✅ Largos enviados: ${largosIds.length}");
        }
      }

      if (horizontalesIds.isNotEmpty) {
        final success = await ExportFunctions.exportHorizontalAuto(context, horizontalesIds, horizontalesDataFiltrados);
        if (success) {
          enviados += horizontalesIds.length;
          algunEnvioRealizado = true;
          print("✅ Horizontales enviados: ${horizontalesIds.length}");
        }
      }

      if (sostenimientoIds.isNotEmpty) {
        final success = await ExportFunctions.exportSostenimientoAuto(context, sostenimientoIds, sostenimientoDataFiltrados);
        if (success) {
          enviados += sostenimientoIds.length;
          algunEnvioRealizado = true;
          print("✅ Sostenimiento enviados: ${sostenimientoIds.length}");
        }
      }

      if (carguioIds.isNotEmpty) {
        final success = await ExportFunctions.exportCarguioAuto(context, carguioIds, carguioDataFiltrados);
        if (success) {
          enviados += carguioIds.length;
          algunEnvioRealizado = true;
          print("✅ Carguío enviados: ${carguioIds.length}");
        }
      }

      if (explosivosIds.isNotEmpty) {
        final success = await ExportFunctions.exportExplosivosAuto(context, explosivosIds);
        if (success) {
          enviados += explosivosIds.length;
          algunEnvioRealizado = true;
          print("✅ Explosivos enviados: ${explosivosIds.length}");
        }
      }

      if (medicionesIds.isNotEmpty) {
        final success = await ExportFunctions.exportMedicionesHorizontalAuto(context, medicionesIds);
        if (success) {
          enviados += medicionesIds.length;
          algunEnvioRealizado = true;
          print("✅ Mediciones enviados: ${medicionesIds.length}");
        }
      }

      if (ingresosIds.isNotEmpty || salidasIds.isNotEmpty) {
        final success = await ExportFunctions.exportAcerosAuto(context, ingresosIds, salidasIds);
        if (success) {
          enviados += ingresosIds.length + salidasIds.length;
          algunEnvioRealizado = true;
          print("✅ Aceros enviados: ${ingresosIds.length + salidasIds.length}");
        }
      }

      // Mostrar resultado solo si realmente hubo envíos
      if (algunEnvioRealizado && context.mounted) {
        _mostrarNotificacionExito(context, enviados);
      } else if (context.mounted) {
        _mostrarNotificacionInfo(context, "No se pudieron enviar algunos registros. Revisa la conexión.");
      }

    } catch (e) {
      print("❌ Error durante la sincronización automática: $e");
      if (context.mounted) {
        _mostrarNotificacionError(context, "Error durante la sincronización");
      }
    }
  }

  static void _mostrarNotificacionExito(BuildContext context, int enviados) {
    _mostrarNotificacionPersonalizada(
      context,
      "✅ Sincronización completada",
      "Se enviaron $enviados registros pendientes correctamente.",
      Colors.green,
    );
  }

  static void _mostrarNotificacionInfo(BuildContext context, String mensaje) {
    _mostrarNotificacionPersonalizada(
      context,
      "ℹ️ Información",
      mensaje,
      Colors.blue,
    );
  }

  static void _mostrarNotificacionError(BuildContext context, String mensaje) {
    _mostrarNotificacionPersonalizada(
      context,
      "❌ Error",
      mensaje,
      Colors.red,
    );
  }

  static void _mostrarNotificacionPersonalizada(
    BuildContext context,
    String titulo,
    String mensaje,
    Color color,
  ) {
    // Crear un OverlayEntry para mostrar la notificación
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Debajo de la barra de estado
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent, // Fondo transparente
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensaje,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insertar el overlay
    overlay.insert(overlayEntry);

    // Remover automáticamente después de 2 segundos
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  // Alternativa usando SnackBar (más simple)
  static void _mostrarSnackBarPersonalizado(
    BuildContext context,
    String titulo,
    String mensaje,
    Color color,
  ) {
    final snackBar = SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}