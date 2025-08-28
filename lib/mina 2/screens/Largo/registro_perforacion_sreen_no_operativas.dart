import 'dart:math';
import 'package:app_seminco/mina%202/screens/Largo/FormularioPerforacionScreen.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/PlanMetraje.dart';
import 'package:app_seminco/mina%202/models/TipoPerforacion.dart';

class RegistroPerforacionScreenNoOperative extends StatefulWidget {
  final VoidCallback onDataInserted;
  final int? estadoId; // Agregar estadoId como parámetro opcional
  final String tipoOperacion;
  final String estado;
  final int operacionId;
  const RegistroPerforacionScreenNoOperative({
    Key? key,
    required this.tipoOperacion,
    required this.onDataInserted,
    required this.estado,
    required this.operacionId,
    this.estadoId, // Inicializar en el constructor
  }) : super(key: key);

  @override
  _RegistroPerforacionScreenState createState() =>
      _RegistroPerforacionScreenState();
}

class _RegistroPerforacionScreenState extends State<RegistroPerforacionScreenNoOperative> {
  int? _perforacionId;
  String? _selectedTipoLabor;
  String? _selectedLabor;
  String? _selectedNivel;
String _observaciones = '';
  final List<String> _tiposLabor = [];
  final List<String> _labores = [];
  final List<String> _niveles = [];
late TextEditingController _observacionesController;
  List<String> _filteredTiposLabor = [];
  List<String> _filteredLabores = [];
  List<String> _filteredNiveles = [];
  List<PlanMetraje> _planesCompletos = [];

