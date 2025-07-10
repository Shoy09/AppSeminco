import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/operacion_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart'; // Para Clipboard

class DetalleSostenimientoScreen extends StatefulWidget {
  final String tipoOperacion;

  DetalleSostenimientoScreen({required this.tipoOperacion});

  @override
  _DetalleSeccionScreenState createState() => _DetalleSeccionScreenState();
}

class _DetalleSeccionScreenState extends State<DetalleSostenimientoScreen> {
  List<Map<String, dynamic>> operacionData = [];
  Set<int> selectedItems = {};
  Timer? selectionTimer;
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";
  String? selectedTurno;
  String? selectedEquipo;
  String? selectedCodigo;
  int? operacionId;
  String? estado;
  String? selectedEmpresa;
  List<Map<String, dynamic>> horometrosData = [];
  List<Map<String, dynamic>> interPerforacionesData = [];
  List<Map<String, String>> currentData = [];

  @override
  void initState() {
    super.initState();
    _fetchOperacionData();
  }

  @override
  void dispose() {
    selectionTimer?.cancel();
    super.dispose();
  }

Future<void> _fetchOperacionData() async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> data = 
      await dbHelper.getOperacionBytipoOperacion(widget.tipoOperacion);

  print('Datos recibidos de la base de datos: $data');

  setState(() {
    operacionData = data; // Siempre actualizamos la lista (aunque esté vacía)
    isLoading = false;

    if (data.isNotEmpty) {
      // Si hay datos, establecemos los valores por defecto
      selectedTurno = data[0]['turno'];
      selectedEquipo = data[0]['equipo'];
      selectedEmpresa = data[0]['empresa'];
      operacionId = data[0]['id'];
      estado = data[0]['estado'];
    } else {
      // Si NO hay datos, limpiamos todas las selecciones
      selectedTurno = null;
      selectedEquipo = null;
      selectedEmpresa = null;
      operacionId = null;
      estado = null;
      mensajeUsuario = "No se encontraron registros.";
    }
  });
}

void _handleItemTap(int index) {
  final itemId = operacionData[index]['id'];

  setState(() {
    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }
  });
}

Future<void> _exportSelectedItems() async {
  if (selectedItems.isEmpty) return;

  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> jsonDataList = []; // Cambio a List para múltiples operaciones

  for (var id in selectedItems) {
    var operacion = operacionData.firstWhere((op) => op['id'] == id);
    List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(id);
    List<Map<String, dynamic>> perforaciones = await dbHelper.getPerforacionesTaladroSostenimiento(id);

    List<Map<String, dynamic>> interPerforaciones = [];
    for (var perforacion in perforaciones) {
      int perforacionId = perforacion['id'];
      List<Map<String, dynamic>> interData = await dbHelper.getInterSostenimientos(perforacionId);
      interPerforaciones.addAll(interData);
    }

    List<Map<String, dynamic>> horometros = await dbHelper.getHorometrosByOperacion(id);

    // Limpiar datos de operación
    Map<String, dynamic> operacionSinId = {
      "turno": operacion['turno'],
      "equipo": operacion['equipo'],
      "codigo": operacion['codigo'],
      "empresa": operacion['empresa'],
      "fecha": operacion['fecha'],
      "tipo_operacion": operacion['tipo_operacion'],
      "estado": operacion['estado'] ?? 'activo' // Valor por defecto
    };

    // Limpiar datos de estados
    List<Map<String, dynamic>> estadosLimpios = estados.map((estado) {
      return {
        "numero": estado['numero'],
        "estado": estado['estado'],
        "codigo": estado['codigo'],
        "hora_inicio": estado['hora_inicio'],
        "hora_final": estado['hora_final']
      };
    }).toList();

    // Limpiar datos de sostenimientos
    List<Map<String, dynamic>> sostenimientosLimpios = perforaciones.map((perforacion) {
      int pId = perforacion['id'];
      return {
        "zona": perforacion['zona'],
        "tipo_labor": perforacion['tipo_labor'],
        "labor": perforacion['labor'],
        "ala": perforacion['ala'],
        "veta": perforacion['veta'],
        "nivel": perforacion['nivel'],
        "tipo_perforacion": perforacion['tipo_perforacion'],
        "inter_sostenimientos": interPerforaciones
            .where((ip) => ip['sostenimiento_id'] == pId)
            .map((ip) {
              return {
                "codigo_actividad": ip['codigo_actividad'],
                "nivel": ip['nivel'],
                "labor": ip['labor'],
                "seccion_de_labor": ip['seccion_de_labor'],
                "nbroca": ip['nbroca'],
                "ntaladro": ip['ntaladro'],
                "longitud_perforacion": ip['longitud_perforacion'],
                "malla_instalada": ip['malla_instalada'] ?? false // Valor por defecto
              };
            }).toList()
      };
    }).toList();

    // Limpiar datos de horometros
    List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
      return {
        "nombre": h['nombre'],
        "inicial": h['inicial'],
        "final": h['final']
      };
    }).toList();

    jsonDataList.add({
      "local_id": id,
      "operacion": operacionSinId,
      "estados": estadosLimpios,
      "sostenimientos": sostenimientosLimpios,
      "horometros": horometrosLimpios
    });
  }

  await _showConfirmationDialog(jsonDataList);
}

