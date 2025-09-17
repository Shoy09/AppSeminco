import 'package:app_seminco/mina%202/screens/ChecklistScreen.dart';
import 'package:app_seminco/mina%202/screens/SubEstadoDialog.dart';
import 'package:app_seminco/mina%202/screens/horizontal/registro_perforacion_sreen_no_operativas.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_seminco/mina%202/models/Empresa.dart';
import 'package:app_seminco/mina%202/models/Equipo.dart';
import 'package:app_seminco/mina%202/screens/Estados/estado_perforacion_screen.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'registro_perforacion_sreen.dart';

class ListaPerforacionHorizontalScreen extends StatefulWidget {
final String tipoOperacion;
final String? rolUsuario; 
  const ListaPerforacionHorizontalScreen({Key? key, required this.tipoOperacion, this.rolUsuario })
      : super(key: key);

  @override
  _ListaPerforacionScreenState createState() => _ListaPerforacionScreenState();
}

class _ListaPerforacionScreenState extends State<ListaPerforacionHorizontalScreen> {
  String? selectedTurno;
  String? selectedEquipo;
  String? selectedCodigo;
  int? operacionId;
  String? estado;

  String? selectedEmpresa;
  String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool showCreateButton = true;
  bool foundData = false;

  List<String> turnos = ['DÍA', 'NOCHE'];
  List<String> equipos = [];
  List<String> codigosFiltrados = [];
  List<String> empresas = [];


  List<Map<String, String>> currentData = [];
  List<Map<String, String>> currentDataDialog = [];
  List<Map<String, dynamic>> estadosBD = [];

  final Map<String, List<Map<String, String>>> datadialog = {
    'OPERATIVO': [],
    'DEMORA': [],
    'MANTENIMIENTO': [],
    'RESERVA': [],
    'FUERA DE PLAN': [],
  };
  @override
  void initState() {
    super.initState();
    _getEmpresas();
    _getEquipos(widget.tipoOperacion);
    // Determinamos el turno automáticamente al iniciar
    selectedTurno = _getTurnoBasedOnTime();
    _fetchOperacionData(); // Hacemos la consulta
         obtenerEstadosBD();
  }

    void obtenerEstadosBD() async {
    estadosBD = await DatabaseHelper_Mina2().getEstadosBD(
        widget.tipoOperacion); // 🔹 Pasamos tipoOperacion como proceso
    print(
        "Estados obtenidos de la BDEstados para proceso '${widget.tipoOperacion}': $estadosBD");

    // Limpiamos la lista antes de actualizar
    datadialog.forEach((key, value) => value.clear());

    // Agregar los estados filtrados a la lista correcta
    for (var estado in estadosBD) {
      String estadoPrincipal = estado['estado_principal'];
      if (datadialog.containsKey(estadoPrincipal)) {
        datadialog[estadoPrincipal]?.add({
          "Nombre": estado['tipo_estado'],
          "Código": estado['codigo'].toString(),
        });
      }
    }

    setState(() {}); // 🔹 Actualiza la UI con los nuevos datos
  }

  Future<void> _getEmpresas() async {
    try {
      final dbHelper = DatabaseHelper_Mina2();
      List<Empresa> empresasList = await dbHelper.getEmpresas();

      print("Empresas obtenidas de la BD local: $empresasList");

      // Usar un Set para evitar duplicados
      Set<String> empresasSet = {};

      for (var empresa in empresasList) {
        var empresaMap = empresa.toMap();
        empresasSet.add(empresaMap['nombre'] ?? '');
      }

      // Actualizar la lista de empresas
      setState(() {
        empresas.clear();
        empresas.addAll(empresasSet.where((element) => element.isNotEmpty));
      });
    } catch (e) {
      print("Error al obtener las empresas: $e");
    }
  }

  Future<void> _getEquipos(String tipoOperacion) async {
    try {
      final dbHelper = DatabaseHelper_Mina2();
      List<Equipo> equiposList = await dbHelper.getEquipos();

      // Filtrar equipos por el proceso tipoOperacion
      List<String> equiposFiltrados = equiposList
          .where((equipo) => equipo.proceso == tipoOperacion)
          .map((equipo) => equipo.nombre)
          .toSet()
          .toList();

      // Filtrar equipos para mostrar solo los códigos correspondientes
      setState(() {
        equipos.clear();
        equipos.addAll(equiposFiltrados);
      });
    } catch (e) {
      print("Error al obtener los equipos: $e");
    }
  }

