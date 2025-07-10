import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/models/Accesorio.dart';
import 'package:app_seminco/mina%202/models/Explosivo.dart';
import 'package:app_seminco/mina%202/models/explosivos_uni.dart';

class FormularioDespachoScreen extends StatefulWidget {
  final int exploracionId; // Recibir el ID de Datos_trabajo_exploraciones

  const FormularioDespachoScreen({Key? key, required this.exploracionId})
      : super(key: key);

  @override
  _FormularioDespachoScreenState createState() =>
      _FormularioDespachoScreenState();
}

class _FormularioDespachoScreenState extends State<FormularioDespachoScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _detallesDespacho = [];
  Map<String, TextEditingController> _controllers = {};
  int? _despachoId;
  List<Map<String, String>> _accesorios = [];
  List<Map<String, String>> _explosivos = [];
  bool _registroCerrado = false;
  List<ExplosivosUni> milisegundosList = [];
  List<ExplosivosUni> medioSegundosList = [];

  final TextEditingController _observacionesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 20; i++) {
      _controllers['msCant1_$i'] = TextEditingController();
      _controllers['lpCant1_$i'] = TextEditingController();
    }
    _loadDetallesDespacho();
    _verificarEstadoRegistro();
    fetchExplosivosuni();
    _cargarDatos();
  }

  Future<void> _verificarEstadoRegistro() async {
    bool cerrado =
        await DatabaseHelper_Mina2().estaRegistroCerrado(widget.exploracionId);
    setState(() {
      _registroCerrado = cerrado;
    });
  }

  void _cargarDatos() async {
    List<Map<String, String>> accesorios =
        await DatabaseHelper_Mina2().getAccesoriosunidad();
    List<Map<String, String>> explosivos =
        await DatabaseHelper_Mina2().getExplosivosunidad();

    setState(() {
      _accesorios = accesorios;
      _explosivos = explosivos;
    });
  }

  void fetchExplosivosuni() async {
    List<ExplosivosUni> explosivos = await DatabaseHelper_Mina2().getExplosivosUni();

    // Limpiamos las listas antes de agregar nuevos datos
    milisegundosList.clear();
    medioSegundosList.clear();

    for (var explosivo in explosivos) {
      if (explosivo.tipo == "Milisegundo") {
        milisegundosList.add(explosivo);
      } else if (explosivo.tipo == "Medio Segundo") {
        medioSegundosList.add(explosivo);
      }
    }

    // Extraemos los valores únicos de cada lista
    _visibleMsOptions = milisegundosList.map((e) => e.dato.toString()).toSet();
    _visibleLpOptions = medioSegundosList.map((e) => e.dato.toString()).toSet();

    setState(() {}); // Notificamos a la UI para que se actualice
  }