  @override
  void initState() {
    super.initState();
  _getPlanesMen();
  _observacionesController = TextEditingController();
  _initializeData();
  }

Future<void> _initializeData() async {
  final dbHelper = DatabaseHelper_Mina2();
  try {
    Map<String, dynamic>? perforacion = await dbHelper.getPerforacionTaladroLargoByEstadoId(widget.estadoId!);
    
    if (perforacion != null) {
       _perforacionId = perforacion['id']; 
       print("id perforacion: $_perforacionId");
      setState(() {
        // Solo asigna el valor si está en la lista actual
        _selectedTipoLabor = _filteredTiposLabor.contains(perforacion['tipo_labor']) ? perforacion['tipo_labor'] : null;
        _selectedLabor = _filteredLabores.contains(perforacion['labor']) ? perforacion['labor'] : null;
        _selectedNivel = _filteredNiveles.contains(perforacion['nivel']) ? perforacion['nivel'] : null;
                 _observaciones = perforacion['observacion'] ?? '';
        _observacionesController.text = _observaciones; 
      });
    }
  } catch (e) {
    print("Error en _initializeData: $e");
  }
}


void _guardarPerforacion() async {
  // Validaciones (se mantienen igual que en tu código)
  List<String> camposFaltantes = [];
  if (_selectedTipoLabor == null) camposFaltantes.add("Tipo de Labor");
  if (_selectedLabor == null) camposFaltantes.add("Labor");
  if (_selectedNivel == null) camposFaltantes.add("Nivel");

  if (camposFaltantes.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Falta seleccionar: ${camposFaltantes.join(", ")}"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (widget.estadoId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("No se encontró el ID de la operación."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final dbHelper = DatabaseHelper_Mina2();
  try {
    if (_perforacionId != null) {
      // ACTUALIZAR registro existente
      await dbHelper.actualizarPerforacionTaladroLargo(
        id: _perforacionId!,
        zona: '',
        tipoLabor: _selectedTipoLabor!,
        labor: _selectedLabor!,
        ala: '',
        veta: '',
        nivel: _selectedNivel!,
        tipoPerforacion: '',
        observacion: _observaciones,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registro actualizado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      await _initializeData();
    } else {
      // INSERTAR nuevo registro
      int nuevoId = await dbHelper.insertarPerforacionTaladroLargo(
        zona: '',
        tipoLabor: _selectedTipoLabor!,
        labor: _selectedLabor!,
        ala: '',
        veta: '',
        nivel: _selectedNivel!,
        tipoPerforacion: '',
        estadoId: widget.estadoId!,
        observacion: _observaciones,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nuevo registro guardado con ID: $nuevoId"),
          backgroundColor: Colors.green,
        ),
      );

      await _initializeData(); // Refrescar para tener datos actualizados
Navigator.of(context).pop();
      
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error al guardar: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<void> _getPlanesMen() async {
    try {
      final dbHelper = DatabaseHelper_Mina2();
      List<PlanMetraje> planes = await dbHelper.getPlanesMetraje();

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
  
        _tiposLabor.clear();
        _tiposLabor
            .addAll(tiposLaborSet.where((element) => element.isNotEmpty));

        _labores.clear();
        _labores.addAll(laboresSet.where((element) => element.isNotEmpty));



        _niveles.clear();
        _niveles.addAll(nivelesSet.where((element) => element.isNotEmpty));

        // Initialize filtered lists with all options
        _filteredTiposLabor = List.from(_tiposLabor);
        _filteredLabores = List.from(_labores);
        _filteredNiveles = List.from(_niveles);
      });
    } catch (e) {
      print("Error al obtener los planes: $e");
    }
  }

void _updateFilteredLists() {
  setState(() {
    // Filter Tipos Labor based on selected Nivel
    if (_selectedNivel != null) {
      _filteredTiposLabor = _planesCompletos
          .where((plan) => plan.nivel == _selectedNivel)
          .map((plan) => plan.tipoLabor)
          .where((tipoLabor) => tipoLabor != null && tipoLabor.isNotEmpty)
          .toSet()
          .toList();
    } else {
      _filteredTiposLabor = List.from(_tiposLabor);
    }

    // Reset TipoLabor if no longer valid
    if (_selectedTipoLabor != null && 
        !_filteredTiposLabor.contains(_selectedTipoLabor)) {
      _selectedTipoLabor = null;
    }

    // Filter Labores based on selected Nivel and TipoLabor
    if (_selectedNivel != null || _selectedTipoLabor != null) {
      _filteredLabores = _planesCompletos
          .where((plan) =>
              (_selectedNivel == null || plan.nivel == _selectedNivel) &&
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

    // Reset Labor if no longer valid
    if (_selectedLabor != null && !_filteredLabores.contains(_selectedLabor)) {
      _selectedLabor = null;
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
    Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedNivel,
            decoration: const InputDecoration(labelText: 'Nivel'),
            items: _niveles.map((nivel) {
              return DropdownMenuItem<String>(
                value: nivel,
                child: Text(
                  nivel,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedNivel = value;
                _selectedTipoLabor = null;
                _selectedLabor = null;
                _updateFilteredLists();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedTipoLabor,
            decoration: const InputDecoration(labelText: 'Tipo de Labor'),
            items: _filteredTiposLabor.map((tipo) {
              return DropdownMenuItem<String>(
                value: tipo,
                child: Text(
                  tipo,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _selectedNivel == null
                ? null
                : (value) {
                    setState(() {
                      _selectedTipoLabor = value;
                      _selectedLabor = null;
                      _updateFilteredLists();
                    });
                  },
            disabledHint: const Text('Selecciona Nivel primero'),
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
            value: _selectedLabor,
            decoration: const InputDecoration(labelText: 'Labor'),
            items: _filteredLabores.map((labor) {
              return DropdownMenuItem<String>(
                value: labor,
                child: Text(
                  labor,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _selectedTipoLabor == null
                ? null
                : (value) {
                    setState(() {
                      _selectedLabor = value;
                    });
                  },
            disabledHint: const Text('Selecciona Tipo de Labor primero'),
          ),
        ),
        const SizedBox(width: 10),
      ],
    ),

    const SizedBox(height: 20),
    
    TextFormField(
  controller: _observacionesController,
  decoration: const InputDecoration(
    labelText: 'Observaciones',
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  ),
  maxLines: 3,
  onChanged: (value) {
    _observaciones = value;
  },
),

const SizedBox(height: 20),

    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _guardarPerforacion,
                child: const Text('Guardar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No aplica'),
              ),
            ),
          ],
        ),
      ],
    )
  ],
),
      ),
    );
  }
}
