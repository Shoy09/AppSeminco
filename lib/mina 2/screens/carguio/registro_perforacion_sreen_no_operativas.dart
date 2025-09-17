import 'dart:math';
import 'package:app_seminco/mina%202/models/PlanMensual.dart';
import 'package:app_seminco/mina%202/models/PlanProduccion.dart';
import 'package:app_seminco/mina%202/screens/horizontal/FormularioPerforacionScreen.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
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

String? _manualTipoLabor;
String? _manualLabor;

String? _observacion;

  final TextEditingController _observacionController = TextEditingController();

  final List<String> _tiposLabor = [];
  final List<String> _labores = [];

  List<String> _filteredTiposLabor = [];
  List<String> _filteredLabores = [];
  List<String> _filteredAlas = [];
  List<String> _filteredVetas = [];
  List<String> _filteredNiveles = [];
  List<PlanMensual> _planesCompletos = [];
  List<PlanProduccion> _planesProduccionCompletos = [];
List<Map<String, dynamic>> _planesCombinadosMap = [];
List<String> _origenes = [];
List<String> _destinos = [];


  @override
void initState() {
  super.initState();
  _initializeData(); // Primero cargar datos existentes
}


  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

// Modifica _initializeData para que también cargue los planes
  Future<void> _initializeData() async {
    final dbHelper = DatabaseHelper_Mina2();
    try {
      // Primero cargar los planes
      await _getPlanesMen();
      
      // Luego cargar datos existentes
      if (widget.estadoId != null) {
        Map<String, dynamic>? perforacion =
            await dbHelper.getCarguioEstadoId(widget.estadoId!);

        if (perforacion != null) {
          print("📌 Datos obtenidos de getCarguioEstadoId: $perforacion");

          _perforacionId = perforacion['id'];
          print("id perforacion: $_perforacionId");

          setState(() {
            // ✅ Dropdowns
            _selectedTipoLabor = perforacion['tipo_labor'];
            _selectedLabor = perforacion['labor'];

            // ✅ Campos manuales
            _manualTipoLabor = perforacion['tipo_labor_manual'] ?? "";
            _manualLabor = perforacion['labor_manual'] ?? "";

        
            // ✅ Observaciones - USAR CONTROLADOR
            _observacion = perforacion['observacion'] ?? "";
            _observacionController.text = _observacion ?? "";
          });

          _updateFilteredLists();
        }
      }
    } catch (e) {
      print("❌ Error en _initializeData: $e");
    }
  }

  Future<void> _getPlanesMen() async {
  try {
    final dbHelper = DatabaseHelper_Mina2();

    // 1️⃣ Llamadas a Planes
    List<PlanMensual> planes = await dbHelper.getPlanes();
    List<PlanProduccion> planesProduccion = await dbHelper.getPlanesProduccion();

    _planesCompletos = planes;
    _planesProduccionCompletos = planesProduccion;

    // 2️⃣ Lista combinada de Planes
    final combinedMaps = [
      ...planes.map((p) => p.toMap()),
      ...planesProduccion.map((p) => p.toMap()),
    ];

    _planesCombinadosMap = combinedMaps;

    // 3️⃣ Llamada a OrigenDestino (toda la tabla)
    List<Map<String, dynamic>> origenDestino =
        await dbHelper.getOrigenDestinoPorOperacion('CARGUÍO'); // si no filtras por operación

    // DEBUG: ver qué llega
    print("OrigenDestino registros: ${origenDestino.length}");
    for (var od in origenDestino) print(od);

// ✅ LIMPIAR antes de volver a llenar
_origenes.clear();
_destinos.clear();

    // 4️⃣ Sets para eliminar duplicados
    final tiposLaborSet = <String>{};
    final laboresSet = <String>{};

    // 4a️⃣ Agregar Planes
    for (final m in combinedMaps) {
      final tipo = (m['tipo_labor'] ?? m['tipoLabor'] ?? '').toString();
      final labor = (m['labor'] ?? m['nombre_labor'] ?? '').toString();
      if (tipo.isNotEmpty) tiposLaborSet.add(tipo);
      if (labor.isNotEmpty) laboresSet.add(labor);
    }

    // 4b️⃣ Agregar OrigenDestino
    for (final m in origenDestino) {
  final tipo = (m['tipo'] ?? '').toString();
  final nombre = (m['nombre'] ?? '').toString();

  if (tipo == 'Origen' && nombre.isNotEmpty) {
    tiposLaborSet.add(nombre); // estos van a tiposLabor
    _origenes.add(nombre);     // guardamos por separado
  } else if (tipo == 'Destino' && nombre.isNotEmpty) {
    laboresSet.add(nombre);    // estos van a labores
    _destinos.add(nombre);     // guardamos por separado
  }
}


    // 5️⃣ Actualizar estado
    setState(() {
      _tiposLabor
        ..clear()
        ..addAll(tiposLaborSet);

      _labores
        ..clear()
        ..addAll(laboresSet);

      _filteredTiposLabor = List.from(_tiposLabor);
      _filteredLabores = List.from(_labores);
    });

    // 6️⃣ Actualizar filtros si había selección activa
    if (_selectedTipoLabor != null) _updateFilteredLists();

  } catch (e) {
    print("Error al obtener los planes: $e");
  }
}

