import 'package:app_seminco/database/database_helper.dart';
import 'package:flutter/material.dart';

class ListaPantalla extends StatefulWidget {
  @override
  _ListaPantallaState createState() => _ListaPantallaState();
}

class _ListaPantallaState extends State<ListaPantalla> {
  List<Map<String, dynamic>> perforacionesConDetalles = [];
  Set<int> _selectedPerforacionIds = {};
  bool _isInSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _cargarPerforaciones();
  }

  void _cargarPerforaciones() async {
    try {
      print('Cargando perforaciones...');
      final datos = await DatabaseHelper().obtenerPerforacionesConDetalles();
      print('Perforaciones encontradas: ${datos.length}');

      setState(() {
        perforacionesConDetalles = datos;
      });
    } catch (e) {
      print('Error al cargar perforaciones: $e');
    }
  }

  Future<void> _eliminarPerforacionesSeleccionadas() async {
    if (_selectedPerforacionIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar las ${_selectedPerforacionIds.length} perforaciones seleccionadas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Eliminar todos los seleccionados
        for (final id in _selectedPerforacionIds) {
          await DatabaseHelper().eliminarPerforacionPorId(id);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedPerforacionIds.length} perforaciones eliminadas correctamente')),
        );
        
        _cargarPerforaciones();
        setState(() {
          _selectedPerforacionIds.clear();
          _isInSelectionMode = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar las perforaciones')),
        );
      }
    }
  }

  void _toggleSelection(int perforacionId) {
    setState(() {
      if (_selectedPerforacionIds.contains(perforacionId)) {
        _selectedPerforacionIds.remove(perforacionId);
        if (_selectedPerforacionIds.isEmpty) {
          _isInSelectionMode = false;
        }
      } else {
        _selectedPerforacionIds.add(perforacionId);
        _isInSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(int firstSelectedId) {
    setState(() {
      _selectedPerforacionIds.add(firstSelectedId);
      _isInSelectionMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isInSelectionMode 
            ? Text('${_selectedPerforacionIds.length} seleccionadas')
            : Text('Lista de Perforaciones'),
        backgroundColor: Color(0xFF21899C),
        actions: [
          if (_isInSelectionMode)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _eliminarPerforacionesSeleccionadas,
            ),
        ],
      ),
      body: perforacionesConDetalles.isEmpty
          ? Center(child: Text('No hay datos'))
          : ListView.builder(
              itemCount: perforacionesConDetalles.length,
              itemBuilder: (context, index) {
                final perf = perforacionesConDetalles[index]['perforacion'];
                final detalles = perforacionesConDetalles[index]['detalles'] as List<Map<String, dynamic>>;
                final isSelected = _selectedPerforacionIds.contains(perf['id']);

                return Card(
                  margin: EdgeInsets.all(8),
                  color: isSelected ? Colors.blue[50] : null,
                  child: InkWell(
                    onTap: () {
                      if (_isInSelectionMode) {
                        _toggleSelection(perf['id']);
                      }
                    },
                    onLongPress: () {
                      if (!_isInSelectionMode) {
                        _enterSelectionMode(perf['id']);
                      } else {
                        _toggleSelection(perf['id']);
                      }
                    },
                    child: Stack(
                      children: [
                        ExpansionTile(
                          title: Row(
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.check_circle, color: Colors.green),
                                ),
                              Expanded(
                                child: Text('Perforación - ${perf['tipo_perforacion']}'),
                              ),
                            ],
                          ),
                          subtitle: Text('Mes: ${perf['mes']} | Semana: ${perf['semana']}'),
                          children: detalles.map((d) {
                            return ListTile(
                              title: Text('${d['labor']}'),
                              subtitle: Row(
                                children: [
                                  Text('Registros: ${d['cant_regis']}'),
                                  SizedBox(width: 10),
                                  Text('Avance: ${d['avance']} m'),
                                  SizedBox(width: 10),
                                  Text('Kg Explo: ${d['kg_explo']}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        if (_isInSelectionMode)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: isSelected 
                                    ? Icon(Icons.check_box, color: Colors.blue)
                                    : Icon(Icons.check_box_outline_blank, color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}