  void _filtrarCodigosPorEquipo(String equipoNombre) {
    final dbHelper = DatabaseHelper_Mina2();

    dbHelper.getEquipos().then((equiposList) {
      List<String> codigos = equiposList
          .where((equipo) => equipo.nombre == equipoNombre)
          .map((equipo) => equipo.codigo)
          .toSet()
          .toList();

      setState(() {
        codigosFiltrados = codigos;
        selectedCodigo = null; // Resetear la selección del código
      });
    });
  }

  // Determina el turno basado en la hora actual
  String _getTurnoBasedOnTime() {
    final currentHour = DateTime.now().hour;
    if (currentHour >= 7 && currentHour < 19) {
      return 'DÍA'; // Turno Día
    } else {
      return 'NOCHE'; // Turno Noche
    }
  }

Future<void> _fetchOperacionData() async {
  if (selectedTurno != null && fechaActual.isNotEmpty) {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> data;
    
    // Elegir la consulta adecuada según el rol
    if (widget.rolUsuario == 'Master') {
      data = await dbHelper.getOperacionByTurnoAndFechaMaster(
          selectedTurno!, fechaActual, widget.tipoOperacion);
    } else {
      data = await dbHelper.getOperacionByTurnoAndFecha(
          selectedTurno!, fechaActual, widget.tipoOperacion);
    }

    // Imprime los datos recibidos
    print('Datos recibidos de la base de datos: $data');

    if (data.isNotEmpty) {
      setState(() {
        selectedTurno = data[0]['turno'];
        selectedEquipo = data[0]['equipo'];
        selectedEmpresa = data[0]['empresa'];
        selectedCodigo = data[0]['codigo'];
        codigosFiltrados = [data[0]['codigo']];
        operacionId = data[0]['id'];
        estado = data[0]['estado'];
        showCreateButton = false;
        foundData = true;
      });
    } else {
      setState(() {
        operacionId = null; // Asegurar que se establezca a null cuando no hay datos
        selectedEquipo = null;
        selectedCodigo = null;
        selectedEmpresa = null;
        estado = null;
        foundData = false;
        showCreateButton = true;
        codigosFiltrados = [];
      });
    }

    // Llamar a fetchEstados en ambos casos
    fetchEstados();
  }
}

void mostrarDialogoCerrarRegistro(BuildContext context, int? operacionId, String turno, {
  required VoidCallback onRegistroCerrado,
}) async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

  List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(operacionId!);

