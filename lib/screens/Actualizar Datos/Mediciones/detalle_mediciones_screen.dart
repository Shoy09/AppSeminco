import 'package:app_seminco/services/Enviar%20nube/perforacion_medicion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import '../../../database/database_helper.dart';

class ListaMedicionesScreen extends StatefulWidget {
  final String tipoPerforacion;

  ListaMedicionesScreen({required this.tipoPerforacion});

  @override
  _DetalleSeccionScreenState createState() => _DetalleSeccionScreenState();
}

class _DetalleSeccionScreenState extends State<ListaMedicionesScreen> {
  List<Map<String, dynamic>> MedicionesData = [];
  Set<int> selectedItems = {};
  Timer? selectionTimer;
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";
  String? selectedMes;
  String? selectedSemana;
int? medicionId;
  @override
  void initState() {
    super.initState();
    _fetchExploracionesData();
  }

  @override
  void dispose() {
    selectionTimer?.cancel();
    super.dispose();
  }

Future<void> _fetchExploracionesData() async {
  setState(() => isLoading = true);
  
  try {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> data = await dbHelper.obtenerPerforacionesConDetalles();

    print('Datos de exploraciones recibidos: $data');

    setState(() {
      MedicionesData = data; // lowerCamelCase

      if (data.isNotEmpty) {
        // Accede a los datos anidados correctamente
        selectedMes = data[0]['perforacion']['mes']; 
        selectedSemana = data[0]['perforacion']['semana'];
        medicionId = data[0]['perforacion']['id'];
      } else {
        selectedMes = null;
        selectedSemana = null;
        medicionId = null;
        mensajeUsuario = "No se encontraron registros de exploraciones.";
      }
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      mensajeUsuario = "Error al cargar los datos: ${e.toString()}";
    });
  }
}

void _handleItemTap(int index) {
  final perforacion = MedicionesData[index]['perforacion'];
  final detalles = MedicionesData[index]['detalles'];
  final perforacionId = perforacion['id'];
  final yaEnviado = perforacion['envio'] == 1;

  // Si ya fue enviado, no permitir selección
  if (yaEnviado) {
    return;
  }

  // Cancelar temporizador anterior si existe
  selectionTimer?.cancel();

  if (selectedItems.contains(perforacionId)) {
    // Si ya está seleccionado, deseleccionar inmediatamente
    setState(() {
      selectedItems.remove(perforacionId);
    });
  } else {
    // Comportamiento diferente según la interacción
    if (selectedItems.isNotEmpty) {
      // Si ya hay seleccionados, seleccionar inmediatamente (modo multi-selección)
      setState(() {
        selectedItems.add(perforacionId);
      });
    } else {
      // Si no hay seleccionados, iniciar temporizador para selección diferida
      selectionTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) { // Verificar que el widget aún esté en el árbol
          setState(() {
            selectedItems.add(perforacionId);
          });
        }
      });
    }
  }
}

  Future<void> _exportSelectedItems() async {
    if (selectedItems.isEmpty) return;

    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> jsonData = [];

    for (var id in selectedItems) {
      List<Map<String, dynamic>> estructuraCompleta = await dbHelper
          .obtenerPerforacionMedicionesEstructura(id);

      // Como `obtenerEstructuraCompleta` devuelve una lista, pero solo hay un dato por ID, tomamos el primer elemento.
      if (estructuraCompleta.isNotEmpty) {
        jsonData.add(estructuraCompleta.first);
      }
    }

    // Mostrar diálogo de confirmación antes de enviar
    await _showConfirmationDialog(jsonData);
  }

Future<void> _showConfirmationDialog(
  List<Map<String, dynamic>> jsonData,
) async {
  String prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);

  bool? confirmado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar envío'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro que deseas enviar los siguientes datos a la nube?'),
              const SizedBox(height: 16),
              Text(
                'Operaciones a enviar: ${jsonData.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contenido JSON:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  prettyJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      );
    },
  );

  if (confirmado == true) {
    await _enviarDatosALaNube(jsonData);
  }
}

  void _confirmarEliminacion() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de eliminar los ${selectedItems.length} registros seleccionados?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarRegistrosSeleccionados();
            },
          ),
        ],
      );
    },
  );
}

