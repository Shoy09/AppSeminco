import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/PlanMensual.dart';
import 'package:app_seminco/mina%202/models/TipoPerforacion.dart';

class RegistroPerforacionScreen extends StatefulWidget {
  final VoidCallback onDataInserted;
  final int? operacionId; // Agregar operacionId como parámetro opcional
  final String tipoOperacion;
  const RegistroPerforacionScreen({
    Key? key,
    required this.tipoOperacion,
    required this.onDataInserted,
    this.operacionId, // Inicializar en el constructor
  }) : super(key: key);

  @override
  _RegistroPerforacionScreenState createState() =>
      _RegistroPerforacionScreenState();
}

class _RegistroPerforacionScreenState extends State<RegistroPerforacionScreen> {
    String? _selectedZona;
  String? _selectedTipoLabor;
  String? _selectedLabor;
  String? _selectedVeta;
    String? _selectedAla;
  String? _selectedNivel;
  String? _selectedTipoPerforacion;

  final List<String> _zonas = [];
  final List<String> _tiposLabor = [];
  final List<String> _labores = [];
    final List<String> _alas = [];
  final List<String> _vetas = [];
  final List<String> _niveles = [];
  final List<String> _tiposPerforacion = [];

  List<String> _filteredTiposLabor = [];
  List<String> _filteredLabores = [];
    List<String> _filteredAlas = [];
  List<String> _filteredVetas = [];
  List<String> _filteredNiveles = [];
  List<PlanMensual> _planesCompletos = [];

  @override
  void initState() {
    super.initState();
    _getTiposPerforacion(widget.tipoOperacion);
    _getPlanesMen();
  }
  
Future<void> _getTiposPerforacion(String tipoOperacion) async {
  try {
    final dbHelper = DatabaseHelper_Mina2();
    List<TipoPerforacion> tipos = await dbHelper.getTiposPerforacion();

    print("Tipos de Perforación obtenidos de la BD local:");
    for (var tipo in tipos) {
      print("ID: ${tipo.id}, Nombre: ${tipo.nombre}, Proceso: ${tipo.proceso}");
    }

    // Usar un Set para evitar duplicados
    Set<String> tiposSet = {};

    for (var tipo in tipos) {
      if (tipo.proceso == tipoOperacion) { // Filtrar por tipoOperacion
        tiposSet.add(tipo.nombre);
      }
    }

    // Actualizar el estado del widget con la lista filtrada
    setState(() {
      _tiposPerforacion.clear();
      _tiposPerforacion.addAll(tiposSet.where((element) => element.isNotEmpty));
    });

  } catch (e) {
    print("Error al obtener los tipos de perforación: $e");
  }
}

void _guardarPerforacion() async {
  List<String> camposFaltantes = [];

  if (_selectedZona == null) camposFaltantes.add("Zona");
  if (_selectedTipoLabor == null) camposFaltantes.add("Tipo de Labor");
  if (_selectedLabor == null) camposFaltantes.add("Labor");
  if (_selectedVeta == null) camposFaltantes.add("Veta");
  if (_selectedNivel == null) camposFaltantes.add("Nivel");
  if (_selectedTipoPerforacion == null) camposFaltantes.add("Tipo de Perforación");

  if (camposFaltantes.isNotEmpty) {
    String mensajeError = "Falta seleccionar: ${camposFaltantes.join(", ")}";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensajeError),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (widget.operacionId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No se encontró el ID de la operación."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final dbHelper = DatabaseHelper_Mina2();
  int nuevoId = await dbHelper.insertarPerforacionTaladroHorizontal(
    zona: _selectedZona!,
    tipoLabor: _selectedTipoLabor!,
    labor: _selectedLabor!,
    ala: _selectedAla ?? '',
    veta: _selectedVeta!,
    nivel: _selectedNivel!,
    tipoPerforacion: _selectedTipoPerforacion!,
    operacionId: widget.operacionId!,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Registro guardado con ID: $nuevoId"),
      backgroundColor: Colors.green,
    ),
  );

  // Llamar al callback para actualizar datos y cerrar el diálogo
  widget.onDataInserted();
  Navigator.pop(context); // 🔹 Cierra el diálogo
}



Future<void> _getPlanesMen() async {
  try {
    final dbHelper = DatabaseHelper_Mina2();
    List<PlanMensual> planes = await dbHelper.getPlanes();
    
    _planesCompletos = planes; // Store the complete data

    print("Planes Mensuales obtenidos de la BD local:");

    // Usar sets para evitar duplicados
    Set<String> zonasSet = {};
    Set<String> tiposLaborSet = {}; 
    Set<String> laboresSet = {};
    Set<String> alaSet = {};
    Set<String> vetasSet = {};
    Set<String> nivelesSet = {};

    for (var plan in planes) {
      var planMap = plan.toMap();

      // Agregar los valores únicos a los sets
      zonasSet.add(planMap['zona'] ?? '');
      tiposLaborSet.add(planMap['tipo_labor'] ?? '');
      laboresSet.add(planMap['labor'] ?? '');
      alaSet.add(planMap['ala'] ?? '');
      vetasSet.add(planMap['estructura_veta'] ?? '');
      nivelesSet.add(planMap['nivel'] ?? '');
    }

    // Convertir los sets en listas y actualizar el estado del widget
    setState(() {
      _zonas.clear();
      _zonas.addAll(zonasSet.where((element) => element.isNotEmpty));

      _tiposLabor.clear();
      _tiposLabor.addAll(tiposLaborSet.where((element) => element.isNotEmpty));

      _labores.clear();
      _labores.addAll(laboresSet.where((element) => element.isNotEmpty));
      
      _alas.clear();
        _alas.addAll(alaSet.where((element) => element.isNotEmpty));

      _vetas.clear();
      _vetas.addAll(vetasSet.where((element) => element.isNotEmpty));

      _niveles.clear();
      _niveles.addAll(nivelesSet.where((element) => element.isNotEmpty));
      
      // Initialize filtered lists with all options
      _filteredTiposLabor = List.from(_tiposLabor);
      _filteredLabores = List.from(_labores);
        _filteredAlas = List.from(_alas);
      _filteredVetas = List.from(_vetas);
      _filteredNiveles = List.from(_niveles);
    });
  } catch (e) {
    print("Error al obtener los planes: $e");
  }
}