void _updateFilteredLists() {
  setState(() {
    if (_selectedTipoLabor != null) {
      // Si el seleccionado es un ORIGEN → mostrar solo DESTINOS
      if (_origenes.contains(_selectedTipoLabor)) {
        _filteredLabores = List.from(_destinos);
      } else {
        // Caso normal: viene de Planes
        _filteredLabores = _planesCombinadosMap
            .where((m) =>
                ((m['tipo_labor'] ?? m['tipoLabor'] ?? '') ==
                    _selectedTipoLabor))
            .map((m) => (m['labor'] ?? m['nombre_labor'] ?? '').toString())
            .where((l) => l.isNotEmpty)
            .toSet()
            .toList();
      }

      // Si el labor seleccionado ya no aplica, se limpia
      if (_selectedLabor != null &&
          !_filteredLabores.contains(_selectedLabor)) {
        _selectedLabor = null;
      }
    } else {
      // Si no hay selección → mostrar todos los destinos
      _filteredLabores = List.from(_labores);
    }
  });
}


void _guardarPerforacion() async {
  // 🔥 FALTAN ESTAS 2 LÍNEAS CRÍTICAS:
  _observacion = _observacionController.text;

  List<String> camposFaltantes = [];
  if (_selectedTipoLabor == null) camposFaltantes.add("Tipo de Labor");
  if ((_selectedLabor == null || _selectedLabor!.isEmpty) &&
    (_manualLabor == null || _manualLabor!.isEmpty)) {
  camposFaltantes.add("Labor");
}

  if (camposFaltantes.isNotEmpty) {
    print("❌ Falta seleccionar: ${camposFaltantes.join(", ")}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Falta seleccionar: ${camposFaltantes.join(", ")}"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (widget.estadoId == null) {
    print("❌ Error: No se encontró el ID de la operación.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No se encontró el ID de la operación."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final dbHelper = DatabaseHelper_Mina2();

  try {
    if (_perforacionId != null) {
      // 🔹 ACTUALIZAR
      print("🔄 Intentando actualizar registro ID=$_perforacionId...");
      await dbHelper.actualizarCarguio(
        id: _perforacionId!,
        tipoLabor: _selectedTipoLabor ?? "",
        labor: _selectedLabor?? "",
        tipoLaborManual: _manualTipoLabor?? "",
        laborManual: _manualLabor?? "",
        ncucharas: 0,
        observacion: _observacion,
      );
      print("✅ Registro ID=$_perforacionId actualizado correctamente.");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro actualizado correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      await _initializeData();

    } else {
      // 🔹 INSERTAR
      print("🆕 Insertando nuevo registro en Acarreo...");


      int nuevoId = await dbHelper.insertarCarguio(
        tipoLabor: _selectedTipoLabor ?? "",
        labor: _selectedLabor ?? "",
        tipoLaborManual: _manualTipoLabor ?? "",
        laborManual: _manualLabor   ?? "",
        ncucharas: 0,
        observacion: _observacion,
        estadoId: widget.estadoId!,
      );
      print("✅ Nuevo registro insertado con ID=$nuevoId");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nuevo registro guardado con ID: $nuevoId"),
          backgroundColor: Colors.green,
        ),
      );

      await _initializeData();
      Navigator.of(context).pop();
    }
  } catch (e, stack) {
    print("❌ Error al guardar en Acarreo: $e");
    print("📌 Stacktrace: $stack");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error al guardar: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}




@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Registro de Perforación')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Primera fila: Tipo Labor y Labor (con opción Otro)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTipoLabor,
                    decoration: const InputDecoration(labelText: 'ORIGEN'),
                    items: [
                      ..._filteredTiposLabor.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      const DropdownMenuItem<String>(
                        value: 'Otro',
                        child: Text('Otro'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTipoLabor = value;
                        _selectedLabor = null;
                        _updateFilteredLists();
                      });
                      print("✅ ORIGEN seleccionado: $value");
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: (_selectedTipoLabor == 'Otro')
                      ? const SizedBox() // 👈 no mostramos dropdown
                      : DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedLabor,
                          decoration:
                              const InputDecoration(labelText: 'DESTINO'),
                          items: [
                            ..._filteredLabores.map((labor) {
                              return DropdownMenuItem<String>(
                                value: labor,
                                child: Text(labor,
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            const DropdownMenuItem<String>(
                              value: 'Otro',
                              child: Text('Otro'),
                            ),
                          ],
                          onChanged: _selectedTipoLabor == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedLabor = value;
                                  });
                                   print("✅ DESTINO seleccionado: $value");
                                },
                          disabledHint: const Text(
                              'Selecciona Tipo de Labor primero'),
                        ),
                ),
              ],
            ),

            // 🔹 Segunda fila: si eligieron "Otro"
            if (_selectedTipoLabor == 'Otro') ...[
  const SizedBox(height: 10),
  Row(
    children: [
      Expanded(
        child: TextFormField(
          initialValue: _manualTipoLabor,
          decoration: const InputDecoration(labelText: 'ORIGEN MANUAL'),
          onChanged: (value) {
            setState(() {
              _manualTipoLabor = value;
            });
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          initialValue: _manualLabor,
          decoration: const InputDecoration(labelText: 'DESTINO MANUAL'),
          onChanged: (value) {
            setState(() {
              _manualLabor = value;
            });
          },
        ),
      ),
    ],
  ),
],

              const SizedBox(height: 20),

              // 🔥 Observaciones - USAR CONTROLADOR
              TextFormField(
                controller: _observacionController, // Usar controller
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 2,
                onChanged: (value) {
                  _observacion = value;
                },
              ),


            const SizedBox(height: 30),

            Row(
  mainAxisAlignment: MainAxisAlignment.end, // Alinea a la derecha
  children: [
    ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text('No aplica'),
    ),
    const SizedBox(width: 10), // espacio entre botones
    ElevatedButton(
      onPressed: _guardarPerforacion,
      child: const Text('Guardar'),
    ),
  ],
)

          ],
        ),
      ),
    ),
  );
}


}
