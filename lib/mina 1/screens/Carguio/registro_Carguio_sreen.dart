import 'dart:math';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/PlanMensual.dart';
import 'package:app_seminco/mina%201/models/TipoPerforacion.dart';

class RegistroPerforacionCarguiocreen extends StatefulWidget {
  final VoidCallback onDataInserted;
  final int? operacionId;
  final String tipoOperacion;

  const RegistroPerforacionCarguiocreen({
    Key? key,
    required this.tipoOperacion,
    required this.onDataInserted,
    this.operacionId,
  }) : super(key: key);

  @override
  _RegistroPerforacionScreenState createState() => _RegistroPerforacionScreenState();
}

class _RegistroPerforacionScreenState extends State<RegistroPerforacionCarguiocreen> {
  // Campos para ORIGEN
  String? _selectedZonaOrigen;
  String? _selectedTipoLaborOrigen;
  String? _selectedLaborOrigen;
  String? _selectedAlaOrigen;

  // Campos para DESTINO
  String? _selectedZonaDestino;
  String? _selectedTipoLaborDestino;
  String? _selectedLaborDestino;
  String? _selectedAlaDestino;

  // Otros campos
  String? _selectedNivel;
  String? _selectedMaterial;
  final TextEditingController _numCucharasController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  // Listas de opciones
  final List<String> _zonas = [];
  final List<String> _tiposLabor = [];
  final List<String> _labores = [];
  final List<String> _alas = [];
  final List<String> _niveles = [];
  final List<String> _materiales = ['M', 'D', 'O']; // Materiales disponibles

  List<PlanMensual> _planesCompletos = [];

  // Listas filtradas para ORIGEN
  List<String> _filteredTiposLaborOrigen = [];
  List<String> _filteredLaboresOrigen = [];
  List<String> _filteredAlasOrigen = [];

  // Listas filtradas para DESTINO
  List<String> _filteredTiposLaborDestino = [];
  List<String> _filteredLaboresDestino = [];
  List<String> _filteredAlasDestino = [];

  @override
  void initState() {
    super.initState();
    _getPlanesMen();
  }

  Future<void> _getPlanesMen() async {
    try {
      final dbHelper = DatabaseHelper_Mina1();
      List<PlanMensual> planes = await dbHelper.getPlanes();
      _planesCompletos = planes;

      print("Planes Mensuales obtenidos de la BD local:");

      // Usar sets para evitar duplicados
      Set<String> zonasSet = {};
      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alaSet = {};
      Set<String> nivelesSet = {};

      for (var plan in planes) {
        var planMap = plan.toMap();
        zonasSet.add(planMap['zona'] ?? '');
        tiposLaborSet.add(planMap['tipo_labor'] ?? '');
        laboresSet.add(planMap['labor'] ?? '');
        alaSet.add(planMap['ala'] ?? '');
        nivelesSet.add(planMap['nivel'] ?? '');
      }

      setState(() {
        _zonas.clear();
        _zonas.addAll(zonasSet.where((element) => element.isNotEmpty));
        _tiposLabor.clear();
        _tiposLabor.addAll(tiposLaborSet.where((element) => element.isNotEmpty));
        _labores.clear();
        _labores.addAll(laboresSet.where((element) => element.isNotEmpty));
        _alas.clear();
        _alas.addAll(alaSet.where((element) => element.isNotEmpty));
        _niveles.clear();
        _niveles.addAll(nivelesSet.where((element) => element.isNotEmpty));

        // Inicializar listas filtradas
        _filteredTiposLaborOrigen = List.from(_tiposLabor);
        _filteredLaboresOrigen = List.from(_labores);
        _filteredAlasOrigen = List.from(_alas);
        _filteredTiposLaborDestino = List.from(_tiposLabor);
        _filteredLaboresDestino = List.from(_labores);
        _filteredAlasDestino = List.from(_alas);
      });
    } catch (e) {
      print("Error al obtener los planes: $e");
    }
  }

