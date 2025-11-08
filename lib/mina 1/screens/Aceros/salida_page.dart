import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/screens/Aceros/FormularioDialogEntrada.dart';
import 'package:app_seminco/mina%201/screens/Aceros/FormularioDialogSalida.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalidaPage extends StatefulWidget {
  const SalidaPage({super.key});

  @override
  State<SalidaPage> createState() => _SalidaPageState();
}

class _SalidaPageState extends State<SalidaPage> {
  List<Map<String, dynamic>> _salidas = [];
  List<Map<String, dynamic>> _salidasFiltradas = [];
  bool _isLoading = true;
  bool _isInSelectionMode = false;
  Set<int> _selectedIds = {};
  
  // Variables para el filtro de fechas
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSalidas();
  }

  // Cargar salidas desde la base de datos
  Future<void> _cargarSalidas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salidas = await DatabaseHelper_Mina1().getSalidasAceros();
      setState(() {
        _salidas = salidas;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar salidas: $e')),
      );
    }
  }

  // Función para aplicar filtros
  void _aplicarFiltros() {
    List<Map<String, dynamic>> salidasFiltradas = _salidas;

    // Filtrar por fechas si están seleccionadas
    if (_fechaInicio != null || _fechaFin != null) {
      salidasFiltradas = salidasFiltradas.where((salida) {
        final fechaSalida = _parseFecha(salida['fecha']);
        if (fechaSalida == null) return false;
        
        if (_fechaInicio != null && fechaSalida.isBefore(_fechaInicio!)) {
          return false;
        }
        if (_fechaFin != null && fechaSalida.isAfter(_fechaFin!)) {
          return false;
        }
        return true;
      }).toList();
    }

    setState(() {
      _salidasFiltradas = salidasFiltradas;
    });
  }

  // Función para parsear fechas desde string
  DateTime? _parseFecha(String? fechaString) {
    if (fechaString == null) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(fechaString);
    } catch (e) {
      return null;
    }
  }

  // Función para seleccionar fecha
  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          _fechaInicioController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _fechaFin = picked;
          _fechaFinController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
        _aplicarFiltros();
      });
    }
  }

  // Función para limpiar filtros
  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _fechaInicioController.clear();
      _fechaFinController.clear();
      _salidasFiltradas = _salidas;
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _isInSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isInSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Mostrar diálogo de confirmación antes de eliminar
  Future<void> _mostrarDialogoConfirmacion() async {
    final cantidad = _selectedIds.length;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar $cantidad salida${cantidad > 1 ? 's' : ''} seleccionada${cantidad > 1 ? 's' : ''}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarSeleccionadas();
              },
            ),
          ],
        );
      },
    );
  }

  // Eliminar salidas seleccionadas de la base de datos
  Future<void> _eliminarSeleccionadas() async {
    final cantidadEliminar = _selectedIds.length;
    
    try {
      final dbHelper = DatabaseHelper_Mina1();
      
      for (final id in _selectedIds) {
        await dbHelper.deleteSalidaAceros2(id);
      }

      await _cargarSalidas();
      
      setState(() {
        _selectedIds.clear();
        _isInSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$cantidadEliminar salida${cantidadEliminar > 1 ? 's' : ''} eliminada${cantidadEliminar > 1 ? 's' : ''} correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar salidas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recargarDatos() {
    _cargarSalidas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isInSelectionMode
            ? Text('${_selectedIds.length} seleccionadas')
            : const Text('Salidas de Material'),
        backgroundColor: const Color(0xFF21899C),
        actions: [
          if (_isInSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _mostrarDialogoConfirmacion,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _recargarDatos,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de Filtros
          _buildFiltrosSection(),
          const SizedBox(height: 8),
          
          // Información de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${_salidasFiltradas.length} salida${_salidasFiltradas.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                if (_fechaInicio != null || _fechaFin != null)
                  Text(
                    'Filtrado por fecha',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Tabla de salidas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _salidasFiltradas.isEmpty
                    ? const Center(child: Text('No hay salidas registradas'))
                    : _buildTableView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return FormularioDialogSalida(
                onSalidaGuardada: _cargarSalidas,
              );
            },
          );
        },
        backgroundColor: const Color(0xFF21899C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Widget para la sección de filtros
  Widget _buildFiltrosSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filtrar por Rango de Fechas",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF21899C),
              ),
            ),
            const SizedBox(height: 8),
            // Fila única con campos de fecha y botones
            Row(
              children: [
                // Campo Fecha Inicio
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _fechaInicioController,
                    decoration: const InputDecoration(
                      labelText: "Fecha Inicio",
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, true),
                  ),
                ),
                const SizedBox(width: 8),
                // Campo Fecha Fin
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _fechaFinController,
                    decoration: const InputDecoration(
                      labelText: "Fecha Fin",
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, false),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Aplicar Filtros
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt, size: 16),
                    label: const Text("Filtrar", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21899C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _aplicarFiltros,
                  ),
                ),
                const SizedBox(width: 4),
                // Botón Limpiar Filtros
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text("Limpiar", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _limpiarFiltros,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir la tabla
  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 16,
            ),
            child: DataTable(
              border: TableBorder.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
              headingRowColor: WidgetStateProperty.all(const Color(0xFF21899C)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              headingRowHeight: 40,
              dataRowHeight: 40,
              columnSpacing: 12,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Seleccionar", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Fecha", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Turno", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Proceso", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Equipo", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Código", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Operador", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Jefe Guardia", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Tipo Acero", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Expanded(
                    child: Center(
                      child: Text("Cantidad", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Descripción", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Estado", textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
              rows: _salidasFiltradas.map((salida) {
                final isSelected = _selectedIds.contains(salida['id']);
                
                return DataRow(
                  selected: isSelected,
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (isSelected) {
                        return Colors.blue.withOpacity(0.3);
                      }
                      return null;
                    },
                  ),
                  cells: [
                    DataCell(
                      Center(
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value != null) {
                              if (value && !_isInSelectionMode) {
                                _enterSelectionMode(salida['id']);
                              } else {
                                _toggleSelection(salida['id']);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['fecha']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['turno']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['proceso']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['equipo']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['codigo_equipo']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: SizedBox(
                          width: 100,
                          child: Text(
                            salida['operador']?.toString() ?? '',
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: SizedBox(
                          width: 100,
                          child: Text(
                            salida['jefe_guardia']?.toString() ?? '',
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['tipo_acero']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          salida['cantidad']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: SizedBox(
                          width: 120,
                          child: Text(
                            salida['descripcion']?.toString() ?? '',
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: _buildStatusChip(salida['envio'] == 1),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool enviado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: enviado ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enviado ? Colors.green[300]! : Colors.orange[300]!,
          width: 1,
        ),
      ),
      child: Text(
        enviado ? 'Enviado' : 'Pendiente',
        style: TextStyle(
          color: enviado ? Colors.green[800] : Colors.orange[800],
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}