// Función para formatear el número
  String formatNumber(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  void _loadDetallesDespacho() async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper_Mina2()
        .getDetalleDespachoByExploracionId(widget.exploracionId);

    if (detalles.isNotEmpty) {
      var detail = detalles.first; // Toma el primer registro

      _despachoId = detail['id']; // Guardar el ID del despacho

      // Cargar el valor de observaciones si no es null
      final obs = detail['observaciones'];
      if (obs != null) {
        _observacionesController.text = obs.toString();
      }

      setState(() {});

      if (_despachoId != null) {
        _loadDetallesDespachoExplo(_despachoId!);
        _loadDetallesDespachoMateriales(_despachoId!);
      }
    }
  }

  void _loadDetallesDespachoMateriales(int despachoId) async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper_Mina2()
        .getDetalleDespachoByDesapachoExposivosyAccesorios(despachoId);

    setState(() {
      _detallesDespacho = detalles.where((d) => d['cantidad'] != null).toList();
      _initializeControllers();
    });
  }

  void _initializeControllers() {
    for (var detalle in _detallesDespacho) {
      String key = detalle['nombre_material'];
      _controllers[key] =
          TextEditingController(text: detalle['cantidad']?.toString() ?? '');
    }
  }

  // Carga los detalles de despacho desde la BD y actualiza los controladores correspondientes.
  void _loadDetallesDespachoExplo(int despachoId) async {
    List<Map<String, dynamic>> detalles =
        await DatabaseHelper_Mina2().getDetalleDespachoByDespachoId(despachoId);

    for (var detail in detalles) {
      int numero = detail['numero'];
      if (numero >= 1 && numero <= 20) {
        _controllers['msCant1_$numero']?.text = detail['ms_cant1'] ?? "";
        _controllers['lpCant1_$numero']?.text = detail['lp_cant1'] ?? "";
      }
    }

    setState(() {});
  }

  Future<bool> _actualizarDespacho() async {
    if (_despachoId == null) {
      throw Exception('No hay un despacho para actualizar');
    }

    Map<String, dynamic> updatedData = {};

    int result =
        await DatabaseHelper_Mina2().updateDespacho(_despachoId!, updatedData);
    if (result > 0) {
      return true; // Éxito
    } else {
      throw Exception('Error al actualizar el despacho');
    }
  }

  Future<void> _actualizarTodosLosDetalles() async {
    try {
      if (_detallesDespacho.isEmpty) return;

      await Future.wait(_detallesDespacho.map((detalle) {
        int id = detalle['id']; // Obtener el ID del registro
        String key = detalle['nombre_material'];
        String cantidad =
            _controllers[key]?.text ?? ""; // Obtener la cantidad ingresada

        if (cantidad.isNotEmpty) {
          return DatabaseHelper_Mina2()
              .updateDespachoDetalle(id, {'cantidad': cantidad});
        } else {
          return Future.value(); // No actualizar si el campo está vacío
        }
      }));

      print("Todos los detalles del despacho fueron actualizados.");
    } catch (e) {
      print("Error al actualizar detalles: $e");
    }
  }

  Future<bool> _guardarFormulario() async {
    if (_despachoId == null) {
      throw Exception('No se encontró un ID de despacho');
    }

    List<Map<String, dynamic>> detalles = [];

    for (int i = 1; i <= 20; i++) {
      final msCant1 = _controllers['msCant1_$i']!.text;
      final lpCant1 = _controllers['lpCant1_$i']!.text;

      if (msCant1.isNotEmpty || lpCant1.isNotEmpty) {
        detalles.add({
          'numero': i,
          'ms_cant1': msCant1,
          'lp_cant1': lpCant1,
        });
      }
    }

    if (detalles.isNotEmpty) {
      await DatabaseHelper_Mina2().insertDetallesDespacho(_despachoId!, detalles);
      return true; // Éxito
    } else {
      throw Exception('No hay datos para guardar en el formulario');
    }
  }

  Future<void> _actualizarObservaciones() async {
    if (_despachoId == null) {
      throw Exception('No se encontró un ID de despacho');
    }

    final observaciones = _observacionesController.text.trim();

    if (observaciones.isEmpty) return; // No actualiza si está vacío

    await DatabaseHelper_Mina2()
        .actualizarDetalleDespacho(_despachoId!, observaciones);

    print("Observaciones actualizadas correctamente.");
  }

  Future<void> _actualizarTiempos() async {
    if (_despachoId == null) {
      throw Exception('No se encontró un ID de despacho');
    }

    final selectedMs = _getSelectedMsOption();
    final selectedLp = _getSelectedLpOption();

    double? ms = selectedMs != null ? double.tryParse(selectedMs) : null;
    double? lp = selectedLp != null ? double.tryParse(selectedLp) : null;

    if (ms == null && lp == null) return;

    int filasActualizadas = await DatabaseHelper_Mina2().actualizarTiemposDespacho(
      _despachoId!,
      ms,
      lp,
    );

    if (filasActualizadas > 0) {
      print('Tiempos actualizados correctamente: MS=$ms, LP=$lp');
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// Método para construir una fila de inputs usando una lista de controladores.
Widget _buildInputRow(List<TextEditingController> controllers) {
  return Row(
    children: controllers
        .map(
          (controller) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextFormField(
                controller: controller,
                style: const TextStyle(fontSize: 12),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                enabled: !_registroCerrado,
                decoration: const InputDecoration(
                  hintText: 'Cant',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

  Widget _buildNumberCell(int number) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        number.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Método para construir la tabla. Se generan filas de 'start' a 'end'.
  Widget _buildTable(int start, int end) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(0.3), // N°
        1: FlexColumnWidth(2.0), // MS
        2: FlexColumnWidth(2.0), // LP
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.black12),
          children: [
            _buildHeaderCell('N°'),
            _buildHeaderWithButtons(
              'Milisegundo (MS)',
              milisegundosList.map((e) => e.dato.toString()).toList(),
              _visibleMsOptions,
              _toggleMsOption,
            ),
            _buildHeaderWithButtons(
              'Medio Segundo (LP)',
              medioSegundosList.map((e) => e.dato.toString()).toList(),
              _visibleLpOptions,
              _toggleLpOption,
            ),
          ],
        ),
        for (int i = start; i <= end; i++)
          TableRow(
            children: [
              _buildNumberCell(i),
              _buildInputRow([_controllers['msCant1_$i']!]),
              _buildInputRow([_controllers['lpCant1_$i']!]),
            ],
          ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Set<String> _visibleMsOptions = {};
  Set<String> _visibleLpOptions = {};

  String? _getSelectedMsOption() {
    return _visibleMsOptions.length == 1 ? _visibleMsOptions.first : null;
  }

  String? _getSelectedLpOption() {
    return _visibleLpOptions.length == 1 ? _visibleLpOptions.first : null;
  }

  void _toggleMsOption(String option) {
    if (_registroCerrado) return;
    setState(() {
      if (_visibleMsOptions.length == 1 && _visibleMsOptions.contains(option)) {
        _visibleMsOptions = milisegundosList
            .map((e) => e.dato.toString())
            .toSet(); // Restaurar todas
      } else {
        _visibleMsOptions = {option}; // Mostrar solo la seleccionada
      }
    });
  }

// Método para alternar opciones visibles de Medio Segundo
  void _toggleLpOption(String option) {
    if (_registroCerrado) return;
    setState(() {
      if (_visibleLpOptions.length == 1 && _visibleLpOptions.contains(option)) {
        _visibleLpOptions =
            medioSegundosList.map((e) => e.dato.toString()).toSet();
      } else {
        _visibleLpOptions = {option};
      }
    });
  }

  Widget _buildHeaderWithButtons(String title, List<String> options,
      Set<String> visibleOptions, Function(String) onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: options
                .where((option) => visibleOptions.contains(option))
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: _registroCerrado
                          ? null
                          : () => onTap(option), // ← Desactiva si está cerrado
                      style: _registroCerrado
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[
                                  300], // Fondo gris si está deshabilitado
                              foregroundColor: Colors.grey[500], // Texto gris
                            )
                          : null,
                      child: Text(option),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
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
              const SizedBox(height: 10),
              // Inputs organizados en filas de 4 en 4 sin métodos adicionales
              Column(
                children: List.generate(
                  (_detallesDespacho.length / 2)
                      .ceil(), // Número de filas necesarias
                  (index) {
                    int startIndex = index * 2;
                    int endIndex = startIndex + 2;
                    List detallesFila = _detallesDespacho.sublist(
                        startIndex,
                        endIndex > _detallesDespacho.length
                            ? _detallesDespacho.length
                            : endIndex);

                    return Row(
                      children: detallesFila.map((detalle) {
                        String key = detalle['nombre_material'];

                        // Buscar unidad de medida en accesorios y explosivos
                        String unidadMedida = '';
                        var accesorio = _accesorios.firstWhere(
                          (a) => a['tipo'] == key,
                          orElse: () => {},
                        );
                        var explosivo = _explosivos.firstWhere(
                          (e) => e['tipo'] == key,
                          orElse: () => {},
                        );

                        // Asignar unidad si se encuentra en accesorios o explosivos
                        if (accesorio.isNotEmpty) {
                          unidadMedida = accesorio['unidad_medida']!;
                        } else if (explosivo.isNotEmpty) {
                          unidadMedida = explosivo['unidad_medida']!;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextFormField(
                              enabled:
                                  !_registroCerrado, // ← Control de habilitación/deshabilitación
                              controller: _controllers[key],
                              decoration: InputDecoration(
                                labelText:
                                    '${detalle['nombre_material']} (${unidadMedida.isNotEmpty ? unidadMedida : ''})',
                                border: const OutlineInputBorder(),
                                filled:
                                    _registroCerrado, // Cambia el fondo si está deshabilitado
                                fillColor:
                                    _registroCerrado ? Colors.grey[200] : null,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              // Mostrar las 20 filas divididas en dos tablas
              LayoutBuilder(
                builder: (context, constraints) {
                  // Si el ancho disponible es menor a 600, asumimos que es un teléfono
                  bool isSmallScreen = constraints.maxWidth < 600;

                  return isSmallScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTable(1, 10),
                            const SizedBox(height: 16),
                            _buildTable(11, 20),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTable(1, 10)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTable(11, 20)),
                          ],
                        );
                },
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _observacionesController,
                enabled:
                    !_registroCerrado, // ← Se desactiva si el registro está cerrado
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  border: const OutlineInputBorder(),
                  filled:
                      _registroCerrado, // Cambia el fondo si está deshabilitado
                  fillColor: _registroCerrado
                      ? Colors.grey[200]
                      : null, // Gris claro cuando está bloqueado
                ),
              ),
              const SizedBox(height: 20),
              // Botón para guardar
              Center(
                child: ElevatedButton(
                  onPressed: _registroCerrado
                      ? null
                      : () async {
                          try {
                            await Future.wait([
                              _actualizarTodosLosDetalles(),
                              _guardarFormulario(),
                              _actualizarObservaciones(),
                              _actualizarTiempos(),
                              // _actualizarDespacho(),
                            ]);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Se guardaron correctamente')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _registroCerrado
                        ? Colors.grey
                        : Colors.blue, // ⚠️ Cambia color si está cerrado
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Guardar'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
