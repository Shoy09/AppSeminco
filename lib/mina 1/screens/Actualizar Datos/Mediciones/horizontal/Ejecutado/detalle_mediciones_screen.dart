import 'package:app_seminco/mina%201/models/Envio%20Api/medicion_horizontal.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/api_service_mediciones_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import '../../../../../../database/database_helper.dart';

class ListaMedicionesScreen extends StatefulWidget {
  final String tipoPerforacion;

  ListaMedicionesScreen({required this.tipoPerforacion});

  @override
  _DetalleSeccionScreenState createState() => _DetalleSeccionScreenState();
}

class _DetalleSeccionScreenState extends State<ListaMedicionesScreen> {
  List<Map<String, dynamic>> medicionesData = [];
  Set<int> selectedItems = {};
  Timer? selectionTimer;
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";

  @override
  void initState() {
    super.initState();
    _fetchMedicionesData();
  }

  @override
  void dispose() {
    selectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMedicionesData() async {
    setState(() => isLoading = true);
    
    try {
      DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
      List<Map<String, dynamic>> data = await dbHelper.obtenerTodasMedicionesHorizontal();

      setState(() {
        medicionesData = data;
        if (data.isEmpty) {
          mensajeUsuario = "No se encontraron registros de mediciones.";
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
    final medicion = medicionesData[index];
    final medicionId = medicion['id'];
    final yaEnviado = medicion['envio'] == 1;

    if (yaEnviado) {
      return;
    }

    selectionTimer?.cancel();

    if (selectedItems.contains(medicionId)) {
      setState(() {
        selectedItems.remove(medicionId);
      });
    } else {
      if (selectedItems.isNotEmpty) {
        setState(() {
          selectedItems.add(medicionId);
        });
      } else {
        selectionTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              selectedItems.add(medicionId);
            });
          }
        });
      }
    }
  }

Future<void> _exportSelectedItems() async {
  if (selectedItems.isEmpty) return;

  final dbHelper = DatabaseHelper_Mina1();
  final List<Map<String, dynamic>> jsonCrear = [];
  final List<Map<String, dynamic>> jsonActualizar = [];

  for (final id in selectedItems) {
    final medicion = await dbHelper.obtenerMedicionHorizontalPorId(id);
    if (medicion == null) continue;

    // si trae idNube_medicion (no null y >0) lo mandamos a actualizar
    if (medicion['idNube_medicion'] != null && medicion['idNube_medicion'] != 0) {
      // copiar y transformar el campo
      final updateMap = Map<String, dynamic>.from(medicion);
      updateMap['id'] = updateMap['idNube_medicion']; // la API espera "id"
      updateMap.remove('idNube_medicion');
      jsonActualizar.add(updateMap);
    } else {
      jsonCrear.add(medicion);
    }
  }
  

  await _showConfirmationDialog(jsonCrear, jsonActualizar);
}

Future<void> _showConfirmationDialog(
  List<Map<String, dynamic>> jsonCrear,
  List<Map<String, dynamic>> jsonActualizar,
) async {
  final total = jsonCrear.length + jsonActualizar.length;

  final confirmado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Confirmar envío'),
      content: Text('Se enviarán $total registros '
          '(${
            jsonCrear.length
          } nuevos, ${jsonActualizar.length} para actualizar)'),
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
    ),
  );

  if (confirmado == true) {
    if (jsonCrear.isNotEmpty) await _enviarDatosALaNube(jsonCrear);
    if (jsonActualizar.isNotEmpty) await _actualizarDatosEnLaNube(jsonActualizar);
  }
}

Future<void> _actualizarDatosEnLaNube(List<Map<String, dynamic>> jsonData) async {
  final medicionService = ApiServiceMedicionesHorizontal();
  bool allSuccess = true;
  List<String> errores = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // aquí puedes llamar a put de golpe si tu API soporta array
    final success = await medicionService.putMedicionHorizontal(jsonData);
    if (success) {
      for (final item in jsonData) {
        await _actualizarEnvio(item['id_local'] ?? item['id']); 
        // si necesitas marcar localmente, usa el id local (el autoincrement)
      }
    } else {
      allSuccess = false;
      errores.add('Error al actualizar registros');
    }
  } catch (e) {
    allSuccess = false;
    errores.add('Error inesperado: ${e.toString()}');
  }

  Navigator.of(context).pop();
  await _showResultDialog(allSuccess, errores);
}


