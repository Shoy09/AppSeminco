import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/screens/Aceros/FormularioDialogEntrada.dart';
import 'package:flutter/material.dart';

class EntradaPage extends StatefulWidget {
  const EntradaPage({super.key});

  @override
  State<EntradaPage> createState() => _EntradaPageState();
}

class _EntradaPageState extends State<EntradaPage> {
  List<Map<String, dynamic>> _entradas = [];
  bool _isInSelectionMode = false;
  Set<int> _selectedIds = {};
  bool _isLoading = true;

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
      barrierDismissible: false, // El usuario debe tocar un botón para cerrar
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
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _eliminarSeleccionadas(); // Proceder con la eliminación
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
        await dbHelper.deleteIngresoAceros2(id);
      }

      // Recargar los datos después de eliminar
      await _cargarEntradas();
      
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
    _cargarEntradas();
  }

  // Función para manejar el cierre del formulario y recargar datos
  void _onFormularioCerrado() {
    _cargarEntradas(); // Recargar datos cuando se cierra el formulario
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entradas.isEmpty
              ? const Center(child: Text('No hay entradas registradas'))
              : ListView.builder(
                  itemCount: _entradas.length,
                  itemBuilder: (context, index) {
                    final entrada = _entradas[index];
                    final isSelected = _selectedIds.contains(entrada['id']);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: isSelected ? Colors.blue[50] : null,
                      child: InkWell(
                        onTap: () {
                          if (_isInSelectionMode) {
                            _toggleSelection(entrada['id']);
                          }
                        },
                        onLongPress: () {
                          if (!_isInSelectionMode) {
                            _enterSelectionMode(entrada['id']);
                          } else {
                            _toggleSelection(entrada['id']);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entrada['proceso']} - ${entrada['tipo_acero']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Fecha: ${entrada['fecha']} | Turno: ${entrada['turno']} | Mes: ${entrada['mes']}'),
                              Text(
                                  'Descripción: ${entrada['descripcion']} | Cantidad: ${entrada['cantidad']}'),
                              const SizedBox(height: 8),
                              _buildStatusChip(entrada['envio'] == 1),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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

  Widget _buildStatusChip(bool enviado) {
    return Chip(
      label: Text(enviado ? 'Enviado' : 'Pendiente'),
      backgroundColor: enviado ? Colors.green[100] : Colors.orange[100],
      labelStyle: TextStyle(
        color: enviado ? Colors.green[800] : Colors.orange[800],
      ),
    );
  }
}