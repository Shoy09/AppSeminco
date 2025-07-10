import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_seminco/mina%201/models/Empresa.dart';
import 'package:app_seminco/mina%201/models/Equipo.dart';
import 'package:app_seminco/mina%201/screens/Estados/estado_perforacion_screen.dart';
import 'package:app_seminco/mina%201/screens/horizontal/FormularioPerforacionScreen.dart';
import 'package:app_seminco/mina%201/screens/horizontal/registro_perforacion_sreen.dart';
import '../../../database/database_helper.dart';

class ListaPerforacionHorizontalScreen extends StatefulWidget {
  final String tipoOperacion; // 🔹 Parámetro recibido
  final String? rolUsuario;

  const ListaPerforacionHorizontalScreen(
      {Key? key, required this.tipoOperacion, this.rolUsuario})
      : super(key: key);

  @override
  _ListaPerforacionScreenState createState() => _ListaPerforacionScreenState();
}

class _ListaPerforacionScreenState
    extends State<ListaPerforacionHorizontalScreen> {
  String? selectedTurno;
  String? selectedEquipo;
  String? selectedCodigo;
  int? operacionId;
  String? estado;
  String? selectedEmpresa;
  String fechaActual = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool showCreateButton = true; // Controlamos si mostrar el botón "Crear"
  bool foundData = false;

  List<String> turnos = ['DÍA', 'NOCHE'];
  List<String> equipos = [];
  List<String> empresas = [];
  List<String> codigosFiltrados = [];

  Future<List<Map<String, dynamic>>> _getPerforacionData() async {
    // Verificar si operacionId está disponible
    if (operacionId != null) {
      DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
      // Llamar a getPerforacionesAgrupadas y pasar el operacionId como parámetro
      List<Map<String, dynamic>> data =
          await dbHelper.getPerforacionesTaladroHorizontal(operacionId!);

      // Imprimir los datos recibidos para depurar
      print('Datos recibidos en _getPerforacionData: $data');

      return data;
    } else {
      // Si operacionId es nulo, manejar el caso (quizás lanzar un error o retornar un conjunto vacío)
      // Usamos un post-frame callback para asegurarnos de que la construcción haya terminado antes de mostrar el SnackBar
      WidgetsBinding.instance.addPostFrameCallback((_) {});

      return []; // Retornamos una lista vacía en lugar de lanzar una excepción
    }
  }

  @override
  void initState() {
    super.initState();
    _getEmpresas();
    _getEquipos(widget.tipoOperacion);
    // Determinamos el turno automáticamente al iniciar
    selectedTurno = _getTurnoBasedOnTime();
    _fetchOperacionData(); // Hacemos la consulta
    print(
        "Tipo de operación recibida: ${widget.tipoOperacion}"); // ✅ Verifica que se reciba correctamente
  }

  Future<void> _getEmpresas() async {
    try {
      final dbHelper = DatabaseHelper_Mina1();
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
      final dbHelper = DatabaseHelper_Mina1();
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

  void mostrarDialogoCerrarRegistro(
    BuildContext context,
    int? operacionId,
    String turno, {
    required VoidCallback onRegistroCerrado, // Nuevo parámetro callback
  }) async {
    DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();

    List<Map<String, dynamic>> estados =
        await dbHelper.getEstadosByOperacionId(operacionId!);

    if (estados.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("No se puede cerrar"),
            content: Text(
                "No puedes cerrar este registro porque no hay estados asociados."),
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
                // 1. Verifica y actualiza la hora_final si es necesario
                if (ultimoEstado['hora_final'] == null ||
                    ultimoEstado['hora_final'].toString().isEmpty) {
                  String horaFinal = (turno == 'DÍA') ? '19:00' : '07:00';
                  await dbHelper.actualizarHoraFinal(
                      ultimoEstado['id'], horaFinal);
                }

                // 2. Luego cierra la operación
                await dbHelper.cerrarOperacion(operacionId!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Registro cerrado exitosamente"),
                    backgroundColor: Colors.green,
                  ),
                );
                // 3. Recargar la pantalla completa
                // 3. Limpiar completamente los datos y recargar
                if (mounted) {
                  setState(() {
                    // Limpiar todos los seleccionados
                    selectedTurno =
                        _getTurnoBasedOnTime(); // Mantener el turno automático
                    selectedEquipo = null;
                    selectedCodigo = null;
                    selectedEmpresa = null;
                    operacionId = null;
                    estado = null;
                    foundData = false;
                    showCreateButton = true;
                    codigosFiltrados = []; // Limpiar códigos filtrados
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

  void _filtrarCodigosPorEquipo(String equipoNombre) {
    final dbHelper = DatabaseHelper_Mina1();

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
      DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
      List<Map<String, dynamic>> data;

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
          selectedCodigo = data[0]['codigo'];
          codigosFiltrados = [data[0]['codigo']];
          selectedEmpresa = data[0]['empresa'];
          operacionId = data[0]['id'];
          estado = data[0]['estado'];
          showCreateButton = false;
          foundData = true;
        });
      } else {
        setState(() {
          operacionId =
              null; // Asegurar que se establezca a null cuando no hay datos
          selectedEquipo = null;
          selectedCodigo = null;
          selectedEmpresa = null;
          estado = null;
          foundData = false;
          showCreateButton = true;
          codigosFiltrados = [];
        });
      }
    }
  }

void showHorometroDialog(BuildContext context, int operacionId, String estado) async {
  DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
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
                        if (horometros[i]["final"] < horometros[i]["inicial"]) {
                          errores.add(i);
                        }
                      }

                      if (errores.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error en filas: ${errores.map((i) => i + 1).join(", ")}"),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

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
                  ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Operación: ${widget.tipoOperacion}'),
        backgroundColor: Color(0xFF21899C),
      ),
      body: Column(
        children: [
          // Card añadida arriba del botón
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
                    _buildDropdown("Código", codigosFiltrados, selectedCodigo,
                        (value) {
                      setState(() {
                        selectedCodigo = value;
                      });
                    }),
                    _buildDropdown("Empresa", empresas, selectedEmpresa,
                        (value) {
                      setState(() {
                        selectedEmpresa = value;
                      });
                    }),
                    _buildReadOnlyField("Fecha", fechaActual),

                    SizedBox(height: 20), // Un poco de espacio antes del botón

                    // Botón "Crear" solo si no hemos encontrado datos
                    if (showCreateButton)
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Verificar si hay algún valor no seleccionado
                            if (selectedTurno == null ||
                                selectedEquipo == null ||
                                selectedCodigo == null ||
                                selectedEmpresa == null) {
                              // Si falta algún valor, mostrar un mensaje de advertencia
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Por favor, selecciona todos los campos antes de crear la operación.'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              return; // Detenemos la ejecución si falta algún dato
                            }

                            // Si todos los valores están seleccionados, continuamos con la inserción
                            String turno =
                                selectedTurno!; // No es necesario poner valor predeterminado, ya que ya hemos verificado que no es null
                            String equipo =
                                selectedEquipo!; // Lo mismo para equipo
                            String codigo = selectedCodigo!;
                            String empresa =
                                selectedEmpresa!; // Lo mismo para empresa
                            String fecha = fechaActual; // La fecha actual

                            String tipoOperacion = widget.tipoOperacion;

                            // Llamamos a la función para insertar la operación
                            int id = await DatabaseHelper_Mina1().insertOperacion(
                                turno,
                                equipo,
                                codigo,
                                empresa,
                                fecha,
                                tipoOperacion);

                            if (id > 0) {
                              // Si la operación fue creada correctamente, puedes mostrar un mensaje de éxito
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Operación creada con éxito'),
                                  backgroundColor: Colors
                                      .green, // Cambia el color de fondo a verde
                                ),
                              );
                              await _fetchOperacionData();
                            } else {
                              // Si ocurrió un error, muestra un mensaje de error
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (estado == "cerrado")
                      ? null
                      : () {
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
                                    border: Border.all(
                                        color: Colors.blue, width: 2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: RegistroPerforacionScreen(
                                      onDataInserted:
                                          _refreshData, // Pasa el callback para refrescar los datos
                                      operacionId:
                                          operacionId, // Pasar operacionId
                                      tipoOperacion: widget.tipoOperacion),
                                ),
                              );
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (estado == "cerrado") ? Colors.grey : Color(0xFF21899C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text(
    "Ingresar registro",
    style: TextStyle(color: Colors.white), // Siempre en blanco
  ),
                ),
              ],
            ),
          ),

          // Tabla con scroll y mejoras visuales
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: SingleChildScrollView(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getPerforacionData(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                print(
                                    'Error al cargar datos: ${snapshot.error}');
                                return Center(
                                    child: Text('Error al cargar datos.'));
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text('No hay datos disponibles.'));
                              } else {
                                return DataTable(
                                  headingRowColor:
                                      MaterialStateProperty.resolveWith(
                                    (states) => Colors.blue.shade200,
                                  ),
                                  columnSpacing: 16,
                                  horizontalMargin: 16,
                                  dataRowHeight: 60,
                                  border: TableBorder(
                                    horizontalInside:
                                        BorderSide(color: Colors.grey.shade300),
                                    verticalInside:
                                        BorderSide(color: Colors.grey.shade300),
                                    top:
                                        BorderSide(color: Colors.grey.shade400),
                                    bottom:
                                        BorderSide(color: Colors.grey.shade400),
                                    left:
                                        BorderSide(color: Colors.grey.shade400),
                                    right:
                                        BorderSide(color: Colors.grey.shade400),
                                  ),
                                  columns: _buildColumns(),
                                  rows: _buildDataRows(snapshot.data!),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Botón fijo en la parte inferior
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
                      builder: (context) => EstadoRegistroPerforacionScreen(
                          turno: selectedTurno!,
                          operacionId: operacionId!,
                          tipoOperacion: widget.tipoOperacion,
                          estado: estado!),
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
              child: Text("Estados", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                if (operacionId != null) {
                  showHorometroDialog(context, operacionId!,
                      estado!); // 🔹 Pasar el estado al diálogo
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
              child: Text("Horómetro", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
  onPressed: estado == 'cerrado'
      ? null // 🔹 Deshabilita el botón si el estado es "cerrado"
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
    backgroundColor: estado == 'cerrado' ? Colors.grey : Color(0xFF21899C), // 🔹 Cambia el color si está deshabilitado
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

// _buildDropdown: método para crear los Dropdowns
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

  List<DataColumn> _buildColumns() {
    final columnNames = [
      'N°',
      'ZONA',
      'TIPO LABOR',
      'LABOR',
      'ALA',
      'VETA',
      'NIVEL',
      'TIPO PERFORACION',
      'ACCIONES'
    ];

    return columnNames
        .map((name) => DataColumn(
              label: Container(
                width: name == 'ACCIONES' ? 100 : 120,
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ))
        .toList();
  }

  List<DataRow> _buildDataRows(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final id = item['id']; // ID del registro

      return DataRow(
        cells: [
          DataCell(
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormularioScreen(
                      estado: estado!,
                      idOperacion: operacionId,
                      tipoOperacion: widget.tipoOperacion,
                      zona: item['zona'] ?? 'N/A',
                      tipo_labor: item['tipo_labor'] ?? 'N/A',
                      labor: item['labor'] ?? 'N/A',
                      veta: item['veta'] ?? 'N/A',
                      nivel: item['nivel'] ?? 'N/A',
                      id: id,
                    ),
                  ),
                );
              },
              child: Text((index + 1).toString()),
            ),
          ),
          _buildInteractiveDataCell(item['zona'] ?? 'N/A', id, item),
          _buildInteractiveDataCell(item['tipo_labor'] ?? 'N/A', id, item),
          _buildInteractiveDataCell(item['labor'] ?? 'N/A', id, item),
          _buildInteractiveDataCell(item['ala'] ?? 'Ninguna', id, item),
          _buildInteractiveDataCell(item['veta'] ?? 'N/A', id, item),
          _buildInteractiveDataCell(item['nivel'] ?? 'N/A', id, item),
          _buildInteractiveDataCell(
              item['tipo_perforacion'] ?? 'N/A', id, item),
          DataCell(
            Container(
              width: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/icon/ejecutado.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormularioScreen(
                            estado: estado!,
                            idOperacion: operacionId,
                            tipoOperacion: widget.tipoOperacion,
                            id: id,
                            zona: item['zona'] ?? 'N/A',
                      tipo_labor: item['tipo_labor'] ?? 'N/A',
                      labor: item['labor'] ?? 'N/A',
                      veta: item['veta'] ?? 'N/A',
                      nivel: item['nivel'] ?? 'N/A',
                          ),
                        ),
                      );
                    },
                    constraints: BoxConstraints(maxWidth: 40),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {},
                    constraints: BoxConstraints(maxWidth: 40),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title:
                                Text('¿Está seguro de eliminar el registro?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: Text('Sí'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        final dbHelper = DatabaseHelper_Mina1();
                        final result = await dbHelper.delete(
                            'PerforacionTaladroLargo', id);

                        if (result > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Registro eliminado correctamente.')),
                          );
                          _refreshData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('No se pudo eliminar el registro.')),
                          );
                        }
                      }
                    },
                    constraints: BoxConstraints(maxWidth: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

// Función para hacer que cada celda sea interactiva
  DataCell _buildInteractiveDataCell(
      String text, int id, Map<String, dynamic> item) {
    return DataCell(
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioScreen(
                estado: estado!,
                tipoOperacion: widget.tipoOperacion,
                zona: item['zona'] ?? 'N/A',
                idOperacion: operacionId,
                      tipo_labor: item['tipo_labor'] ?? 'N/A',
                      labor: item['labor'] ?? 'N/A',
                      veta: item['veta'] ?? 'N/A',
                      nivel: item['nivel'] ?? 'N/A',
                id: id, // Solo pasamos el ID
              ),
            ),
          );
        },
        child: Container(
          width: 120,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
