import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/PlanMensual.dart';
import 'package:app_seminco/mina%201/models/PlanProduccion.dart';
import 'package:app_seminco/mina%201/models/PlanTrabajo.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/dialogs_labor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MedicionesRemanentesScreen extends StatefulWidget {

  const MedicionesRemanentesScreen({
    Key? key,
  }) : super(key: key);

  @override
  _MedicionesRemanentesScreenState createState() => _MedicionesRemanentesScreenState();
}

class _MedicionesRemanentesScreenState extends State<MedicionesRemanentesScreen> {
  List<Map<String, dynamic>> _mediciones = [];
  List<Map<String, dynamic>> _medicionesFiltradas = [];
  bool _isLoading = true;
  Map<String, TextEditingController> controllers = {};
  Map<int, Map<String, dynamic>> registrosEditados = {};
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController turnoController = TextEditingController();

  final List<String> _zonas = [];
  final List<String> _tiposLabor = [];
  final List<String> _labores = [];
  final List<String> _alas = [];
  final List<String> _vetas = [];
  List<PlanTrabajo> _planesCompletos = [];
  @override
  void initState() {
    super.initState();
    _cargarMedicionesRemanentes();
    _getPlanesCompletos();
  }

Future<void> _cargarMedicionesRemanentes() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final dbHelper = DatabaseHelper_Mina1();
    final mediciones = await dbHelper.obtenerMedicionesHorizontalConRemanente();
    
    // Crear copias editables de todos los mapas
    final medicionesEditables = mediciones.map((map) => Map<String, dynamic>.from(map)).toList();
    