Future<void> _eliminarRegistrosSeleccionados() async {
  if (selectedItems.isEmpty) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    DatabaseHelper dbHelper = DatabaseHelper();
    int totalEliminados = 0;

    for (var id in selectedItems) {
      // Esto activará el DELETE CASCADE en todas las tablas relacionadas
      bool result = await dbHelper.eliminarPerforacionPorId(id);
      if (result) totalEliminados++;  // Si el resultado es true, incrementamos el contador
    }

    Navigator.of(context).pop(); // Cierra el loading

    // Actualiza la lista después de eliminar
    await _fetchExploracionesData();

    setState(() {
      selectedItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$totalEliminados registros eliminados correctamente'),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    Navigator.of(context).pop(); // Cierra el loading si hay error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al eliminar: ${e.toString()}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}


Future<void> _enviarDatosALaNube(List<Map<String, dynamic>> jsonData) async {
  final medicionService = PerforacionMedicionService();
  bool allSuccess = true;

  print('==== INICIANDO ENVÍO ====');
  print('Cantidad de operaciones: ${jsonData.length}');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    for (var operacion in jsonData) {
      final prettyJson = const JsonEncoder.withIndent('  ').convert(operacion);
      print('--- Enviando operación ID: ${operacion['id']} ---');
      print('JSON de la operación:\n$prettyJson');

      bool success = await medicionService.crearPerforacion(operacion);

      if (success) {
        print('✅ Operación ${operacion['id']} enviada con éxito');
        await _actualizarEnvio(operacion['id']);
      } else {
        allSuccess = false;
        print('❌ Error al enviar operación: ${operacion['id']}');
      }
    }
  } catch (e) {
    allSuccess = false;
    print('❗ Error inesperado durante el envío: $e');
  }

  Navigator.of(context).pop();
  _showResultDialog(allSuccess);
}


Future<int> _actualizarEnvio(int operacionId) async {
  DatabaseHelper dbHelper = DatabaseHelper();
  return await dbHelper.actualizarEnvioDatos_mediociones(operacionId);
}

  Future<void> _showResultDialog(bool success) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(success ? 'Éxito' : 'Error'),
            content: Text(
              success
                  ? 'Los datos se enviaron correctamente a la nube. La pantalla se actualizará.'
                  : 'Ocurrió un error al enviar algunos datos. Por favor revisa los logs.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Cierra el diálogo de resultado

                  if (success) {
                    // Muestra loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    // Limpiar selecciones + recargar datos
                    await _fetchExploracionesData(); // Espera a que se completen los datos

                    Navigator.of(context).pop(); // Cierra el loading

                    setState(() {
                      selectedItems
                          .clear(); // Limpia selecciones y actualiza UI en un solo setState
                    });
                  }
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Detalles de ${widget.tipoPerforacion}"),
      backgroundColor: const Color(0xFF21899C),
      actions: [
        if (selectedItems.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmarEliminacion,
            tooltip: "Eliminar seleccionados",
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportSelectedItems,
            tooltip: "Exportar seleccionados",
          ),
        ],
      ],
    ),
    body: isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  mensajeUsuario ?? 'Cargando datos...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          )
        : MedicionesData.isEmpty
            ? Center(
                child: Text(
                  mensajeUsuario ?? 'No hay datos disponibles',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Operaciones encontradas:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${selectedItems.length} elemento(s) seleccionado(s)",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: MedicionesData.length,
                      itemBuilder: (context, index) {
                        final perforacion = MedicionesData[index]['perforacion'];
                        final detalles = MedicionesData[index]['detalles'];
                        final isSelected = selectedItems.contains(perforacion['id']);
                        final yaEnviado = perforacion['envio'] == 1;

                        return GestureDetector(
                          onTap: yaEnviado ? null : () => _handleItemTap(index),
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            color: yaEnviado
                                ? Colors.grey[300]
                                : isSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : null,
                            child: ListTile(
                              title: Text("Operación ID: ${perforacion['id']}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Mes: ${perforacion['mes']}, Semana: ${perforacion['semana']}"),
                                  Text("Tipo: ${perforacion['tipo_perforacion']}"),
                                  ...detalles.map((detalle) => Text(
                                    "Labor: ${detalle['labor']}, Avance: ${detalle['avance']}m",
                                  )).toList(),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (yaEnviado)
                                    const Icon(Icons.cloud_done, color: Colors.green),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
  );
}
}