  void _updateFilteredListsOrigen() {
    setState(() {
      // Filter Tipos Labor ORIGEN based on selected Zona
      if (_selectedZonaOrigen != null) {
        _filteredTiposLaborOrigen = _planesCompletos
            .where((plan) => plan.zona == _selectedZonaOrigen)
            .map((plan) => plan.tipoLabor)
            .where((tipoLabor) => tipoLabor != null && tipoLabor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredTiposLaborOrigen = List.from(_tiposLabor);
      }

      if (_selectedTipoLaborOrigen != null && !_filteredTiposLaborOrigen.contains(_selectedTipoLaborOrigen)) {
        _selectedTipoLaborOrigen = null;
      }

      // Filter Labores ORIGEN based on selected Zona and TipoLabor
      if (_selectedZonaOrigen != null || _selectedTipoLaborOrigen != null) {
        _filteredLaboresOrigen = _planesCompletos
            .where((plan) => (_selectedZonaOrigen == null || plan.zona == _selectedZonaOrigen) &&
                (_selectedTipoLaborOrigen == null || plan.tipoLabor == _selectedTipoLaborOrigen))
            .map((plan) => plan.labor)
            .whereType<String>()
            .where((labor) => labor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredLaboresOrigen = List.from(_labores);
      }

      if (_selectedLaborOrigen != null && !_filteredLaboresOrigen.contains(_selectedLaborOrigen)) {
        _selectedLaborOrigen = null;
      }

      // Filter Alas ORIGEN based on selected Zona, TipoLabor and Labor
      if (_selectedZonaOrigen != null || _selectedTipoLaborOrigen != null || _selectedLaborOrigen != null) {
        _filteredAlasOrigen = _planesCompletos
            .where((plan) => (_selectedZonaOrigen == null || plan.zona == _selectedZonaOrigen) &&
                (_selectedTipoLaborOrigen == null || plan.tipoLabor == _selectedTipoLaborOrigen) &&
                (_selectedLaborOrigen == null || plan.labor == _selectedLaborOrigen))
            .map((plan) => plan.ala)
            .whereType<String>()
            .where((ala) => ala.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredAlasOrigen = List.from(_alas);
      }

      if (_selectedAlaOrigen != null && !_filteredAlasOrigen.contains(_selectedAlaOrigen)) {
        _selectedAlaOrigen = null;
      }
    });
  }

  void _updateFilteredListsDestino() {
    setState(() {
      // Filter Tipos Labor DESTINO based on selected Zona
      if (_selectedZonaDestino != null) {
        _filteredTiposLaborDestino = _planesCompletos
            .where((plan) => plan.zona == _selectedZonaDestino)
            .map((plan) => plan.tipoLabor)
            .where((tipoLabor) => tipoLabor != null && tipoLabor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredTiposLaborDestino = List.from(_tiposLabor);
      }

      if (_selectedTipoLaborDestino != null && !_filteredTiposLaborDestino.contains(_selectedTipoLaborDestino)) {
        _selectedTipoLaborDestino = null;
      }

      // Filter Labores DESTINO based on selected Zona and TipoLabor
      if (_selectedZonaDestino != null || _selectedTipoLaborDestino != null) {
        _filteredLaboresDestino = _planesCompletos
            .where((plan) => (_selectedZonaDestino == null || plan.zona == _selectedZonaDestino) &&
                (_selectedTipoLaborDestino == null || plan.tipoLabor == _selectedTipoLaborDestino))
            .map((plan) => plan.labor)
            .whereType<String>()
            .where((labor) => labor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredLaboresDestino = List.from(_labores);
      }

      if (_selectedLaborDestino != null && !_filteredLaboresDestino.contains(_selectedLaborDestino)) {
        _selectedLaborDestino = null;
      }

      // Filter Alas DESTINO based on selected Zona, TipoLabor and Labor
      if (_selectedZonaDestino != null || _selectedTipoLaborDestino != null || _selectedLaborDestino != null) {
        _filteredAlasDestino = _planesCompletos
            .where((plan) => (_selectedZonaDestino == null || plan.zona == _selectedZonaDestino) &&
                (_selectedTipoLaborDestino == null || plan.tipoLabor == _selectedTipoLaborDestino) &&
                (_selectedLaborDestino == null || plan.labor == _selectedLaborDestino))
            .map((plan) => plan.ala)
            .whereType<String>()
            .where((ala) => ala.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredAlasDestino = List.from(_alas);
      }

      if (_selectedAlaDestino != null && !_filteredAlasDestino.contains(_selectedAlaDestino)) {
        _selectedAlaDestino = null;
      }
    });
  }

  void _guardarCarguio() async {
    List<String> camposFaltantes = [];

    // Validar campos de ORIGEN
    if (_selectedZonaOrigen == null) camposFaltantes.add("Zona Origen");
    if (_selectedTipoLaborOrigen == null) camposFaltantes.add("Tipo de Labor Origen");
    if (_selectedLaborOrigen == null) camposFaltantes.add("Labor Origen");

    // Validar campos de DESTINO
    if (_selectedZonaDestino == null) camposFaltantes.add("Zona Destino");
    if (_selectedTipoLaborDestino == null) camposFaltantes.add("Tipo de Labor Destino");
    if (_selectedLaborDestino == null) camposFaltantes.add("Labor Destino");

    // Validar otros campos
    if (_selectedNivel == null) camposFaltantes.add("Nivel");
    if (_selectedMaterial == null) camposFaltantes.add("Material");
    if (_numCucharasController.text.isEmpty) camposFaltantes.add("Número de Cucharas");

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

    try {
      final dbHelper = DatabaseHelper_Mina1();
      
      // Construir labor_origen concatenando los valores
      String laborOrigen = '${_selectedTipoLaborOrigen!} - ${_selectedLaborOrigen!}' +
          (_selectedAlaOrigen != null ? ' - ${_selectedAlaOrigen!}' : '');
      
      // Construir labor_destino concatenando los valores
      String laborDestino = '${_selectedTipoLaborDestino!} - ${_selectedLaborDestino!}' +
          (_selectedAlaDestino != null ? ' - ${_selectedAlaDestino!}' : '');

      int nuevoId = await dbHelper.insertarCarguio(
        operacionId: widget.operacionId!,
        nivel: _selectedNivel!,
        laborOrigen: laborOrigen,
        material: _selectedMaterial!,
        laborDestino: laborDestino,
        numCucharas: int.parse(_numCucharasController.text),
        observaciones: _observacionesController.text,
      );

      // ✅ Actualizar estado a “Parciales” si existe el idOperacion
    if (widget.operacionId != null) {
      await dbHelper.actualizarEstadoAParciales(widget.operacionId!);
    }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Carguío guardado con ID: $nuevoId"),
          backgroundColor: Colors.green,
        ),
      );

      // Llamar al callback para actualizar datos y cerrar el diálogo
      widget.onDataInserted();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro de Carguío')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SECCIÓN ORIGEN
              _buildSeccionOrigen(),
              const SizedBox(height: 20),
              
              // SECCIÓN DESTINO
              _buildSeccionDestino(),
              const SizedBox(height: 20),
              
              // OTROS CAMPOS
              _buildOtrosCampos(),
              const SizedBox(height: 20),
              
              // BOTÓN GUARDAR
              ElevatedButton(
                onPressed: _guardarCarguio,
                child: const Text('Guardar Carguío'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionOrigen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ORIGEN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Zona Origen
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedZonaOrigen,
              decoration: const InputDecoration(labelText: 'Zona Origen'),
              items: _zonas.map((zona) {
                return DropdownMenuItem<String>(
                  value: zona,
                  child: Text(zona, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZonaOrigen = value;
                  _selectedTipoLaborOrigen = null;
                  _selectedLaborOrigen = null;
                  _selectedAlaOrigen = null;
                  _updateFilteredListsOrigen();
                });
              },
            ),
            const SizedBox(height: 10),
            
            // Fila: Tipo Labor Origen y Labor Origen
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTipoLaborOrigen,
                    decoration: const InputDecoration(labelText: 'Tipo Labor Origen'),
                    items: _filteredTiposLaborOrigen.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _selectedZonaOrigen == null ? null : (value) {
                      setState(() {
                        _selectedTipoLaborOrigen = value;
                        _selectedLaborOrigen = null;
                        _selectedAlaOrigen = null;
                        _updateFilteredListsOrigen();
                      });
                    },
                    disabledHint: const Text('Selecciona Zona primero'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedLaborOrigen,
                    decoration: const InputDecoration(labelText: 'Labor Origen'),
                    items: _filteredLaboresOrigen.map((labor) {
                      return DropdownMenuItem<String>(
                        value: labor,
                        child: Text(labor, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _selectedTipoLaborOrigen == null ? null : (value) {
                      setState(() {
                        _selectedLaborOrigen = value;
                        _selectedAlaOrigen = null;
                        _updateFilteredListsOrigen();
                      });
                    },
                    disabledHint: const Text('Selecciona Tipo Labor primero'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Ala Origen (Opcional)
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedAlaOrigen,
              decoration: const InputDecoration(labelText: 'Ala Origen (Opcional)'),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Ninguna', style: TextStyle(color: Colors.grey)),
                ),
                ..._filteredAlasOrigen.map((ala) {
                  return DropdownMenuItem<String>(
                    value: ala,
                    child: Text(ala, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ],
              onChanged: _selectedLaborOrigen == null ? null : (value) {
                setState(() {
                  _selectedAlaOrigen = value;
                });
              },
              disabledHint: const Text('Selecciona Labor primero'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionDestino() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DESTINO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Zona Destino
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedZonaDestino,
              decoration: const InputDecoration(labelText: 'Zona Destino'),
              items: _zonas.map((zona) {
                return DropdownMenuItem<String>(
                  value: zona,
                  child: Text(zona, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZonaDestino = value;
                  _selectedTipoLaborDestino = null;
                  _selectedLaborDestino = null;
                  _selectedAlaDestino = null;
                  _updateFilteredListsDestino();
                });
              },
            ),
            const SizedBox(height: 10),
            
            // Fila: Tipo Labor Destino y Labor Destino
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedTipoLaborDestino,
                    decoration: const InputDecoration(labelText: 'Tipo Labor Destino'),
                    items: _filteredTiposLaborDestino.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _selectedZonaDestino == null ? null : (value) {
                      setState(() {
                        _selectedTipoLaborDestino = value;
                        _selectedLaborDestino = null;
                        _selectedAlaDestino = null;
                        _updateFilteredListsDestino();
                      });
                    },
                    disabledHint: const Text('Selecciona Zona primero'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedLaborDestino,
                    decoration: const InputDecoration(labelText: 'Labor Destino'),
                    items: _filteredLaboresDestino.map((labor) {
                      return DropdownMenuItem<String>(
                        value: labor,
                        child: Text(labor, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _selectedTipoLaborDestino == null ? null : (value) {
                      setState(() {
                        _selectedLaborDestino = value;
                        _selectedAlaDestino = null;
                        _updateFilteredListsDestino();
                      });
                    },
                    disabledHint: const Text('Selecciona Tipo Labor primero'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Ala Destino (Opcional)
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedAlaDestino,
              decoration: const InputDecoration(labelText: 'Ala Destino (Opcional)'),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Ninguna', style: TextStyle(color: Colors.grey)),
                ),
                ..._filteredAlasDestino.map((ala) {
                  return DropdownMenuItem<String>(
                    value: ala,
                    child: Text(ala, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ],
              onChanged: _selectedLaborDestino == null ? null : (value) {
                setState(() {
                  _selectedAlaDestino = value;
                });
              },
              disabledHint: const Text('Selecciona Labor primero'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtrosCampos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OTROS DATOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Fila: Nivel y Material
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
                        child: Text(nivel, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedNivel = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedMaterial,
                    decoration: const InputDecoration(labelText: 'Material'),
                    items: _materiales.map((material) {
                      return DropdownMenuItem<String>(
                        value: material,
                        child: Text(material),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMaterial = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Número de Cucharas
            TextFormField(
              controller: _numCucharasController,
              decoration: const InputDecoration(
                labelText: 'Número de Cucharas',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            
            // Observaciones
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (Opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numCucharasController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}