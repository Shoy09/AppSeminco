
import 'package:app_seminco/mina%201/services/Enviar%20nube/aceros_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import '../../../../../database/database_helper.dart';

class ListaAcerosScreen extends StatefulWidget {
  final String tipoProceso;

  ListaAcerosScreen({required this.tipoProceso});

  @override
  _ListaAcerosScreenState createState() => _ListaAcerosScreenState();
}

class _ListaAcerosScreenState extends State<ListaAcerosScreen> {
  List<Map<String, dynamic>> acerosData = [];
  Set<int> selectedItems = Set();
  Timer? selectionTimer;
  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";

  @override
  void initState() {
    super.initState();
    _fetchAcerosData();
  }

  @override
  void dispose() {
    selectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAcerosData() async {
    setState(() => isLoading = true);
    
    try {
      DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
      
      // Obtener datos de ambas tablas
      List<Map<String, dynamic>> ingresos = await dbHelper.getIngresosAceros();
      List<Map<String, dynamic>> salidas = await dbHelper.getSalidasAceros();
      
      // Combinar y agregar identificador de tipo
      List<Map<String, dynamic>> combinedData = [];
      
      for (var ingreso in ingresos) {
        combinedData.add({...ingreso, 'tipo_registro': 'ingreso'});
      }
      
      for (var salida in salidas) {
        combinedData.add({...salida, 'tipo_registro': 'salida'});
      }
      
      // Ordenar por fecha (opcional)
      combinedData.sort((a, b) => b['fecha'].compareTo(a['fecha']));

      setState(() {
        acerosData = combinedData;
        if (combinedData.isEmpty) {
          mensajeUsuario = "No se encontraron registros de aceros.";
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
    final acero = acerosData[index];
    final registroId = acero['id'];
    final tipoRegistro = acero['tipo_registro'];
    final yaEnviado = acero['envio'] == 1;

    if (yaEnviado) {
      return;
    }

    // Crear un ID único combinando tipo e id
    final uniqueId = _getUniqueId(tipoRegistro, registroId);

    selectionTimer?.cancel();

    if (selectedItems.contains(uniqueId)) {
      setState(() {
        selectedItems.remove(uniqueId);
      });
    } else {
      if (selectedItems.isNotEmpty) {
        setState(() {
          selectedItems.add(uniqueId);
        });
      } else {
        selectionTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              selectedItems.add(uniqueId);
            });
          }
        });
      }
    }
  }

  // Función para crear ID único combinando tipo e id
  int _getUniqueId(String tipo, int id) {
    return tipo == 'ingreso' ? id : -id; // Negativos para salidas
  }

  // Función para extraer tipo e id del ID único
  Map<String, dynamic> _parseUniqueId(int uniqueId) {
    if (uniqueId > 0) {
      return {'tipo': 'ingreso', 'id': uniqueId};
    } else {
      return {'tipo': 'salida', 'id': -uniqueId};
    }
  }

Future<void> _exportSelectedItems() async {
  if (selectedItems.isEmpty) return;

  final dbHelper = DatabaseHelper_Mina1();
  final List<Map<String, dynamic>> ingresosParaEnviar = [];
  final List<Map<String, dynamic>> salidasParaEnviar = [];

  // Separar los registros por tipo
  for (final uniqueId in selectedItems) {
    final parsed = _parseUniqueId(uniqueId);
    final tipo = parsed['tipo'];
    final id = parsed['id'];

    if (tipo == 'ingreso') {
      final ingreso = await dbHelper.obtenerIngresoPorId(id);
      if (ingreso != null) {
        ingresosParaEnviar.add(ingreso);
      }
    } else {
      final salida = await dbHelper.obtenerSalidaPorId(id);
      if (salida != null) {
        salidasParaEnviar.add(salida);
      }
    }
  }

  await _showConfirmationDialog(ingresosParaEnviar, salidasParaEnviar);
}

Future<void> _showConfirmationDialog(
  List<Map<String, dynamic>> ingresosParaEnviar,
  List<Map<String, dynamic>> salidasParaEnviar,
) async {
  final totalIngresos = ingresosParaEnviar.length;
  final totalSalidas = salidasParaEnviar.length;
  final total = totalIngresos + totalSalidas;

  final confirmado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Confirmar envío'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Se enviarán $total registros:'),
          if (totalIngresos > 0) ...[
            const SizedBox(height: 8),
            Text('• Ingresos: $totalIngresos'),
          ],
          if (totalSalidas > 0) ...[
            const SizedBox(height: 8),
            Text('• Salidas: $totalSalidas'),
          ],
        ],
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
    ),
  );

  if (confirmado == true) {
    await _enviarDatosALaNube(ingresosParaEnviar, salidasParaEnviar);
  }
}

