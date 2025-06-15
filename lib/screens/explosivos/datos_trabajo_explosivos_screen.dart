import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/models/PlanMensual.dart';
import 'package:app_seminco/models/PlanProduccion.dart';
import 'package:app_seminco/models/PlanTrabajo.dart';
import 'package:app_seminco/models/TipoPerforacion.dart';

class FormularioDatosTrabajoScreen extends StatefulWidget {
  final int
      exploracionId; // Se espera que se reciba el id; para un registro nuevo se puede pasar, por ejemplo, -1 o 0
  final VoidCallback? onEstadoActualizado;
  const FormularioDatosTrabajoScreen({
    Key? key,
    required this.exploracionId,
    this.onEstadoActualizado,
  }) : super(key: key);

  @override
  _FormularioDatosTrabajoScreenState createState() =>
      _FormularioDatosTrabajoScreenState();
}

class _FormularioDatosTrabajoScreenState
    extends State<FormularioDatosTrabajoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para campos de texto que se mantienen
  final _fechaController = TextEditingController();
  final _turnoController = TextEditingController();
  final _semanaDefaultController = TextEditingController();
  final _taladroController = TextEditingController();
  final _piesPorTaladroController = TextEditingController();

  // Variables para dropdowns (spinners) y listas de opciones
  String? _selectedTipoPlan;
  String? _selectedZona;
  String? _selectedTipoLabor;
  String? _selectedLabor;
  String? _selectedAla;
  String? _selectedVeta;
  String? _selectedNivel;
  String? _selectedTipoPerforacion;

  final List<String> _zonas = [];
  final List<String> _tiposLabor = [];
  final List<String> _labores = [];
  final List<String> _alas = [];
  final List<String> _vetas = [];
  final List<String> _niveles = [];
  final List<String> _tiposPerforacion = [];

  // Filtered lists for dropdowns
  List<String> _filteredTiposLabor = [];
  List<String> _filteredLabores = [];
  List<String> _filteredAlas = [];
  List<String> _filteredVetas = [];
  List<String> _filteredNiveles = [];