  void _updateFilteredLists() {
    setState(() {
      // Filter Tipos Labor based on selected Zona
      if (_selectedZona != null) {
        _filteredTiposLabor = _planesCompletos
            .where((plan) => plan.zona == _selectedZona)
            .map((plan) => plan.tipoLabor)
            .where((tipoLabor) => tipoLabor != null && tipoLabor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredTiposLabor = List.from(_tiposLabor);
      }

      if (_selectedTipoLabor != null &&
          !_filteredTiposLabor.contains(_selectedTipoLabor)) {
        _selectedTipoLabor = null;
      }

      // Filter Labores based on selected Zona and TipoLabor
      if (_selectedZona != null || _selectedTipoLabor != null) {
        _filteredLabores = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor))
            .map((plan) => plan.labor)
            .whereType<String>()
            .where((labor) => labor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredLabores = List.from(_labores);
      }

      if (_selectedLabor != null &&
          !_filteredLabores.contains(_selectedLabor)) {
        _selectedLabor = null;
      }

      // Filter Alas based on selected Zona, TipoLabor and Labor
      if (_selectedZona != null ||
          _selectedTipoLabor != null ||
          _selectedLabor != null) {
        _filteredAlas = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor) &&
                (_selectedLabor == null || plan.labor == _selectedLabor))
            .map((plan) => plan.ala)
            .whereType<String>()
            .where((ala) => ala.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredAlas = List.from(_alas);
      }

      // Reset Ala if no longer valid
      if (_selectedAla != null && !_filteredAlas.contains(_selectedAla)) {
        _selectedAla = null;
      }

      // Filter Vetas based on previous selections (no longer requires Ala)
      if (_selectedZona != null ||
          _selectedTipoLabor != null ||
          _selectedLabor != null) {
        _filteredVetas = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor) &&
                (_selectedLabor == null || plan.labor == _selectedLabor))
            .map((plan) => plan.estructuraVeta)
            .where((veta) => veta != null && veta.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredVetas = List.from(_vetas);
      }

      if (_selectedVeta != null && !_filteredVetas.contains(_selectedVeta)) {
        _selectedVeta = null;
      }

      // Filter Niveles based on all previous selections (no longer requires Ala)
      if (_selectedZona != null ||
          _selectedTipoLabor != null ||
          _selectedLabor != null ||
          _selectedVeta != null) {
        _filteredNiveles = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor) &&
                (_selectedLabor == null || plan.labor == _selectedLabor) &&
                (_selectedVeta == null || plan.estructuraVeta == _selectedVeta))
            .map((plan) => plan.nivel)
            .whereType<String>()
            .toSet()
            .toList();
      } else {
        _filteredNiveles = List.from(_niveles);
      }

      if (_selectedNivel != null &&
          !_filteredNiveles.contains(_selectedNivel)) {
        _selectedNivel = null;
      }
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Registro de Perforación')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
  children: [
    // Zona (único en una fila)
    DropdownButtonFormField<String>(
      isExpanded: true, // Add this to prevent overflow
      value: _selectedZona,
      decoration: const InputDecoration(labelText: 'Zona'),
      items: _zonas.map((zona) {
        return DropdownMenuItem<String>(
          value: zona,
          child: Text(
            zona,
            overflow: TextOverflow.ellipsis, // Handle text overflow
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedZona = value;
          _selectedTipoLabor = null;
          _selectedLabor = null;
          _selectedAla = null;
          _selectedVeta = null;
          _selectedNivel = null;
          _updateFilteredLists();
        });
      },
    ),

    const SizedBox(height: 10),

    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true, // Add this to prevent overflow
            value: _selectedTipoLabor,
            decoration: const InputDecoration(labelText: 'Tipo de Labor'),
            items: _filteredTiposLabor.map((tipo) {
              return DropdownMenuItem<String>(
                value: tipo,
                child: Text(
                  tipo,
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              );
            }).toList(),
            onChanged: _selectedZona == null ? null : (value) {
              setState(() {
                _selectedTipoLabor = value;
                _selectedLabor = null;
                _selectedAla = null;
                _selectedVeta = null;
                _selectedNivel = null;
                _updateFilteredLists();
              });
            },
            disabledHint: const Text('Selecciona Zona primero'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true, // Add this to prevent overflow
            value: _selectedLabor,
            decoration: const InputDecoration(labelText: 'Labor'),
            items: _filteredLabores.map((labor) {
              return DropdownMenuItem<String>(
                value: labor,
                child: Text(
                  labor,
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              );
            }).toList(),
            onChanged: _selectedTipoLabor == null ? null : (value) {
              setState(() {
                _selectedLabor = value;
                _selectedAla = null;
                _selectedVeta = null;
                _selectedNivel = null;
                _updateFilteredLists();
              });
            },
            disabledHint: const Text('Selecciona Tipo de Labor primero'),
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    Row(
      children: [
        Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedAla,
                    decoration: const InputDecoration(
                        labelText: 'Ala (Opcional)'), // Indicar que es opcional
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'Ninguna',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ..._filteredAlas.map((ala) {
                        return DropdownMenuItem<String>(
                          value: ala,
                          child: Text(
                            ala,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: _selectedLabor == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedAla = value;
                              _selectedVeta = null;
                              _selectedNivel = null;
                              _updateFilteredLists();
                            });
                          },
                    disabledHint: const Text('Selecciona Labor primero'),
                  ),
                ),
                const SizedBox(width: 10),
        Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedVeta,
                    decoration: const InputDecoration(labelText: 'Veta'),
                    items: _filteredVetas.map((veta) {
                      return DropdownMenuItem<String>(
                        value: veta,
                        child: Text(
                          veta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedLabor == null
                        ? null
                        : (value) {
                            // Ahora depende de Labor, no de Ala
                            setState(() {
                              _selectedVeta = value;
                              _selectedNivel = null;
                              _updateFilteredLists();
                            });
                          },
                    disabledHint: const Text('Selecciona Labor primero'),
                  ),
                ),
        
      ],
    ),

    const SizedBox(height: 10),

    Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedNivel,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                    items: _filteredNiveles.map((nivel) {
                      return DropdownMenuItem<String>(
                        value: nivel,
                        child: Text(
                          nivel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedVeta == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedNivel = value;
                            });
                          },
                    disabledHint: const Text('Selecciona Veta primero'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTipoPerforacion,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Perforación'),
                    items: _tiposPerforacion.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(
                          tipo,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTipoPerforacion = value;
                      });
                    },
                  ),
                ),
              ],
            ),
    const SizedBox(height: 20),
            ElevatedButton(
  onPressed: _guardarPerforacion,
  child: const Text('Guardar'),
),

  ],
),
    ),
  );
}

}