Future<void> _enviarDatosALaNube(
  List<Map<String, dynamic>> ingresosParaEnviar,
  List<Map<String, dynamic>> salidasParaEnviar,
) async {
  bool allSuccess = true;
  List<String> errores = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Procesar ingresos
    if (ingresosParaEnviar.isNotEmpty) {
      final ingresoService = AcerosService();
      
      for (var ingreso in ingresosParaEnviar) {
        try {
          bool success = await ingresoService.enviarIngresos(ingreso);
          if (success) {
            await _actualizarEnvio('ingreso', ingreso['id']);
          } else {
            allSuccess = false;
            errores.add("Error al enviar ingreso ID: ${ingreso['id']}");
          }
        } catch (e) {
          allSuccess = false;
          errores.add("Error procesando ingreso ID: ${ingreso['id']} - ${e.toString()}");
        }
      }
    }

    // Procesar salidas
    if (salidasParaEnviar.isNotEmpty) {
      final salidaService = AcerosService();
      
      for (var salida in salidasParaEnviar) {
        try {
          bool success = await salidaService.enviarSalidas(salida);
          if (success) {
            await _actualizarEnvio('salida', salida['id']);
          } else {
            allSuccess = false;
            errores.add("Error al enviar salida ID: ${salida['id']}");
          }
        } catch (e) {
          allSuccess = false;
          errores.add("Error procesando salida ID: ${salida['id']} - ${e.toString()}");
        }
      }
    }

  } catch (e) {
    allSuccess = false;
    errores.add("Error inesperado: ${e.toString()}");
  }

  Navigator.of(context).pop();
  await _showResultDialog(allSuccess, errores);
}

  Future<int> _actualizarEnvio(String tipo, int registroId) async {
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
    if (tipo == 'ingreso') {
      return await dbHelper.actualizarEnvioIngresos([registroId]);
    } else {
      return await dbHelper.actualizarEnvioSalidas([registroId]);
    }
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
                    ? 'Los datos se enviaron correctamente a la nube.'
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
                await _fetchAcerosData();
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
      
      // Separar ingresos y salidas para eliminación
      List<int> ingresosIds = [];
      List<int> salidasIds = [];

      for (final uniqueId in selectedItems) {
        final parsed = _parseUniqueId(uniqueId);
        if (parsed['tipo'] == 'ingreso') {
          ingresosIds.add(parsed['id']);
        } else {
          salidasIds.add(parsed['id']);
        }
      }

      int deletedCount = 0;
      
      if (ingresosIds.isNotEmpty) {
        deletedCount += await dbHelper.deleteIngresoAceros(ingresosIds);
      }
      
      if (salidasIds.isNotEmpty) {
        deletedCount += await dbHelper.deleteSalidaAceros(salidasIds);
      }

      Navigator.of(context).pop();

      await _fetchAcerosData();

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

  Widget _buildAceroCard(int index) {
    final acero = acerosData[index];
    final uniqueId = _getUniqueId(acero['tipo_registro'], acero['id']);
    final isSelected = selectedItems.contains(uniqueId);
    final yaEnviado = acero['envio'] == 1;
    final esIngreso = acero['tipo_registro'] == 'ingreso';

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
                // Header con ID, tipo y estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "ID: ${acero['id']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTipoChip(esIngreso ? 'INGRESO' : 'SALIDA'),
                      ],
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
                
                // Información común
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
                            acero['fecha'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.event_note,
                            "Mes:",
                            acero['mes'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.work,
                            "Turno:",
                            acero['turno'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.settings,
                            "Proceso:",
                            acero['proceso'],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.category,
                            "Tipo acero:",
                            acero['tipo_acero'],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.scale,
                            "Cantidad:",
                            "${acero['cantidad']}",
                          ),
                          const SizedBox(height: 8),
                          if (!esIngreso) ...[
                            _buildInfoRow(
                              Icons.build,
                              "Equipo:",
                              acero['equipo'],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person,
                              "Operador:",
                              acero['operador'],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Descripción (si existe)
                if (acero['descripcion'] != null && acero['descripcion'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.description,
                    "Descripción:",
                    acero['descripcion'],
                  ),
                ],
                
                // Campos específicos de salida
                if (!esIngreso) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (acero['codigo_equipo'] != null && acero['codigo_equipo'].isNotEmpty)
                        _buildFlagChip(
                          "Código: ${acero['codigo_equipo']}",
                          Colors.blue[700]!,
                        ),
                      const SizedBox(width: 8),
                      if (acero['jefe_guardia'] != null && acero['jefe_guardia'].isNotEmpty)
                        _buildFlagChip(
                          "Jefe: ${acero['jefe_guardia']}",
                          Colors.green[700]!,
                        ),
                    ],
                  ),
                ],
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
        title: Text("Registros de Aceros - ${widget.tipoProceso}"),
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
          : acerosData.isEmpty
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
                            "Registros encontrados: ${acerosData.length}",
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
                        itemCount: acerosData.length,
                        itemBuilder: (context, index) {
                          return _buildAceroCard(index);
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

  // Widget auxiliar para construir chips de tipo
  Widget _buildTipoChip(String tipo) {
    final isIngreso = tipo == 'INGRESO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isIngreso ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIngreso ? Colors.green[300]! : Colors.orange[300]!,
          width: 1,
        ),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isIngreso ? Colors.green[800] : Colors.orange[800],
        ),
      ),
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