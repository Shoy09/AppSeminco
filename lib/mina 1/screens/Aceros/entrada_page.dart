import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/screens/Aceros/FormularioDialogEntrada.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntradaPage extends StatefulWidget {
  const EntradaPage({super.key});

  @override
  State<EntradaPage> createState() => _EntradaPageState();
}

class _EntradaPageState extends State<EntradaPage> {
  List<Map<String, dynamic>> _entradas = [];
  List<Map<String, dynamic>> _entradasFiltradas = [];
  bool _isInSelectionMode = false;
  Set<int> _selectedIds = {};
  bool _isLoading = true;
  
  // Variables para el filtro de fechas
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEntradas();
  }

  // Cargar entradas desde la base de datos
  Future<void> _cargarEntradas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper_Mina1().getIngresosAceros();
      setState(() {
        _entradas = data;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar entradas: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  // Función para aplicar filtros
  void _aplicarFiltros() {
    List<Map<String, dynamic>> entradasFiltradas = _entradas;

    // Filtrar por fechas si están seleccionadas
    if (_fechaInicio != null || _fechaFin != null) {
      entradasFiltradas = entradasFiltradas.where((entrada) {
        final fechaEntrada = _parseFecha(entrada['fecha']);
        if (fechaEntrada == null) return false;
        
        if (_fechaInicio != null && fechaEntrada.isBefore(_fechaInicio!)) {
          return false;
        }
        if (_fechaFin != null && fechaEntrada.isAfter(_fechaFin!)) {
          return false;
        }
        return true;
      }).toList();
    }

    setState(() {
      _entradasFiltradas = entradasFiltradas;
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
      _entradasFiltradas = _entradas;
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

 Future<void> _mostrarDialogoConfirmacion() async {
    final cantidad = _selectedIds.length;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar $cantidad entrada${cantidad > 1 ? 's' : ''} seleccionada${cantidad > 1 ? 's' : ''}?',
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

  // Eliminar entradas seleccionadas de la base de datos
  Future<void> _eliminarSeleccionadas() async {
    final cantidadEliminar = _selectedIds.length;
    
    try {
      final dbHelper = DatabaseHelper_Mina1();
      
      for (final id in _selectedIds) {
        await dbHelper.deleteIngresoAceros2(id);
      }

      await _cargarEntradas();
      
      setState(() {
        _selectedIds.clear();
        _isInSelectionMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$cantidadEliminar entrada${cantidadEliminar > 1 ? 's' : ''} eliminada${cantidadEliminar > 1 ? 's' : ''} correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar entradas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recargarDatos() {
    _cargarEntradas();
  }

  // Función para manejar el cierre del formulario y recargar datos
  void _onFormularioCerrado() {
    _cargarEntradas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isInSelectionMode
            ? Text('${_selectedIds.length} seleccionadas')
            : const Text('Entradas de Material'),
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
                  'Total: ${_entradasFiltradas.length} entrada${_entradasFiltradas.length != 1 ? 's' : ''}',
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
          
          // Tabla de entradas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entradasFiltradas.isEmpty
                    ? const Center(child: Text('No hay entradas registradas'))
                    : _buildTableView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return FormularioDialogEntrada(
                onEntradaGuardada: _onFormularioCerrado,
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
              columnSpacing: 16,
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
                      child: Text("Tipo Acero", textAlign: TextAlign.center),
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
                      child: Text("Estado", textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
              rows: _entradasFiltradas.map((entrada) {
                final isSelected = _selectedIds.contains(entrada['id']);
                
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
                                _enterSelectionMode(entrada['id']);
                              } else {
                                _toggleSelection(entrada['id']);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          entrada['fecha']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          entrada['turno']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          entrada['proceso']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          entrada['tipo_acero']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: SizedBox(
                          width: 150,
                          child: Text(
                            entrada['descripcion']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          entrada['cantidad']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: _buildStatusChip(entrada['envio'] == 1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enviado ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enviado ? Colors.green[300]! : Colors.orange[300]!,
          width: 1,
        ),
      ),
      child: Text(
        enviado ? 'Enviado' : 'Pendiente',
        style: TextStyle(
          color: enviado ? Colors.green[800] : Colors.orange[800],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}