Future<void> _showConfirmationDialog(List<Map<String, dynamic>> jsonDataList) async {
  final jsonString = JsonEncoder.withIndent('  ').convert(jsonDataList);
  final textController = TextEditingController(text: jsonString);

  bool? confirmado = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirmar envío - Sostenimiento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Estás seguro de enviar estas operaciones de sostenimiento?'),
                  const SizedBox(height: 10),
                  Text('Total: ${jsonDataList.length} operaciones'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmado == true) {
    await _enviarDatosALaNube(jsonDataList);
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
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    int totalEliminados = 0;

    for (var id in selectedItems) {
      // Esto activará el DELETE CASCADE en todas las tablas relacionadas
      int result = await dbHelper.deleteOperacion(id);
      if (result > 0) totalEliminados++;
    }

    Navigator.of(context).pop(); // Cierra el loading

    // Actualiza la lista después de eliminar
    await _fetchOperacionData();

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
  final operacionService = OperacionService();
  bool allSuccess = true;
  int successfulUploads = 0;

  // Mostrar indicador de carga
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    for (var operacion in jsonData) {
      int localId = operacion['local_id'];
      print('Enviando a la nube operación con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final idsNube = await operacionService.crearOperacionSostenimiento(operacionSinLocalId);

      if (idsNube != null && idsNube.isNotEmpty) {
        final idNube = idsNube.first;

        await _actualizarEnvio(localId);
        await _actualizarIdNubeOperacion(localId, idNube);

        successfulUploads++;
        print('Operación local $localId ahora tiene ID nube $idNube');
      } else {
        allSuccess = false;
        print('Error: No se recibieron IDs de la nube para operación local $localId');
      }
    }
  } catch (e) {
    allSuccess = false;
    print('Error durante el envío: $e');
  }

  Navigator.of(context).pop();

  if (allSuccess) {
    _showSuccessDialog(successfulUploads);
  } else {
    _showPartialSuccessDialog(successfulUploads, jsonData.length - successfulUploads);
  }
}

// Nuevo método para mostrar éxito total
void _showSuccessDialog(int count) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Éxito'),
      content: Text('Se enviaron correctamente $count operaciones'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// Nuevo método para mostrar éxito parcial
void _showPartialSuccessDialog(int successCount, int failedCount) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Resultado parcial'),
      content: Text('''
Operaciones exitosas: $successCount
Operaciones fallidas: $failedCount
      '''),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
} 

Future<int> _actualizarIdNubeOperacion(int idOperacion, int idNube) async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  return await dbHelper.actualizarIdNubeOperacion(idOperacion, idNube);
}

  Future<int> _actualizarEnvio(int operacionId) async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    return await dbHelper.actualizarEnvio(operacionId);
  }

  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Éxito' : 'Error'),
        content: Text(
          success
              ? 'Los datos se enviaron correctamente a la nube.'
              : 'Ocurrió un error al enviar algunos datos. Por favor revisa los logs.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (success) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                await _fetchOperacionData();
                Navigator.of(context).pop();
                setState(() {
                  selectedItems.clear();
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
        title: Text("Detalles de ${widget.tipoOperacion}"),
        backgroundColor: Color(0xFF21899C),
        actions: [
          if (selectedItems.isNotEmpty)
          IconButton(
        icon: Icon(Icons.delete),
        onPressed: _confirmarEliminacion,
        tooltip: "Eliminar seleccionados",
      ),
            IconButton(
              icon: Icon(Icons.file_download),
              onPressed: _exportSelectedItems,
              tooltip: "Exportar seleccionados",
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(mensajeUsuario, style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : operacionData.isEmpty
              ? Center(
                  child: Text(mensajeUsuario, style: TextStyle(fontSize: 16)),
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
                        itemCount: operacionData.length,
                        itemBuilder: (context, index) {
                          var item = operacionData[index];
                          final isSelected = selectedItems.contains(item['id']);
                          final yaEnviado = item['envio'] == 1;
                          return GestureDetector(
                            onTap: () => _handleItemTap(index),
                            child: Card(
                              margin: EdgeInsets.all(8),
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : null,
                              child: ListTile(
                                title: Text("Operación ID: ${item['id']}"),
                                subtitle: Text(
                                  "Turno: ${item['turno']}, Equipo: ${item['equipo']}, Fecha: ${item['fecha']}, Tipo: ${item['tipo_operacion']}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Estado: ${item['estado']}"),
                                    if (yaEnviado)
                                      Icon(Icons.cloud_done, color: Colors.green),
                                    if (isSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
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