  if (estados.isEmpty) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No se puede cerrar"),
          content: Text("No puedes cerrar este registro porque no hay estados asociados."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Entendido"),
            ),
          ],
        );
      },
    );
    return;
  }

  Map<String, dynamic> ultimoEstado = estados.last;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirmar cierre"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¿Estás seguro de que quieres cerrar este registro?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              // 1. Determinar hora de inicio para el estado RESERVA
              String horaReservaInicio = (turno == 'DÍA') ? '17:30' : '05:30';
              
              // 2. Actualizar hora_final del último estado actual
              await dbHelper.actualizarHoraFinal(ultimoEstado['id'], horaReservaInicio);
              
              // 3. Crear nuevo estado RESERVA (401)
              int newNumber = estados.isNotEmpty 
                  ? (estados.last['numero'] as int) + 1 
                  : 1;
              
              await dbHelper.createReservaEstado(
                operacionId!,
                newNumber,
                horaReservaInicio,
                (turno == 'DÍA') ? '19:00' : '07:00', // Hora final según turno
              );

              // 4. Cerrar la operación
              await dbHelper.cerrarOperacion(operacionId!);
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Registro cerrado exitosamente"),
                  backgroundColor: Colors.green,
                ),
              );
              
              // 5. Limpiar y recargar
              if (mounted) {
                setState(() {
                  selectedTurno = _getTurnoBasedOnTime();
                  selectedEquipo = null;
                  selectedCodigo = null;
                  selectedEmpresa = null;
                  operacionId = null;
                  estado = null;
                  foundData = false;
                  showCreateButton = true;
                  codigosFiltrados = [];
                });
                _getEquipos(widget.tipoOperacion);
                _getEmpresas();
                _fetchOperacionData();
                onRegistroCerrado();
              }
            },
            child: Text("Cerrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}
  void showHorometroDialog(BuildContext context, int operacionId, String estado) async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> horometros =
      (await dbHelper.getHorometrosByOperacion(operacionId))
          .map((map) => Map<String, dynamic>.from(map))
          .toList(); // Convertir a lista mutable

  bool isEditable = estado.toLowerCase() != "cerrado"; // Determinar si es editable

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Horómetro",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[300]),
                            children: [
                              _buildTableCell("Nombre", isHeader: true),
                              _buildTableCell("Inicial", isHeader: true),
                              _buildTableCell("Final", isHeader: true),
                              _buildTableCell("OP", isHeader: true),
                              _buildTableCell("INOP", isHeader: true),
                            ],
                          ),
                          for (int i = 0; i < horometros.length; i++)
                            TableRow(
                              children: [
                                _buildTableCell(horometros[i]["nombre"]),
                                _buildEditableCell(
                                  horometros[i]["inicial"],
                                  isEditable,
                                  (value) {
                                    horometros[i]["inicial"] = _parseDouble(value);
                                  },
                                ),
                                _buildEditableCell(
                                  horometros[i]["final"],
                                  isEditable,
                                  (value) {
                                    horometros[i]["final"] = _parseDouble(value);
                                  },
                                ),
                                _buildCheckboxCell(
                                  horometros[i]["EstaOP"],
                                  isEditable,
                                  (value) {
                                    setState(() {
                                      horometros[i]["EstaOP"] = value ? 1 : 0;
                                    });
                                  },
                                ),
                                _buildCheckboxCell(
                                  horometros[i]["EstaINOP"],
                                  isEditable,
                                  (value) {
                                    setState(() {
                                      horometros[i]["EstaINOP"] = value ? 1 : 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
  onPressed: isEditable ? () async {
    List<int> errores = [];

    for (int i = 0; i < horometros.length; i++) {
      final inicial = horometros[i]["inicial"];
      final finalHoro = horometros[i]["final"];

      // Si el final NO está vacío ni nulo ni cero, validar que sea mayor
      if (finalHoro != null && finalHoro != 0 && finalHoro <= inicial) {
        errores.add(i);
      }
    }

    if (errores.isNotEmpty) {
      debugPrint("Errores en filas: ${errores.map((i) => i + 1).join(", ")}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error en filas: ${errores.map((i) => i + 1).join(", ")}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Guardar datos
    for (var horometro in horometros) {
      await dbHelper.updateHorometro(horometro);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Horómetros guardados correctamente"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  } : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: isEditable ? Color(0xFF21899C) : Colors.grey,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  ),
  child: Text("Guardar", style: TextStyle(color: Colors.white)),
)

                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildTableCell(String text, {bool isHeader = false}) {
  return Padding(
    padding: EdgeInsets.all(8.0),
    child: Text(
      text,
      style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
    ),
  );
}

Widget _buildEditableCell(dynamic value, bool isEditable, Function(String) onChanged) {
  String formattedValue = (value == 0.0)
      ? "" // Si es 0.0, mostrar vacío
      : (value % 1 == 0) 
          ? value.toInt().toString() // Si es entero, quitar decimales
          : value.toString(); // Si tiene decimales, mostrar completo

  return Padding(
    padding: EdgeInsets.all(8.0),
    child: TextFormField(
      initialValue: formattedValue,
      keyboardType: TextInputType.number,
      enabled: isEditable,
      onChanged: onChanged,
      decoration: InputDecoration(border: InputBorder.none),
    ),
  );
}

Widget _buildCheckboxCell(int value, bool isEditable, Function(bool) onChanged) {
  return Padding(
    padding: EdgeInsets.all(8.0),
    child: Checkbox(
      value: value == 1,
      onChanged: isEditable ? (bool? newValue) => onChanged(newValue ?? false) : null,
    ),
  );
}

double _parseDouble(String value) {
  return double.tryParse(value) ?? 0.0;
}


  // Callback para actualizar los datos
  void _refreshData() {
    setState(() {}); // Esto forzará una recarga de la tabla
  }

@override
Widget build(BuildContext context) {
  var codigoOperativos = currentData;
  return Scaffold(
    appBar: AppBar(
      title: Text('Operación: ${widget.tipoOperacion}'),
      backgroundColor: Color(0xFF21899C),
    ),
    body: SingleChildScrollView(  // Añadido para manejar el desplazamiento
      child: Column(
        children: [
          // Card con los campos de selección
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _buildReadOnlyField("Fecha", fechaActual),
                    _buildDropdown("Turno", turnos, selectedTurno, (value) {
                      setState(() {
                        selectedTurno = value;
                      });
                    }),
                    _buildDropdown("Equipo", equipos, selectedEquipo, (value) {
                      setState(() {
                        selectedEquipo = value;
                        _filtrarCodigosPorEquipo(value!);
                      });
                    }),
                    _buildDropdown("Código", codigosFiltrados, selectedCodigo, (value) {
                      setState(() {
                        selectedCodigo = value;
                      });
                    }),
                    _buildDropdown("Empresa", empresas, selectedEmpresa, (value) {
                      setState(() {
                        selectedEmpresa = value;
                      });
                    }),
                    
                    SizedBox(height: 20),
                    
                    if (showCreateButton)
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedTurno == null ||
                                selectedEquipo == null ||
                                selectedCodigo == null ||
                                selectedEmpresa == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Por favor, selecciona todos los campos antes de crear la operación.'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              return;
                            }
                            
                            String turno = selectedTurno!;
                            String equipo = selectedEquipo!;
                            String codigo = selectedCodigo!;
                            String empresa = selectedEmpresa!;
                            String fecha = fechaActual;
                            String tipoOperacion = widget.tipoOperacion;

                            List<Map<String, dynamic>> checklistItems =
    await DatabaseHelper_Mina2()
        .getCheckListByProceso(tipoOperacion);

print("Checklist items para $tipoOperacion: $checklistItems");

                              int id = await DatabaseHelper_Mina2().insertOperacion(
  turno,
  equipo,
  codigo,
  empresa,
  fecha,
  tipoOperacion,
  checklistItems, // ✅ PASA LOS checklistItems aquí
);

                            if (id > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Operación creada con éxito'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              await _fetchOperacionData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al crear la operación'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text("Crear"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Sección de botones de estado y tabla
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Botones de estado
                SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildStateButton('OPERATIVO', Colors.green, codigoOperativos),
      SizedBox(width: 10),
      _buildStateButton('DEMORA', Colors.yellow, codigoOperativos),
      SizedBox(width: 10),
      _buildStateButton('MANTENIMIENTO', Colors.red, codigoOperativos),
      SizedBox(width: 10),
      _buildStateButton('RESERVA', Colors.orange, codigoOperativos),
      SizedBox(width: 10),
      _buildStateButton('FUERA DE PLAN', Colors.blue, codigoOperativos),
    ],
  ),
),
                SizedBox(height: 20),
                
                // Tabla de códigos - Removido el Expanded y añadido un Container con altura fija
                Container(
                  height: MediaQuery.of(context).size.height * 0.5, // 50% de la altura de la pantalla
                  color: Colors.white,
                  padding: EdgeInsets.all(10),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildCodigoTable()),
                            SizedBox(width: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),

    // Botones de navegación inferiores
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
              onPressed: () {
                if (selectedTurno != null &&
                    selectedEquipo != null &&
                    selectedEmpresa != null &&
                    operacionId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChecklistScreen(
                          operacionId: operacionId!,
                          ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Por favor, selecciona todos los campos antes de continuar"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF21899C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("CheckList", style: TextStyle(color: Colors.white)),
            ),
          
          ElevatedButton(
            onPressed: () {
              if (operacionId != null) {
                showHorometroDialog(context, operacionId!, estado!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Por favor, selecciona todos los campos antes de continuar"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF21899C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              textStyle: TextStyle(fontSize: 16),
            ),
            child: Text("Horómetro", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: estado == 'cerrado'
                ? null
                : () {
                    if (operacionId != null) {
                      mostrarDialogoCerrarRegistro(
                        context, 
                        operacionId!, 
                        selectedTurno ?? '', 
                        onRegistroCerrado: _refreshData,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("No hay operación seleccionada"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: estado == 'cerrado' ? Colors.grey : Color(0xFF21899C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              textStyle: TextStyle(fontSize: 16),
            ),
            child: Text(
              "Cerrar registro",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDropdown(String label, List<String> options,
      String? selectedOption, Function(String?) onChanged) {
    return Container(
      width: 200, // Tamaño reducido de los spinners
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: selectedOption?.isNotEmpty ?? false
            ? selectedOption
            : null, // Comprobar si no es nulo
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: foundData
            ? null
            : onChanged, // Deshabilita el Dropdown si foundData es true
      ),
    );
  }

Widget _buildReadOnlyField(String label, String value) {
  return Container(
    width: 160,
    child: InkWell(
      onTap: foundData 
          ? null  // Deshabilita el tap si hay datos
          : () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value),
      ),
    ),
  );
}

Future<void> _selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  
  if (picked != null && picked != DateTime.parse(fechaActual)) {
    setState(() {
      fechaActual = DateFormat('yyyy-MM-dd').format(picked);
      _fetchOperacionData(); // Actualizar datos con la nueva fecha
    });
  }
}

Widget _buildStateButton(
  String label,
  Color color,
  List<Map<String, String>> codigoOperativos,
) {
  return GestureDetector(
    onTap: () {
      if (selectedTurno == null || operacionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes crear una operación primero'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      
      showRegisterOperationDialog(
        context,
        codigoOperativos,
        selectedTurno!,
        operacionId!,
        label,
      );
    },
    child: Container(
      height: 50,
      width: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: MediaQuery.of(context).size.width < 600 ? 8 : 14,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}


void showRegisterOperationDialog(
  BuildContext context,
  List<Map<String, String>> codigoOperativos,
  String turno,
  int operacionId,
  String selectedState, {
  Map<String, String>? existingRecord,
}) {
  print('Turno: $turno');
  print('operacionId: $operacionId');
  print('SelectedState: $selectedState');
  print('Existing Record: $existingRecord');

  // Función auxiliar para comparar tiempos
  int _compareTimes(String time1, String time2) {
    List<int> parts1 = time1.split(':').map(int.parse).toList();
    List<int> parts2 = time2.split(':').map(int.parse).toList();
    
    if (parts1[0] != parts2[0]) return parts1[0] - parts2[0];
    return parts1[1] - parts2[1];
  }

  // Variables para manejar el estado
  String? selectedCodigo;
  String? selectedTime;
  final timeController = TextEditingController();
  final isEditing = existingRecord != null;

  // Si estamos editando, inicializamos los valores
  if (isEditing) {
    selectedCodigo = existingRecord['codigo'];
    selectedTime = existingRecord['hora_inicio'];
    timeController.text = existingRecord['hora_inicio'] ?? '';
  }

  // Función para generar intervalos de tiempo cada 5 minutos
  List<String> generateTimeIntervals(String turno) {
    List<String> times = [];
    if (turno == "DÍA") {
      // Turno día: 07:00 - 17:25
      for (int hour = 7; hour <= 17; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 17 && minute > 25) break;
          times.add(
              "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
    } else {
      // Turno noche: 19:00 - 05:25
      List<String> nightTimes = [];
      // Primera parte: 19:00 - 23:55
      for (int hour = 19; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          nightTimes.add(
              "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
      // Segunda parte: 00:00 - 05:25
      for (int hour = 0; hour <= 5; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 5 && minute > 25) break;
          nightTimes.add(
              "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
      times.addAll(nightTimes);
    }
    return times;
  }

  List<DropdownMenuItem<String>> obtenerOpcionesUnicas(
      List<Map<String, dynamic>> data) {
    final seen = <String>{};
    return data.where((e) => seen.add(e["Código"] as String? ?? "")).map((e) {
      String codigo = e["Código"] as String? ?? "";
      String tipoEstado = e["Nombre"] as String? ?? "";
      return DropdownMenuItem<String>(
        value: codigo,
        child: Text("$codigo - $tipoEstado", style: TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  List<Map<String, String>> currentDataDialog = datadialog[selectedState] ?? [];

  // Función para obtener el rango de horas válidas al editar
  List<String> getValidTimeRangeForEdit() {
    if (!isEditing) return [];
    
    // Encontrar el índice del registro actual
    int currentIndex = codigoOperativos.indexWhere(
      (item) => item["id"] == existingRecord!["id"],
    );
    
    if (currentIndex == -1) return [];
    
    String? minTime;
    String? maxTime;
    
    // Si hay registro anterior, su hora_inicio es el límite inferior
    if (currentIndex > 0) {
      minTime = codigoOperativos[currentIndex - 1]["hora_inicio"];
    }
    
    // Si hay registro siguiente, su hora_inicio es el límite superior
    if (currentIndex < codigoOperativos.length - 1) {
      maxTime = codigoOperativos[currentIndex + 1]["hora_inicio"];
    }
    
    // Generar todas las opciones de tiempo
    List<String> allTimes = generateTimeIntervals(turno);
    
    // Filtrar según los límites
    return allTimes.where((time) {
      if (minTime != null && _compareTimes(time, minTime) <= 0) return false;
      if (maxTime != null && _compareTimes(time, maxTime) >= 0) return false;
      return true;
    }).toList();
  }

  bool isValidTimeForShift(String time, String shift) {
    try {
      final hour = int.parse(time.split(':')[0]);
      final minute = int.parse(time.split(':')[1]);
      if (shift == "DÍA") {
        // Validar entre 7:00 y 17:25
        if (hour < 7 || hour > 17) return false;
        if (hour == 17 && minute > 25) return false;
      } else {
        // Validar entre 19:00-23:55 y 00:00-05:25
        if (hour > 5 && hour < 19) return false;
        if (hour == 5 && minute > 25) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isLastRecord() {
    if (!isEditing || codigoOperativos.isEmpty) return false;
    return codigoOperativos.last["id"] == existingRecord!["id"];
  }

  String horaFinalTurno = turno == "DÍA" ? "19:00" : "07:00";
  bool esCambioTurno = DateTime.now().hour == (turno == "DÍA" ? 19 : 7) && 
                       DateTime.now().minute == 0;

  if (esCambioTurno && codigoOperativos.isNotEmpty && !isEditing) {
    int lastId = int.parse(codigoOperativos.last["id"]!);
    DatabaseHelper_Mina2().updateHoraFinal(lastId, horaFinalTurno);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Generar opciones de tiempo disponibles
          List<String> timeOptions = generateTimeIntervals(turno);
          
          // Filtrar horas disponibles según si es edición o creación
          List<String> availableTimeOptions;
          
          if (isEditing) {
            // En edición: usar el rango entre registro anterior y siguiente
            availableTimeOptions = getValidTimeRangeForEdit();
            
            // Asegurarnos de que el selectedTime esté en las opciones disponibles
            if (selectedTime != null && !availableTimeOptions.contains(selectedTime)) {
              availableTimeOptions.add(selectedTime!);
              availableTimeOptions.sort((a, b) => _compareTimes(a, b));
            }
          } else {
            // En creación: horas posteriores a la última registrada
            List<String> registeredHours = codigoOperativos
                .map((item) => item["hora_inicio"] ?? '')
                .where((hora) => hora.isNotEmpty)
                .toList();
                
            availableTimeOptions = timeOptions.where((hora) {
              if (!isValidTimeForShift(hora, turno)) return false;
              if (registeredHours.isEmpty) return true;
              
              // Encontrar la última hora registrada
              String lastTime = registeredHours.reduce((a, b) => 
                  _compareTimes(a, b) > 0 ? a : b);
              
              return _compareTimes(hora, lastTime) > 0;
            }).toList();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Center(
              child: Text(
                isEditing ? "EDITAR OPERACIÓN" : "REGISTRA OPERACIÓN",
                style: TextStyle(fontWeight: FontWeight.bold)
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Código (*)",
                        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                      ),
                      value: selectedCodigo,
                      items: obtenerOpcionesUnicas(currentDataDialog),
                      onChanged: (value) {
                        setState(() {
                          selectedCodigo = value;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Hora Inicio (*)",
                        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                      ),
                      value: selectedTime,
                      items: availableTimeOptions
                          .map((time) => DropdownMenuItem(
                                value: time,
                                child: Text(time, style: TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTime = value;
                        });
                      },
                      menuMaxHeight: 200,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCodigo = isEditing ? existingRecord['codigo'] : null;
                              selectedTime = isEditing ? existingRecord['hora_inicio'] : null;
                              if (isEditing) {
                                timeController.text = existingRecord['hora_inicio'] ?? '';
                              } else {
                                timeController.clear();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: Text("Limpiar"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedCodigo != null && selectedTime != null) {
                              bool horaExiste = codigoOperativos
                                  .where((item) => !isEditing || item["id"] != existingRecord!["id"])
                                  .any((item) => item["hora_inicio"] == selectedTime);
                              
                              if (horaExiste) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: La Hora Inicio ya está registrada."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (!isValidTimeForShift(selectedTime!, turno)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("La hora no está dentro del turno $turno"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Validación específica para edición
                              if (isEditing && !getValidTimeRangeForEdit().contains(selectedTime!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("La hora debe estar entre el registro anterior y el siguiente"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (isEditing) {
                                // Lógica para actualizar el registro actual
                                int result = await DatabaseHelper_Mina2().updateEstado(
                                  int.parse(existingRecord!["id"]!),
                                  int.parse(existingRecord["numero"]!),
                                  selectedState,
                                  selectedCodigo!,
                                  selectedTime!,
                                  existingRecord["hora_final"] ?? "",
                                );
                                
                                final currentIndex = codigoOperativos.indexWhere(
                                  (item) => item["id"] == existingRecord["id"],
                                );
                                
                                if (currentIndex > 0) {
                                  // 🔹 Actualizar hora_final del registro anterior con la nueva hora_inicio de este
                                  final previousRecord = codigoOperativos[currentIndex - 1];
                                  await DatabaseHelper_Mina2().updateHoraFinal(
                                    int.parse(previousRecord["id"]!),
                                    selectedTime!,
                                  );
                                }
                                
                                if (currentIndex < codigoOperativos.length - 1) {
                                  // 🔹 Si no es el último, la hora_final de este registro debe ser la hora_inicio del siguiente
                                  final nextRecord = codigoOperativos[currentIndex + 1];
                                  await DatabaseHelper_Mina2().updateHoraFinal(
                                    int.parse(existingRecord["id"]!),
                                    nextRecord["hora_inicio"]!,
                                  );
                                } else {
                                  // 🔹 Si es el último, su hora_final queda vacía
                                  await DatabaseHelper_Mina2().updateHoraFinal(
                                    int.parse(existingRecord["id"]!),
                                    "",
                                  );
                                }
                                
                                if (result > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Registro actualizado correctamente."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  fetchEstados();
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error al actualizar el registro."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Lógica para crear
                                int newNumber = codigoOperativos.isNotEmpty ? 
                                    int.parse(codigoOperativos.last["numero"]!) + 1 : 1;
                                    
                                String horaInicio = codigoOperativos.isNotEmpty && 
                                    codigoOperativos.last["hora_final"]!.isNotEmpty ? 
                                    codigoOperativos.last["hora_final"]! : selectedTime!;
                                    
                                if (codigoOperativos.isNotEmpty) {
                                  int lastId = int.parse(codigoOperativos.last["id"]!);
                                  await DatabaseHelper_Mina2().updateHoraFinal(lastId, selectedTime!);
                                }
                                
                                int result = await DatabaseHelper_Mina2().createEstado(
                                  operacionId,
                                  newNumber,
                                  selectedState,
                                  selectedCodigo!,
                                  horaInicio,
                                  "",
                                );
                                
                                if (result > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Registro guardado correctamente."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  fetchEstados();
                                  Navigator.of(context).pop();
                                  
                                  Future.delayed(Duration.zero, () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            width: 700,
                                            height: 800,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 10.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.blue, width: 2),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: selectedState == "OPERATIVO" ? 
                                              RegistroPerforacionScreen(
                                                onDataInserted: fetchEstados,
                                                estadoId: result,
                                                estado: selectedState,
                                                operacionId: operacionId,
                                                tipoOperacion: widget.tipoOperacion,
                                              ) : 
                                              RegistroPerforacionScreenNoOperative(
                                                onDataInserted: fetchEstados,
                                                estadoId: result,
                                                estado: selectedState,
                                                operacionId: operacionId,
                                                tipoOperacion: widget.tipoOperacion,
                                              ),
                                          ),
                                        );
                                      },
                                    );
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error al guardar el registro."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Faltan datos por seleccionar."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEditing ? Colors.orange : Colors.green),
                          child: Text(isEditing ? "Actualizar" : "Crear"),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("(*) Los campos con asterisco son obligatorios.", 
                         style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  
  void fetchEstados() async {
    try {

      final dbHelper = DatabaseHelper_Mina2();
      List<Map<String, dynamic>> estados =
          await dbHelper.getEstadosByOperacionId(operacionId!);

      print("Datos obtenidos de la base de datos: $estados");

      List<Map<String, String>> allEstados = estados.map((estado) {
        return {
          'id': estado['id'].toString(),
          'numero': estado['numero']?.toString() ?? '',
          'estado': estado['estado']?.toString() ?? '',
          'codigo': estado['codigo']?.toString() ?? '',
          'hora_inicio': estado['hora_inicio']?.toString() ?? '',
          'hora_final': estado['hora_final']?.toString() ?? '',
        };
      }).toList();

      print("Estados convertidos: $allEstados");

      setState(() {
        currentData = allEstados;
      });
    } catch (e) {
      print("Error al obtener estados: $e");
    }
  }

Widget _buildCodigoTable() {
  return LayoutBuilder(
    builder: (context, constraints) {
      bool isSmallScreen = constraints.maxWidth < 600;

      Widget table = Table(
        border: TableBorder.all(color: Colors.black),
        columnWidths: const {
          0: FixedColumnWidth(40),   // N°
          1: FixedColumnWidth(100),  // Estado
          2: FixedColumnWidth(120),  // Código
          3: FixedColumnWidth(120),  // Sub Estados (nuevo)
          4: FixedColumnWidth(120),  // Hora Inicio
          5: FixedColumnWidth(100),  // Hora Fin
          // 6: FixedColumnWidth(100),  // Acciones
        },
        children: [
          // Cabecera
          TableRow(
            decoration: BoxDecoration(color: Colors.blue.shade200),
            children: [
              headerCell("N°", isSmallScreen: isSmallScreen),
              headerCell("Estado", isSmallScreen: isSmallScreen),
              headerCell("Código", isSmallScreen: isSmallScreen),
              // headerCell("Sub Estados", isSmallScreen: isSmallScreen), 
              headerCell("Hora Inicio", isSmallScreen: isSmallScreen),
              headerCell("Hora Fin", isSmallScreen: isSmallScreen),
              headerCell("Acciones", isSmallScreen: isSmallScreen),
            ],
          ),
          // Filas dinámicas
          for (var item in currentData)
            TableRow(
              children: [
                cellText(item["numero"] ?? "", isSmallScreen: isSmallScreen),
                cellText(item["estado"] ?? "", isSmallScreen: isSmallScreen),
                cellText(item["codigo"] ?? "", isSmallScreen: isSmallScreen),

                // ✅ Nueva columna con ícono condicional
//                 Center(
//   child: (item["estado"] == "MANTENIMIENTO")
//       ? IconButton(
//           icon: const Icon(Icons.add, color: Colors.blue),
//           onPressed: () {
//             showDialog(
//               context: context,
//               builder: (context) => SubEstadoDialog(
//                 codigo: item["codigo"] ?? "",
//                 turno: selectedTurno!,
//                 proceso: widget.tipoOperacion,
//                 idEstado: int.parse(item["id"] ?? "0"),
//               ),
//             );
//           },
//         )
//       : const SizedBox.shrink(),
// ),


                cellText(item["hora_inicio"] ?? "", isSmallScreen: isSmallScreen),
                cellText(item["hora_final"] ?? "", isSmallScreen: isSmallScreen),
                _buildActionIcons(context, item),
              ],
            ),
        ],
      );

      return isSmallScreen
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: table,
            )
          : table;
    },
  );
}

Widget _buildActionIcons(BuildContext context, Map<String, dynamic> item) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: Icon(Icons.play_arrow, color: Colors.green),
        onPressed: () {
          print("Ejecutando item con id: ${item["id"]}");

          // Verifica el estado y muestra el dialog correspondiente
          if (item["estado"] == "OPERATIVO") {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 700,
                    height: 800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RegistroPerforacionScreen(
                      onDataInserted: _refreshData,
                      estadoId: int.parse(item["id"].toString()),
                      estado: estado!,
                      tipoOperacion: widget.tipoOperacion,
                      operacionId: operacionId!,
                    ),
                  ),
                );
              },
            );
          } else {
            // Para estados no OPERATIVO, abre el otro dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 700,
                    height: 800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RegistroPerforacionScreenNoOperative(
                      onDataInserted: _refreshData,
                      estado: estado!,
                      estadoId: int.parse(item["id"].toString()),
                      tipoOperacion: widget.tipoOperacion,
                      operacionId: operacionId!,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      _buildDeleteIcon(context, item["id"]),
    ],
  );
}


Widget headerCell(String text, {bool isSmallScreen = false}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: isSmallScreen ? 12 : 14,
      ),
    ),
  );
}

Widget cellText(String text, {bool isSmallScreen = false}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: isSmallScreen ? 10 : 14,
      ),
    ),
  );
}

  Widget _buildDeleteIcon(BuildContext context, String? id,) {
    return IconButton(
      icon: Icon(Icons.delete, color : Colors.red),
      onPressed:() {
              if (id != null) {
                int estadoId = int.tryParse(id) ?? 0;
                if (estadoId > 0) {
                  List<int> idsAEliminar = [];
                  for (var item in currentData) {
                    int currentId = int.tryParse(item["id"] ?? "0") ?? 0;
                    if (currentId >= estadoId) {
                      idsAEliminar.add(currentId);
                    }
                  }
                  _confirmDelete(context, idsAEliminar);
                }
              }
            },
    );
  }
  void _confirmDelete(BuildContext context, List<int> idsAEliminar) {
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text(
              "¿Estás seguro de que quieres eliminar estos estados? Se eliminarán todos los registros posteriores al seleccionado."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final dbHelper = DatabaseHelper_Mina2();
                bool success = true;

                try {
                  // ✅ Buscar el estado anterior al que se va a eliminar
                  int estadoAEliminar = idsAEliminar.first;
                  int? estadoAnteriorId;

                  for (var item in currentData) {
                    int currentId = int.tryParse(item["id"] ?? "0") ?? 0;
                    if (currentId < estadoAEliminar) {
                      estadoAnteriorId = currentId;
                    }
                  }

                  // ✅ Si hay un estado anterior, actualizar su `hora_final` a vacío
                  if (estadoAnteriorId != null) {
                    await dbHelper.updateHoraFinal(estadoAnteriorId, "");
                    print(
                        "Se limpió la hora_final del estado con ID: $estadoAnteriorId");
                  }

                  // ✅ Eliminar los estados desde el seleccionado en adelante
                  for (int id in idsAEliminar) {
                    int result = await dbHelper.deleteEstado(id);
                    if (result == 0) {
                      success = false;
                    }
                  }

                  // ✅ Mostrar mensaje de éxito o error
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? "Estados eliminados correctamente"
                          : "Error al eliminar algunos estados"),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  fetchEstados(); // ✅ Actualizar la lista en la UI
                } catch (e) {
                  print("Error al eliminar estados: $e");

                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text("Error al eliminar los estados"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