Future<void> _enviarDatosALaNube(List<Map<String, dynamic>> jsonData) async {
  final medicionService = ApiServiceMedicionesHorizontal();
  final exploracionService = ExploracionService();
  bool allSuccess = true;
  List<String> errores = [];
  List<int> idsNubeParaMarcar = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Paso 1: Enviar todas las mediciones horizontales
    for (var medicionMap in jsonData) {
      try {
        final medicion = MedicionHorizontal.fromJson(medicionMap);
        bool success = await medicionService.postMedicionHorizontal(medicion.toApiJson());

        if (success) {
          await _actualizarEnvio(medicionMap['id']);
          
          // Si tiene idnube, lo agregamos a la lista para marcar
          if (medicionMap['idnube'] != null) {
            idsNubeParaMarcar.add(medicionMap['idnube']);
          }
        } else {
          allSuccess = false;
          errores.add("Error al enviar medición ID: ${medicionMap['id']}");
        }
      } catch (e) {
        allSuccess = false;
        errores.add("Error procesando medición ID: ${medicionMap['id']} - ${e.toString()}");
      }
    }

    // Paso 2: Marcar los registros como usados en mediciones (solo si hay ids)
    if (idsNubeParaMarcar.isNotEmpty) {
      bool marcadoExitoso = await exploracionService.marcarComoUsadosEnMediciones(idsNubeParaMarcar);
      
      if (!marcadoExitoso) {
        allSuccess = false;
        errores.add("Error al marcar registros como usados en mediciones");
      }
    }

  } catch (e) {
    allSuccess = false;
    errores.add("Error inesperado: ${e.toString()}");
  }

  Navigator.of(context).pop();
  await _showResultDialog(allSuccess, errores);
}



  Future<int> _actualizarEnvio(int medicionId) async {
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    return await dbHelper.actualizarEnvioMedicionesHorizontal([medicionId]);
  }

Future<void> _showResultDialog(bool success, List<String> errores) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(success ? 'Éxito' : 'Error'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              success
                  ? 'Los datos se enviaron correctamente a la nube y se marcaron los registros correspondientes.'
                  : 'Ocurrieron algunos errores durante el proceso:',
            ),
            if (errores.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Detalles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...errores.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('- $e', style: const TextStyle(fontSize: 14)),
              )).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            if (success) {
              await _fetchMedicionesData();
              setState(() => selectedItems.clear());
            }
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
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
      int deletedCount = await dbHelper.eliminarMultiplesMedicionesHorizontal(selectedItems.toList());

      Navigator.of(context).pop();

      await _fetchMedicionesData();

      setState(() {
        selectedItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount registros eliminados correctamente'),
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



  Widget _buildMedicionCard(int index) {
    final medicion = medicionesData[index];
    final isSelected = selectedItems.contains(medicion['id']);
    final yaEnviado = medicion['envio'] == 1;
    final noAplica = medicion['no_aplica'] == 1 ? "Sí" : "No";
    final remanente = medicion['remanente'] == 1 ? "Sí" : "No";

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
          onTap: yaEnviado ? null : () => _handleItemTap(index),
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
                      "ID: ${medicion['id']}",
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
                
                // Información principal en dos columnas
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
                            medicion['fecha'],
                          ),
                           const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.event_note,
                          "Semana:",
                          medicion['semana'] ?? "-", // <-- Nuevo campo agregado
                        ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.work,
                            "Turno:",
                            medicion['turno'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.place,
                            "Zona:",
                            medicion['zona'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.engineering,
                            "Labor:",
                            medicion['labor'],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.terrain,
                            "Veta:",
                            medicion['veta'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.trending_up,
                            "Avance programado:",
                            "${medicion['avance_programado']}m",
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.aspect_ratio,
                            "Dimensiones:",
                            "${medicion['ancho']}m x ${medicion['alto']}m",
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.local_fire_department,
                            "Explosivos:",
                            "${medicion['kg_explosivos']}kg",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Flags de No aplica y Remanente
                Row(
                  children: [
                    _buildFlagChip(
                      "No aplica: $noAplica",
                      noAplica == "Sí" 
                        ? Colors.orange[800]! 
                        : Colors.grey[600]!,
                    ),
                    const SizedBox(width: 8),
                    _buildFlagChip(
                      "Remanente: $remanente",
                      remanente == "Sí" 
                        ? Colors.purple[700]! 
                        : Colors.grey[600]!,
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
        title: Text("Mediciones de ${widget.tipoPerforacion}"),
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
          : medicionesData.isEmpty
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
                            "Mediciones encontradas: ${medicionesData.length}",
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
                        itemCount: medicionesData.length,
                        itemBuilder: (context, index) {
                          return _buildMedicionCard(index);
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
