import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/carguio_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class ListaCarguiosScreen extends StatefulWidget {
  final String tipoOperacion;

  ListaCarguiosScreen({required this.tipoOperacion});

  @override
  _ListaCarguiosScreenState createState() => _ListaCarguiosScreenState();
}

class _ListaCarguiosScreenState extends State<ListaCarguiosScreen> {
  List<Map<String, dynamic>> operacionData = [];
  Set<int> selectedItems = {};
  Timer? selectionTimer;
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";

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
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    List<Map<String, dynamic>> data = await dbHelper
        .getOperacionBytipoOperacion(widget.tipoOperacion);

    print('Datos recibidos de la base de datos: $data');

    setState(() {
      operacionData = data;
      isLoading = false;

      if (data.isEmpty) {
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

    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    List<Map<String, dynamic>> jsonDataList = [];

    for (var operacionId in selectedItems) {
      // Obtener datos de la operación principal
      var operacion = operacionData.firstWhere((op) => op['id'] == operacionId);
      
      // Obtener estados relacionados
      List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(operacionId);
      
      // Obtener horómetros relacionados
      List<Map<String, dynamic>> horometros = await dbHelper.getHorometrosByOperacion(operacionId);
      
      // Obtener carguíos relacionados
      List<Map<String, dynamic>> carguios = await dbHelper.getCarguiosByOperacionId(operacionId);

      // Construir operación sin ID
      Map<String, dynamic> operacionSinId = {
        "turno": operacion['turno'],
        "equipo": operacion['equipo'],
        "codigo": operacion['codigo'],
        "empresa": operacion['empresa'],
        "fecha": operacion['fecha'],
        "tipo_operacion": operacion['tipo_operacion'],
        "estado": operacion['estado']
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

      // Limpiar datos de horómetros
      List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final']
        };
      }).toList();

      // Limpiar datos de carguíos
      List<Map<String, dynamic>> carguiosLimpios = carguios.map((carguio) {
        return {
          "nivel": carguio['nivel'],
          "labor_origen": carguio['labor_origen'],
          "material": carguio['material'],
          "labor_destino": carguio['labor_destino'],
          "num_cucharas": carguio['num_cucharas'],
          "observaciones": carguio['observaciones'] ?? ""
        };
      }).toList();

      // Construir el objeto completo para enviar
      jsonDataList.add({
        "local_id": operacionId,
        "operacion": operacionSinId,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "carguios": carguiosLimpios,
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
            title: const Text('Confirmar envío - Carguíos'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Estás seguro de enviar estas operaciones?'),
                  const SizedBox(height: 10),
                  Text('Total: ${jsonDataList.length} operaciones'),
                  const SizedBox(height: 10),
                  const Text(
                    'Datos a enviar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'JSON Preview:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: jsonString));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('JSON copiado al portapapeles')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              jsonString,
                              style: const TextStyle(fontFamily: 'Monospace', fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Incluye: Operación, Estados, Horómetros y Carguíos',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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

  Future<void> _enviarDatosALaNube(List<Map<String, dynamic>> jsonData) async {
    final carguioService = CarguioService();
    bool allSuccess = true;
    int successfulUploads = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var operacion in jsonData) {
        int localId = operacion['local_id'];
        print('Enviando a la nube operación de carguío con ID local: $localId');

        // Crea una copia sin 'local_id'
        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        // Envía los datos y espera la respuesta con los IDs de la nube
        final idsNube = await carguioService.enviarCarguio(operacionSinLocalId);

        if (idsNube != null && idsNube.isNotEmpty) {
          final idNube = idsNube.first;

          await _actualizarEnvio(localId);
          await _actualizarIdNubeOperacion(localId, idNube);

          successfulUploads++;
          print('Operación de carguío local $localId ahora tiene ID nube $idNube');
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

    // Mostrar resultados
    if (allSuccess) {
      _showSuccessDialog(successfulUploads);
    } else {
      _showPartialSuccessDialog(successfulUploads, jsonData.length - successfulUploads);
    }
  }
 
  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Éxito'),
        content: Text('Se enviaron correctamente $count operaciones de carguío'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshAfterSuccess();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
            onPressed: () {
              Navigator.of(context).pop();
              _refreshAfterSuccess();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAfterSuccess() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await _fetchOperacionData();

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        selectedItems.clear();
      });
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
      DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
      int totalEliminados = 0;

      for (var id in selectedItems) {
        // Esto activará el DELETE CASCADE en todas las tablas relacionadas (incluyendo Carguio)
        int result = await dbHelper.deleteOperacion(id);
        if (result > 0) totalEliminados++;
      }

      Navigator.of(context).pop();

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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<int> _actualizarEnvio(int operacionId) async {
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    return await dbHelper.actualizarEnvio(operacionId);
  }

  Future<int> _actualizarIdNubeOperacion(int idOperacion, int idNube) async {
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    return await dbHelper.actualizarIdNubeOperacion(idOperacion, idNube);
  }

  Widget _buildOperacionCard(int index) {
    var item = operacionData[index];
    final isSelected = selectedItems.contains(item['id']);
    final yaEnviado = item['envio'] == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Colors.blue, width: 1.5)
              : BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        color: yaEnviado
            ? Colors.grey[100]
            : isSelected
                ? Colors.blue.withOpacity(0.05)
                : Colors.white,
        child: InkWell(
          onTap: () => _handleItemTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ID y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Operación ID: ${item['id']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    Row(
                      children: [
                        if (yaEnviado)
                          Icon(Icons.cloud_done,
                              color: Colors.green[700], size: 20),
                        if (isSelected)
                          Icon(Icons.check_circle, color: Colors.blue, size: 20),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Información de la operación
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.calendar_today,
                            "Fecha:",
                            item['fecha'] ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.work,
                            "Turno:",
                            item['turno'] ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.settings,
                            "Equipo:",
                            item['equipo'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.business,
                            "Empresa:",
                            item['empresa'] ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.tag,
                            "Código:",
                            item['codigo'] ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.assignment,
                            "Estado:",
                            item['estado'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Tipo de operación
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFlagChip(
                      "Tipo: ${item['tipo_operacion'] ?? 'N/A'}",
                      const Color(0xFF21899C),
                    ),
                    const SizedBox(width: 8),
                    _buildFlagChip(
                      yaEnviado ? "Enviado a nube" : "Pendiente de envío",
                      yaEnviado ? Colors.green[700]! : Colors.orange[700]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Operaciones de Carguío - ${widget.tipoOperacion}"),
        backgroundColor: const Color(0xFF21899C),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
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
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF21899C)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    mensajeUsuario,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : operacionData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        mensajeUsuario,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Operaciones encontradas: ${operacionData.length}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (selectedItems.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${selectedItems.length} seleccionado(s)",
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: operacionData.length,
                        itemBuilder: (context, index) {
                          return _buildOperacionCard(index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // Widget auxiliar para construir filas de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF21899C)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: "$label ",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para construir chips de estado
  Widget _buildFlagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}