    setState(() {
      _mediciones = medicionesEditables;
      _medicionesFiltradas = medicionesEditables;
      _isLoading = false;
    });
  } catch (e) {
    print("Error al cargar mediciones remanentes: $e");
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _getPlanesCompletos() async {
    try {
      final List<PlanMensual> planesMensuales =
          await DatabaseHelper_Mina1().getPlanes();
      final List<PlanProduccion> planesProduccion =
          await DatabaseHelper_Mina1().getPlanesProduccion();

      List<PlanTrabajo> planesTrabajo = [];

      // Convertir PlanMensual a PlanTrabajo
      planesTrabajo.addAll(planesMensuales.map((plan) => PlanTrabajo(
            zona: plan.toMap()['zona'] ?? '',
            tipoLabor: plan.toMap()['tipo_labor'] ?? '',
            labor: plan.toMap()['labor'] ?? '',
            ala: plan.toMap()['ala'] ?? '',
            estructuraVeta: plan.toMap()['estructura_veta'] ?? '',
            nivel: plan.toMap()['nivel'] ?? '',
            empresa: plan.toMap()['empresa'],
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
      Set<String> EmpresasSet = {};
      Set<String> tiposLaborSet = {};
      Set<String> laboresSet = {};
      Set<String> alaSet = {};
      Set<String> vetasSet = {};
      Set<String> nivelesSet = {};

      for (var plan in planesTrabajo) {
        zonasSet.add(plan.zona);
        EmpresasSet.addAll([if (plan.empresa != null) plan.empresa!]);
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

      });
    } catch (e) {
      print("Error al obtener los planes: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_medicionesFiltradas.isEmpty) {
      return Center(
        child: Text(
          "No hay mediciones remanentes",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Agrupar mediciones por empresa
    final Map<String, List<Map<String, dynamic>>> medicionesPorEmpresa = {};
    for (var medicion in _medicionesFiltradas) {
      final empresa = medicion['empresa']?.toString() ?? 'Sin empresa';
      if (!medicionesPorEmpresa.containsKey(empresa)) {
        medicionesPorEmpresa[empresa] = [];
      }
      medicionesPorEmpresa[empresa]!.add(medicion);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: TextField(
                    controller: fechaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          fechaController.text =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          _filtrarMediciones();
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: turnoController.text.isEmpty
                        ? null
                        : turnoController.text,
                    decoration: InputDecoration(
                      labelText: 'Turno',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['Día', 'Noche'].map((String turno) {
                      return DropdownMenuItem<String>(
                        value: turno,
                        child: Text(turno),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        turnoController.text = newValue ?? '';
                        _filtrarMediciones();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.search, size: 20),
                  label: Text('Buscar'),
                  onPressed: _filtrarMediciones,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Tablas dinámicas por empresa
            Expanded(
              child: ListView(
                children: medicionesPorEmpresa.entries.map((entry) {
                  final empresa = entry.key;
                  final medicionesEmpresa = entry.value;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        empresa,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Table(
                                  border: TableBorder.all(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(0.6),
                                    1: FlexColumnWidth(1.2),
                                    2: FlexColumnWidth(1.2),
                                    3: FlexColumnWidth(1.2),
                                    4: FlexColumnWidth(1.2),
                                    5: FlexColumnWidth(1.3),
                                    6: FlexColumnWidth(1.2),
                                    7: FlexColumnWidth(1.2),
                                    8: FlexColumnWidth(1.2),
                                    9: FlexColumnWidth(1.2),
                                    10: FlexColumnWidth(1.0),
                                    11: FlexColumnWidth(1.0),
                                    12: FlexColumnWidth(0.8),
                                    13: FlexColumnWidth(1.0),
                                  },
                                  children: [
                                    // Encabezados de tabla
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(8)),
                                      ),
                                      children: [
                                        tableCellBold(context, 'N°'),
                                        tableCellBold(context, 'FECHA'),
                                        tableCellBold(context, 'SEMANA'),
                                        tableCellBold(context, 'TURNO'),
                                        tableCellBold(context, 'EMPRESA'),
                                        tableCellBold(context, 'ZONA'),
                                        tableCellBold(context, 'LABOR'),
                                        tableCellBold(context, 'TIPO PERFORACIÓN'),
                                        tableCellBold(context, 'KG EXPLOSIVOS'),
                                        tableCellBold(context, 'AVANCE PROGRAMADO (m)'),
                                        tableCellBold(context, 'ANCHO (m)'),
                                        tableCellBold(context, 'ALTO (m)'),
                                        tableCellBold(context, 'NO APLICA'),
                                        tableCellBold(context, 'REMANENTE'),
                                      ],
                                    ),
                                    // Filas con datos
                                    for (int i = 0; i < medicionesEmpresa.length; i++)
                                      TableRow(children: [
                                        tableCell((i + 1).toString()),
                                        tableCell(medicionesEmpresa[i]['fecha']?.toString() ?? ''),
                                        tableCell(medicionesEmpresa[i]['semana']?.toString() ?? ''),
                                        tableCell(medicionesEmpresa[i]['turno']?.toString() ?? ''),
                                        tableCell(medicionesEmpresa[i]['empresa']?.toString() ?? ''),
                                        tableCell(medicionesEmpresa[i]['zona']?.toString() ?? ''),
                                        tableCellMulti([
                                          medicionesEmpresa[i]['tipo_labor']?.toString() ?? '',
                                          medicionesEmpresa[i]['labor']?.toString() ?? '',
                                          medicionesEmpresa[i]['ala']?.toString() ?? ''
                                        ]),
                                        tableCell(medicionesEmpresa[i]['tipo_perforacion']?.toString() ?? ''),
                                        tableCell(medicionesEmpresa[i]['kg_explosivos']?.toString() ?? ''),
                                        // Campo editable: avance_programado
                                        // Campo editable: avance_programado
tableCellEditable(
  'mediciones',
  'avance_programado',
  i,
  'avance_programado',
  medicionesEmpresa[i]['avance_programado'],
  // Editable solo si NO está activado "NO APLICA"
  medicionesEmpresa[i]['no_aplica'] != 1,
),
// Campo editable: ancho
tableCellEditable(
  'mediciones',
  'dimensiones',
  i,
  'ancho',
  medicionesEmpresa[i]['ancho'],
  // Editable solo si NO está activado "NO APLICA" ni "REMANENTE"
  medicionesEmpresa[i]['no_aplica'] != 1 && medicionesEmpresa[i]['remanente'] != 1,
),
// Campo editable: alto
tableCellEditable(
  'mediciones',
  'dimensiones',
  i,
  'alto',
  medicionesEmpresa[i]['alto'],
  // Editable solo si NO está activado "NO APLICA" ni "REMANENTE"
  medicionesEmpresa[i]['no_aplica'] != 1 && medicionesEmpresa[i]['remanente'] != 1,
),
                                        // Checkbox para No Aplica
                                        TableCell(
  verticalAlignment: TableCellVerticalAlignment.middle,
  child: Checkbox(
    value: medicionesEmpresa[i]['no_aplica'] == 1,
    onChanged: (medicionesEmpresa[i]['remanente'] == 1) 
        ? null // Deshabilitar si remanente está activado
        : (bool? value) {
            setState(() {
              final bool nuevoValor = value!;
              medicionesEmpresa[i]['no_aplica'] = nuevoValor ? 1 : 0;
              
              if (nuevoValor) {
                // Si se activa "NO APLICA"
                // Limpiar TODOS los campos editables
                medicionesEmpresa[i]['avance_programado'] = '';
                medicionesEmpresa[i]['ancho'] = '';
                medicionesEmpresa[i]['alto'] = '';
                
                // Desactivar remanente
                medicionesEmpresa[i]['remanente'] = 0;
                
                // Actualizar controladores
                _actualizarControladores(i, 'avance_programado', '');
                _actualizarControladores(i, 'ancho', '');
                _actualizarControladores(i, 'alto', '');
              }
              
              // Guardar en registros editados
              if (!registrosEditados.containsKey(i)) {
                registrosEditados[i] = Map<String, dynamic>.from(medicionesEmpresa[i]);
              } else {
                registrosEditados[i]!['no_aplica'] = nuevoValor ? 1 : 0;
                if (nuevoValor) {
                  registrosEditados[i]!['avance_programado'] = '';
                  registrosEditados[i]!['ancho'] = '';
                  registrosEditados[i]!['alto'] = '';
                  registrosEditados[i]!['remanente'] = 0;
                }
              }
            });
          },
  ),
),
// Checkbox para Remanente
TableCell(
  verticalAlignment: TableCellVerticalAlignment.middle,
  child: Checkbox(
    value: medicionesEmpresa[i]['remanente'] == 1,
    onChanged: (medicionesEmpresa[i]['no_aplica'] == 1)
        ? null // Deshabilitar si "no aplica" está activado
        : (bool? value) async {
            final index = i;
            final bool activado = value ?? false;

            if (activado) {
              // Activar Remanente
              setState(() {
                medicionesEmpresa[index]['remanente'] = 1;
                medicionesEmpresa[index]['ancho'] = '';
                medicionesEmpresa[index]['alto'] = '';
                _actualizarControladores(index, 'ancho', '');
                _actualizarControladores(index, 'alto', '');

                registrosEditados[index] =
                    Map<String, dynamic>.from(medicionesEmpresa[index]);
              });
            } else {
              // Desactivar Remanente -> preguntar si continúa la misma labor
              final bool? continuar = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("Confirmación"),
                  content: const Text("¿Continúa la misma labor?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Sí"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("No"),
                    ),
                  ],
                ),
              );

              if (continuar == true) {
                // Solo quitar el remanente
                setState(() {
                  medicionesEmpresa[index]['remanente'] = 0;
                  registrosEditados[index] =
                      Map<String, dynamic>.from(medicionesEmpresa[index]);
                });
              }else if (continuar == false) {
  // Mostrar diálogo de nueva labor con selección
  final nuevaInfo = await mostrarDialogoNuevaLabor(
    context,
    _planesCompletos, // Pasar la lista completa de planes
    _zonas.toList(),
    _tiposLabor.toList(),
    _labores.toList(),
    _alas.toList(),
    _vetas.toList(),
  );

  if (nuevaInfo != null) {
    setState(() {
      medicionesEmpresa[index]['remanente'] = 0;
      medicionesEmpresa[index]['zona'] = nuevaInfo['zona'];
      medicionesEmpresa[index]['tipo_labor'] = nuevaInfo['tipo_labor'];
      medicionesEmpresa[index]['labor'] = nuevaInfo['labor'];
      medicionesEmpresa[index]['ala'] = nuevaInfo['ala'];
      medicionesEmpresa[index]['veta'] = nuevaInfo['veta'];

      registrosEditados[index] = Map<String, dynamic>.from(medicionesEmpresa[index]);
    });
  }
}
            }
          },
  ),
),

                                      ]),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Botones de acción
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () {},
                                      label: Text('BORRAR'),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      icon: Icon(Icons.save, size: 18),
                                      label: Text('GUARDAR'),
                                      onPressed: _actualizarMediciones,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

void _actualizarControladores(int index, String campo, String valor) {
  // Buscar todas las claves que coincidan con este índice y campo
  final clavesCoincidentes = controllers.keys.where((key) {
    return key.contains('-$index-$campo');
  }).toList();
  
  // Actualizar todos los controladores coincidentes
  for (var clave in clavesCoincidentes) {
    controllers[clave]!.text = valor;
  }
  
  // También actualizar el valor en el mapa principal
  if (_medicionesFiltradas.length > index) {
    _medicionesFiltradas[index][campo] = valor;
  }
}
void _filtrarMediciones() {
  setState(() {
    _medicionesFiltradas = _mediciones.where((medicion) {
      final fechaMatch = fechaController.text.isEmpty || 
          medicion['fecha']?.toString().contains(fechaController.text) == true;
      final turnoMatch = turnoController.text.isEmpty || 
          medicion['turno']?.toString() == turnoController.text;
      return fechaMatch && turnoMatch;
    }).map((map) => Map<String, dynamic>.from(map)).toList(); // Crear copias editables
  });
}

  Widget tableCellEditable(String tipo, String subTipo, int index,
      String campo, dynamic valor, bool enabled) {
    final key = '$tipo-$subTipo-$index-$campo';
    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: valor?.toString() ?? '');
    }
    final controller = controllers[key]!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: (newValue) {
          if (newValue.isEmpty || double.tryParse(newValue) != null) {
            actualizarValor(tipo, subTipo, index, campo, newValue);
          } else {
            controller.text = valor?.toString() ?? '';
            controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length));
          }
        },
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
    );
  }

Future<void> _actualizarMediciones() async {
  if (registrosEditados.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay cambios para guardar')),
    );
    return;
  }

  try {
    final dbHelper = DatabaseHelper_Mina1();

    for (var entry in registrosEditados.entries) {
      final registro = entry.value;

      final tipo = registro['tipo_labor']?.toString() ?? '';
      final labor = registro['labor']?.toString() ?? '';
      final ala  = registro['ala']?.toString() ?? '';
      final laborCompleta = '$tipo $labor $ala';

      final datosActualizacion = {
        'avance_programado': registro['avance_programado'],
        'ancho': registro['ancho'],
        'alto': registro['alto'],
        'zona': registro['zona'],
        'no_aplica': registro['no_aplica'] ?? 0,
        'remanente': registro['remanente'] ?? 0,
        'labor': laborCompleta,
      };

      await dbHelper.actualizarMedicionHorizontal(
        registro['id'],
        datosActualizacion,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados exitosamente')),
    );

    registrosEditados.clear();
    await _cargarMedicionesRemanentes();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar datos: $e')),
    );
    debugPrint("Error al actualizar mediciones: $e");
  }
}


void actualizarValor(String tipo, String subTipo, int index,
    String campo, String nuevoValor) {
  setState(() {
    try {
      // Intentar modificar directamente
      _medicionesFiltradas[index][campo] = nuevoValor;
    } catch (e) {
      // Si falla, crear una copia editable
      final originalMap = _medicionesFiltradas[index];
      final editableMap = Map<String, dynamic>.from(originalMap);
      editableMap[campo] = nuevoValor;
      _medicionesFiltradas[index] = editableMap;
    }

    // Guardar la fila completa editada
    if (!registrosEditados.containsKey(index)) {
      registrosEditados[index] = Map<String, dynamic>.from(_medicionesFiltradas[index]);
    } else {
      registrosEditados[index]![campo] = nuevoValor;
    }
  });
}

// Función auxiliar para verificar si un mapa es de solo lectura
bool _isMapReadOnly(Map<String, dynamic> map) {
  try {
    map['test_key'] = 'test_value'; // Intentar modificar
    map.remove('test_key'); // Limpiar si funcionó
    return false;
  } catch (e) {
    return true;
  }
}

  Widget tableCellMulti(List<String> texts, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: texts
            .map((text) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(text)),
    );
  }

  Widget tableCellBold(BuildContext context, String text) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 600 ? 8 : 12;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose de todos los controladores
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    fechaController.dispose();
    turnoController.dispose();
    super.dispose();
  }
}