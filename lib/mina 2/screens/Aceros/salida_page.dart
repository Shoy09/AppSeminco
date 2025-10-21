import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/screens/Aceros/FormularioDialogEntrada.dart';
import 'package:app_seminco/mina%202/screens/Aceros/FormularioDialogSalida.dart';
import 'package:flutter/material.dart';

class SalidaPage extends StatefulWidget {
  const SalidaPage({super.key});

  @override
  State<SalidaPage> createState() => _SalidaPageState();
}

class _SalidaPageState extends State<SalidaPage> {
  List<Map<String, dynamic>> _salidas = [];
  bool _isLoading = true;
  bool _isInSelectionMode = false;
  Set<int> _selectedIds = {};

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
      final salidas = await DatabaseHelper_Mina2().getSalidasAceros();
      setState(() {
        _salidas = salidas;
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
      final dbHelper = DatabaseHelper_Mina2();
      
      for (final id in _selectedIds) {
        await dbHelper.deleteSalidaAceros2(id);
      }

      // Recargar los datos después de eliminar
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salidas.isEmpty
              ? const Center(child: Text('No hay salidas registradas'))
              : ListView.builder(
                  itemCount: _salidas.length,
                  itemBuilder: (context, index) {
                    final salida = _salidas[index];
                    final isSelected = _selectedIds.contains(salida['id']);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: isSelected ? Colors.blue[50] : null,
                      child: InkWell(
                        onTap: () {
                          if (_isInSelectionMode) {
                            _toggleSelection(salida['id']);
                          }
                        },
                        onLongPress: () {
                          if (!_isInSelectionMode) {
                            _enterSelectionMode(salida['id']);
                          } else {
                            _toggleSelection(salida['id']);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${salida['proceso']} - ${salida['equipo']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Fecha: ${salida['fecha']} | Turno: ${salida['turno']} | Mes: ${salida['mes']}'),
                              Text(
                                  'Equipo: ${salida['equipo']} (${salida['codigo_equipo']})'),
                              Text(
                                  'Operador: ${salida['operador']} | Jefe de Guardia: ${salida['jefe_guardia']}'),
                              Text(
                                  'Tipo de Acero: ${salida['tipo_acero']} | Cantidad: ${salida['cantidad']}'),
                              if (salida['descripcion'] != null && salida['descripcion'].isNotEmpty)
                                Text('Descripción: ${salida['descripcion']}'),
                              const SizedBox(height: 8),
                              _buildStatusChip(salida['envio'] == 1),
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
              return FormularioDialogSalida(
                onSalidaGuardada: _cargarSalidas, // Recargar después de guardar
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