// Original plan data (keep this to filter against)
  List<PlanMensual> _planesCompletosmensual = [];
  List<PlanProduccion> _planesCompletosproduccion = [];
  List<PlanTrabajo> _planesCompletos = [];

  @override
  void dispose() {
    // Liberar recursos de controladores
    _fechaController.dispose();
    _turnoController.dispose();
    _semanaDefaultController.dispose();
    _taladroController.dispose();
    _piesPorTaladroController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData(widget.exploracionId);
    _getPlanesCompletos();
    _getTiposPerforacion();
  }

  Future<void> _actualizarEstadoEnProceso() async {
    if (widget.exploracionId > 0) {
      // Verifica que sea un ID válido
      await DatabaseHelper()
          .updateEstadoExploracion(widget.exploracionId, 'En proceso');

      // 🔹 Notificar al padre que el estado se actualizó
      if (widget.onEstadoActualizado != null) {
        widget.onEstadoActualizado!();
      }
    }
  }

  Future<void> _getTiposPerforacion() async {
    try {
      final dbHelper = DatabaseHelper();
      List<TipoPerforacion> tipos = await dbHelper.getTiposPerforacion();

      print("Tipos de Perforación obtenidos de la BD local: $tipos");

      // Usar un Set para evitar duplicados
      Set<String> tiposSet = {};

      for (var tipo in tipos) {
        var tipoMap = tipo.toMap();
        tiposSet.add(tipoMap['nombre'] ?? '');
      }

      // Actualizar el estado del widget con la lista filtrada
      setState(() {
        _tiposPerforacion.clear();
        _tiposPerforacion
            .addAll(tiposSet.where((element) => element.isNotEmpty));
      });
    } catch (e) {
      print("Error al obtener los tipos de perforación: $e");
    }
  }

  Future<void> _getPlanesCompletos() async {
    try {
      final List<PlanMensual> planesMensuales =
          await DatabaseHelper().getPlanes();
      final List<PlanProduccion> planesProduccion =
          await DatabaseHelper().getPlanesProduccion();

      List<PlanTrabajo> planesTrabajo = [];

      // Convertir PlanMensual a PlanTrabajo
      planesTrabajo.addAll(planesMensuales.map((plan) => PlanTrabajo(
            zona: plan.toMap()['zona'] ?? '',
            tipoLabor: plan.toMap()['tipo_labor'] ?? '',
            labor: plan.toMap()['labor'] ?? '',
            ala: plan.toMap()['ala'] ?? '',
            estructuraVeta: plan.toMap()['estructura_veta'] ?? '',
            nivel: plan.toMap()['nivel'] ?? '',
          )));

      // Convertir PlanProduccion a PlanTrabajo
      planesTrabajo.addAll(planesProduccion.map((plan) => PlanTrabajo(
            zona: plan.toMap()['zona'] ?? '',
            tipoLabor: plan.toMap()['tipo_labor'] ?? '',
            labor: plan.toMap()['labor'] ?? '',
            ala: plan.toMap()['ala'] ?? '',
            estructuraVeta: plan.toMap()['estructura_veta'] ?? '',
            nivel: plan.toMap()['nivel'] ?? '',
          )));

      // Usar Sets para eliminar duplicados
      Set<String> zonasSet = {};
      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alaSet = {};
      Set<String> vetasSet = {};
      Set<String> nivelesSet = {};

      for (var plan in planesTrabajo) {
        zonasSet.add(plan.zona);
        tiposLaborSet.add(plan.tipoLabor);
        laboresSet.add(plan.labor);
        alaSet.add(plan.ala);
        vetasSet.add(plan.estructuraVeta);
        nivelesSet.add(plan.nivel);
      }

      // Actualizar estado
      setState(() {
        _planesCompletos = planesTrabajo;

        _zonas.clear();
        _zonas.addAll(zonasSet.where((e) => e.isNotEmpty));

        _tiposLabor.clear();
        _tiposLabor.addAll(tiposLaborSet.where((e) => e.isNotEmpty));

        _labores.clear();
        _labores.addAll(laboresSet.where((e) => e.isNotEmpty));

        _alas.clear();
        _alas.addAll(alaSet.where((e) => e.isNotEmpty));

        _vetas.clear();
        _vetas.addAll(vetasSet.where((e) => e.isNotEmpty));

        _niveles.clear();
        _niveles.addAll(nivelesSet.where((e) => e.isNotEmpty));

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

      // If current selection is no longer valid, reset it
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
            .where((labor) => labor != null && labor.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredLabores = List.from(_labores);
      }

      // Reset Labor if no longer valid
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
            .where((ala) => ala != null && ala.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredAlas = List.from(_alas);
      }

      // Reset Ala if no longer valid
      if (_selectedAla != null && !_filteredAlas.contains(_selectedAla)) {
        _selectedAla = null;
      }

      // Filter Vetas based on previous selections (including Ala)
      if (_selectedZona != null ||
          _selectedTipoLabor != null ||
          _selectedLabor != null ||
          _selectedAla != null) {
        _filteredVetas = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor) &&
                (_selectedLabor == null || plan.labor == _selectedLabor) &&
                (_selectedAla == null || plan.ala == _selectedAla))
            .map((plan) => plan.estructuraVeta)
            .where((veta) => veta != null && veta.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredVetas = List.from(_vetas);
      }

      // Reset Veta if no longer valid
      if (_selectedVeta != null && !_filteredVetas.contains(_selectedVeta)) {
        _selectedVeta = null;
      }

      // Filter Niveles based on all previous selections (including Ala)
      if (_selectedZona != null ||
          _selectedTipoLabor != null ||
          _selectedLabor != null ||
          _selectedVeta != null ||
          _selectedAla != null) {
        _filteredNiveles = _planesCompletos
            .where((plan) =>
                (_selectedZona == null || plan.zona == _selectedZona) &&
                (_selectedTipoLabor == null ||
                    plan.tipoLabor == _selectedTipoLabor) &&
                (_selectedLabor == null || plan.labor == _selectedLabor) &&
                (_selectedVeta == null ||
                    plan.estructuraVeta == _selectedVeta) &&
                (_selectedAla == null || plan.ala == _selectedAla))
            .map((plan) => plan.nivel)
            .where((nivel) => nivel != null && nivel.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _filteredNiveles = List.from(_niveles);
      }

      // Reset Nivel if no longer valid
      if (_selectedNivel != null &&
          !_filteredNiveles.contains(_selectedNivel)) {
        _selectedNivel = null;
      }
    });
  }

  // Cargar datos desde la BD para el id dado
  void _loadData(int id) async {
    var registro = await DatabaseHelper().getExploracionById(id);
    if (registro != null) {
      // Si se encontraron datos, se rellenan los campos con la información existente
      _fechaController.text = registro['fecha'] ?? "";
      _turnoController.text = registro['turno'] ?? "";
      _semanaDefaultController.text = registro['semanaDefault'] ?? "";
      _taladroController.text = registro['taladro'] ?? "";
      _piesPorTaladroController.text = registro['pies_por_taladro'] ?? "";

      _selectedZona = registro['zona'];
      _selectedTipoLabor = registro['tipo_labor'];
      _selectedLabor = registro['labor'];
      _selectedAla = registro['ala'];
      _selectedVeta = registro['veta'];
      _selectedNivel = registro['nivel'];
      _selectedTipoPerforacion = registro['tipo_perforacion'];
    }
    setState(() {});
  }

  // Método para guardar el formulario (insertar o actualizar según la existencia del registro)
  Future<void> _guardarFormulario() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> datos = {
        'fecha': _fechaController.text,
        'turno': _turnoController.text,
        'semanaDefault': _semanaDefaultController.text,
        'taladro': _taladroController.text,
        'pies_por_taladro': _piesPorTaladroController.text,
        'zona': _selectedZona,
        'tipo_labor': _selectedTipoLabor,
        'labor': _selectedLabor,
        'ala': _selectedAla,
        'veta': _selectedVeta,
        'nivel': _selectedNivel,
        'tipo_perforacion': _selectedTipoPerforacion,
      };

      // Si ya existe un registro para este id, se actualiza; de lo contrario, se inserta uno nuevo.
      var registroExistente =
          await DatabaseHelper().getExploracionById(widget.exploracionId);
      if (registroExistente != null) {
        await DatabaseHelper().updateExploracion(widget.exploracionId, datos);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos actualizados correctamente')),
        );
      } else {
        await DatabaseHelper().insertExploracionFull(datos);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos guardados correctamente')),
        );
      }
    }
  }

  // Función para simplificar la decoración de los campos
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------- Campos principales ---------
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fechaController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            hintText: 'DD/MM/AAAA',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _turnoController,
                          decoration: const InputDecoration(
                            labelText: 'Turno',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _semanaDefaultController,
                          decoration: const InputDecoration(
                            labelText: 'Semana por defecto',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedZona,
                          decoration: const InputDecoration(
                            labelText: 'Zona',
                          ),
                          items: _zonas.map((zona) {
                            return DropdownMenuItem<String>(
                              value: zona,
                              child: Text(zona),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedZona = value;
                              // Reset dependent fields
                              _selectedTipoLabor = null;
                              _selectedLabor = null;
                              _selectedAla = null;
                              _selectedVeta = null;
                              _selectedNivel = null;
                              // Update filtered lists
                              _updateFilteredLists();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTipoLabor,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Labor',
                          ),
                          items: _filteredTiposLabor.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTipoLabor = value;
                              // Reset dependent fields
                              _selectedLabor = null;
                              _selectedAla = null;
                              _selectedVeta = null;
                              _selectedNivel = null;
                              // Update filtered lists
                              _updateFilteredLists();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedLabor,
                          decoration: const InputDecoration(
                            labelText: 'Labor',
                          ),
                          items: _filteredLabores.map((labor) {
                            return DropdownMenuItem<String>(
                              value: labor,
                              child: Text(labor),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedLabor = value;
                              // Reset dependent fields
                              _selectedAla = null;
                              _selectedVeta = null;
                              _selectedNivel = null;
                              // Update filtered lists
                              _updateFilteredLists();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filteredAlas.contains(_selectedAla)
                              ? _selectedAla
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Ala',
                          ),
                          items: _filteredAlas.map((ala) {
                            return DropdownMenuItem<String>(
                              value: ala,
                              child: Text(ala),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAla = value;
                              _selectedVeta = null;
                              _selectedNivel = null;
                              _updateFilteredLists();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedVeta,
                          decoration: const InputDecoration(
                            labelText: 'Veta',
                          ),
                          items: _filteredVetas.map((veta) {
                            return DropdownMenuItem<String>(
                              value: veta,
                              child: Text(veta),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVeta = value;
                              // Reset dependent fields
                              _selectedNivel = null;
                              // Update filtered lists
                              _updateFilteredLists();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filteredNiveles.contains(_selectedNivel)
                              ? _selectedNivel
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Nivel',
                          ),
                          items: _filteredNiveles.map((nivel) {
                            return DropdownMenuItem<String>(
                              value: nivel,
                              child: Text(nivel),
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
                          value: _selectedTipoPerforacion,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Perforación',
                          ),
                          items: _tiposPerforacion.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taladroController,
                          decoration: const InputDecoration(
                            labelText: 'N° TAL DISP.',
                          ),
                          keyboardType:
                              TextInputType.number, // Muestra teclado numérico
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ], // Solo números
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _piesPorTaladroController,
                          decoration: const InputDecoration(
                            labelText: 'Pies por taladro',
                          ),
                          keyboardType:
                              TextInputType.number, // Muestra teclado numérico
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ], // Solo números
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _guardarFormulario(); // Llama la función para guardar el formulario
                    await _actualizarEstadoEnProceso(); // Luego actualiza el estado
                  },
                  child: Text('Guardar'),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
