import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper.dart';

class FormularioScreen extends StatefulWidget {
  final String estado;
  final String tipoOperacion; // 🔹 Parámetro recibido
  final int id;
  final int? idOperacion;
  final String zona;
  final String tipo_labor;
  final String labor;
  final String veta;
  final String nivel;
  

  FormularioScreen(
      {required this.id,
      required this.tipoOperacion,
      required this.estado,
      required this.idOperacion,
      required this.zona,
      required this.tipo_labor,
      required this.labor,
      required this.veta,
      required this.nivel
      });

  @override
  _FormularioScreenState createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _editableData = [];
  List<String> estados = [];
  String? area;

  @override
  void initState() {
    super.initState();
    _loadData();
    obtenerEstadosBD();
    obtenerPlanMensual();
  }

  void obtenerEstadosBD() async {
    List<Map<String, dynamic>> estadosObtenidos =
        await DatabaseHelper().getEstadosBDOPERATIVO(widget.tipoOperacion);

    print(
        "Estados obtenidos de la BD para proceso '${widget.tipoOperacion}' (solo OPERATIVO): $estadosObtenidos");

    // Usamos un conjunto (Set) para evitar duplicados
    Set<String> estadosUnicos = {};

    // Agregar los estados con formato "codigo - tipo_estado"
    for (var estado in estadosObtenidos) {
      String estadoFormato =
          "${estado['codigo']} - ${estado['tipo_estado']}"; // Concatenar código y estado
      estadosUnicos.add(estadoFormato); // Agregar al set
    }

    setState(() {
      estados = estadosUnicos.toList(); // Convertimos el set a lista
    });
  }

  void _loadData() async {
    List<Map<String, dynamic>> data =
        await dbHelper.getInterPerforacionesHorizontal(widget.id);
    setState(() {
      _editableData = data;
    });
  }

void obtenerPlanMensual() async {
  String zona = widget.zona;
  String tipoLabor = widget.tipo_labor;
  String labor = widget.labor;
  String estructuraVeta = widget.veta;
  String nivel = widget.nivel;

  var resultado = await dbHelper.getPlanMensual(
    zona: zona,
    tipoLabor: tipoLabor,
    labor: labor,
    estructuraVeta: estructuraVeta,
    nivel: nivel,
  );

  if (resultado != null) {
    double ancho = resultado['ancho_m'];
    double alto = resultado['alto_m'];
    area = '${ancho.toStringAsFixed(2)}m x ${alto.toStringAsFixed(2)}m';  // Formateamos como texto
    print("Dimensión: $area");
    setState(() {});  // Refrescar UI si es necesario
  } else {
    print("No se encontró ningún registro.");
  }
}

  Future<void> _addNewRecord() async {
    TextEditingController nivelController =
        TextEditingController(text: widget.nivel);
    TextEditingController laborController =
        TextEditingController(text: widget.labor);
TextEditingController seccionLaborController = TextEditingController(text: area);
    TextEditingController nbrocaController = TextEditingController();
    TextEditingController ntaladroController = TextEditingController();
    TextEditingController ntaladrosRimadosController = TextEditingController();
    TextEditingController longitudPerforacionController =
        TextEditingController();
    TextEditingController detallesTrabajoController = TextEditingController();
    String? selectedCodigoActividad;

    List<String> errores = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Para actualizar la UI si hay errores
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Agregar Nuevo Registro",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (errores.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: errores
                                .map((error) => Text(
                                      error,
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ))
                                .toList(),
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDropdownField(
                                "Código Actividad",
                                estados,
                                selectedCodigoActividad,
                                (String? newValue) {
                                  setState(() {
                                    selectedCodigoActividad =
                                        newValue?.split(" - ")[0];
                                  });
                                },
                              ),
                              _buildNumberField("Nivel", nivelController,
                                  readOnly: true),
                              _buildTextField("Labor", laborController,
                                  readOnly: true),
                              _buildNumberField("Sección de la Labor (a x b)",
                                  seccionLaborController, readOnly: true),
                              _buildNumberField("N° Broca", nbrocaController),
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              _buildNumberField("N° Taladros Rimados",
                                  ntaladrosRimadosController),
                              _buildDecimalField("Longitud Perforación (m)",
                                  longitudPerforacionController),
                              _buildTextField("Detalles del Trabajo Realizado",
                                  detallesTrabajoController),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                errores.clear();
                                if (selectedCodigoActividad == null ||
                                    selectedCodigoActividad!.isEmpty) {
                                  errores
                                      .add("Código de Actividad es requerido.");
                                }
                                if (seccionLaborController.text.isEmpty) {
                                  errores
                                      .add("Sección de la Labor es requerida.");
                                }
                                if (nbrocaController.text.isEmpty) {
                                  errores.add("N° Broca es requerido.");
                                }
                                if (ntaladroController.text.isEmpty) {
                                  errores.add("N° Taladro es requerido.");
                                }
                                if (ntaladrosRimadosController.text.isEmpty) {
                                  errores
                                      .add("N° Taladros Rimados es requerido.");
                                }
                                if (longitudPerforacionController
                                    .text.isEmpty) {
                                  errores.add(
                                      "Longitud de Perforación es requerida.");
                                }
                                if (detallesTrabajoController.text.isEmpty) {
                                  errores.add(
                                      "Detalles del Trabajo son requeridos.");
                                }
                              });

                              if (errores.isEmpty) {
                                await dbHelper.insertInterPerforacionHorizontal(
                                  widget.id,
                                  selectedCodigoActividad ?? "",
                                  nivelController.text,
                                  laborController.text,
                                  seccionLaborController.text,
                                  int.tryParse(nbrocaController.text) ?? 0,
                                  int.tryParse(ntaladroController.text) ?? 0,
                                  int.tryParse(
                                          ntaladrosRimadosController.text) ??
                                      0,
                                  double.tryParse(
                                          longitudPerforacionController.text) ??
                                      0.0,
                                  detallesTrabajoController.text,
                                );

                              if (widget.idOperacion != null) {
                                await dbHelper.actualizarEstadoAParciales(
                                    widget.idOperacion!);
                              }

                                _loadData();
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text("Guardar"),
                          ),
                        ],
                      ),
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

  Future<void> _editRecord(Map<String, dynamic> record) async {
    TextEditingController nivelController =
        TextEditingController(text: record['nivel']);
    TextEditingController laborController =
        TextEditingController(text: record['labor']);
    TextEditingController seccionLaborController =
        TextEditingController(text: record['seccion_la_labor']);
    TextEditingController nbrocaController =
        TextEditingController(text: record['nbroca'].toString());
    TextEditingController ntaladroController =
        TextEditingController(text: record['ntaladro'].toString());
    TextEditingController ntaladrosRimadosController =
        TextEditingController(text: record['ntaladros_rimados'].toString());
    TextEditingController longitudPerforacionController =
        TextEditingController(text: record['longitud_perforacion'].toString());
    TextEditingController detallesTrabajoController =
        TextEditingController(text: record['detalles_trabajo_realizado']);

    String? selectedCodigoActividad = record['codigo_actividad'];
    List<String> errores = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Editar Registro",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDropdownField(
                                "Código Actividad",
                                estados,
                                selectedCodigoActividad,
                                (String? newValue) {
                                  setState(() {
                                    selectedCodigoActividad =
                                        newValue?.split(" - ")[0];
                                  });
                                },
                              ),
                              _buildNumberField("Nivel", nivelController,
                                  readOnly: true),
                              _buildTextField("Labor", laborController,
                                  readOnly: true),
                              _buildNumberField("Sección de la Labor (a x b)",
                                  seccionLaborController, readOnly: true),
                              _buildNumberField("N° Broca", nbrocaController),
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              _buildNumberField("N° Taladros Rimados",
                                  ntaladrosRimadosController),
                              _buildDecimalField("Longitud Perforación (m)",
                                  longitudPerforacionController),
                              _buildTextField("Detalles del Trabajo Realizado",
                                  detallesTrabajoController),
                              if (errores.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    children: errores
                                        .map((error) => Text(
                                              error,
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              errores.clear();

                              // Validación de campos obligatorios
                              if (selectedCodigoActividad == null ||
                                  selectedCodigoActividad!.isEmpty)
                                errores
                                    .add("Seleccione un Código de Actividad.");
                              if (nivelController.text.isEmpty)
                                errores.add("El campo 'Nivel' es obligatorio.");
                              if (laborController.text.isEmpty)
                                errores.add("El campo 'Labor' es obligatorio.");
                              if (seccionLaborController.text.isEmpty)
                                errores.add(
                                    "El campo 'Sección de la Labor' es obligatorio.");
                              if (nbrocaController.text.isEmpty)
                                errores
                                    .add("El campo 'N° Broca' es obligatorio.");
                              if (ntaladroController.text.isEmpty)
                                errores.add(
                                    "El campo 'N° Taladro' es obligatorio.");
                              if (ntaladrosRimadosController.text.isEmpty)
                                errores.add(
                                    "El campo 'N° Taladros Rimados' es obligatorio.");
                              if (longitudPerforacionController.text.isEmpty)
                                errores.add(
                                    "El campo 'Longitud de Perforación' es obligatorio.");
                              if (detallesTrabajoController.text.isEmpty)
                                errores.add(
                                    "El campo 'Detalles del Trabajo Realizado' es obligatorio.");

                              // Si hay errores, actualiza la UI y detiene la ejecución
                              if (errores.isNotEmpty) {
                                setState(() {});
                                return;
                              }

                              // Si no hay errores, procede a actualizar
                              await dbHelper.updateInterPerforacionHorizontal(
                                record['id'],
                                {
                                  "codigo_actividad":
                                      selectedCodigoActividad ?? "",
                                  "nivel": nivelController.text,
                                  "labor": laborController.text,
                                  "seccion_la_labor":
                                      seccionLaborController.text,
                                  "nbroca":
                                      int.tryParse(nbrocaController.text) ?? 0,
                                  "ntaladro":
                                      int.tryParse(ntaladroController.text) ??
                                          0,
                                  "ntaladros_rimados": int.tryParse(
                                          ntaladrosRimadosController.text) ??
                                      0,
                                  "longitud_perforacion": double.tryParse(
                                          longitudPerforacionController.text) ??
                                      0.0,
                                  "detalles_trabajo_realizado":
                                      detallesTrabajoController.text,
                                },
                              );
                              _loadData();
                              Navigator.of(context).pop();
                            },
                            child: Text("Actualizar"),
                          ),
                        ],
                      ),
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

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: selectedValue != null && items.contains(selectedValue)
          ? selectedValue
          : null,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item, // Mantener "codigo - tipo_estado" en la lista
          child: Text(item), // Mostrar "codigo - tipo_estado"
        );
      }).toList(),
      onChanged: (String? newValue) {
        onChanged(newValue); // Extrae el código en `_addNewRecord`
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDecimalField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int recordId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text(
              "¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(); // Cerrar el diálogo sin eliminar
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
                _deleteRecord(recordId); // Llamar a la función de eliminación
              },
              child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRecord(int recordId) async {
    try {
      await dbHelper
          .deleteInterPerforacionHorizontal(recordId); // Eliminar en BD

      _loadData(); // Recargar la lista desde la base de datos

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registro eliminado"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error al eliminar el registro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Tabla de taladro horizontal"),
          backgroundColor: Color(0xFF21899C)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey),
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.blue[200]!),
                    columns: [
                      DataColumn(
                          label: SizedBox(
                              width: 50,
                              child: Text('N°',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text('Código\nde actividad',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                      DataColumn(
                          label: SizedBox(
                              width: 60,
                              child: Text('Nivel',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center))),
                      DataColumn(
                          label: SizedBox(
                              width: 80,
                              child: Text('Labor',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center))),
                      DataColumn(
                          label: SizedBox(
                              width: 120,
                              child: Text('Sección de\nla labor (a x b)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                      DataColumn(
                          label: SizedBox(
                              width: 80,
                              child: Text('N° Broca',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center))),
                      DataColumn(
                          label: SizedBox(
                              width: 80,
                              child: Text('N° Taladro',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text('N° Taladros\nRimados',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                      DataColumn(
                          label: SizedBox(
                              width: 120,
                              child: Text('Longitud de\nperforación (m)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                      DataColumn(
                          label: SizedBox(
                              width: 150,
                              child: Text('Detalles del\nTrabajo realizado',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text('Acciones',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2))),
                    ],
                    rows: _editableData.isNotEmpty
                        ? _editableData.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            Map<String, dynamic> row = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(index.toString())),
                              _editableCell(row, 'codigo_actividad'),
                              _editableCell(row, 'nivel'),
                              _editableCell(row, 'labor'),
                              _editableCell(row, 'seccion_la_labor'),
                              _editableCell(row, 'nbroca'),
                              _editableCell(row, 'ntaladro'),
                              _editableCell(row, 'ntaladros_rimados'),
                              _editableCell(row, 'longitud_perforacion'),
                              _editableCell(row, 'detalles_trabajo_realizado'),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: widget.estado == 'cerrado'
                                            ? Colors.grey
                                            : Colors.blue),
                                    onPressed: widget.estado == 'cerrado'
                                        ? null
                                        : () {
                                            _editRecord(row);
                                          },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: widget.estado == 'cerrado'
                                            ? Colors.grey
                                            : Colors.red),
                                    onPressed: widget.estado == 'cerrado'
                                        ? null
                                        : () {
                                            if (row.containsKey('id')) {
                                              int recordId = row[
                                                  'id']; // Obtener ID del registro
                                              _confirmDelete(context, recordId);
                                            } else {
                                              print(
                                                  "Error: La fila no contiene un ID válido.");
                                            }
                                          },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList()
                        : [
                            DataRow(
                              cells: List.generate(
                                11,
                                (index) => DataCell(Text('-')),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: widget.estado == "cerrado" ? null : _addNewRecord,
  child: Icon(Icons.add),
  backgroundColor: widget.estado == "cerrado" ? Colors.grey : Colors.blue,
),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  DataCell _editableCell(Map<String, dynamic> row, String column) {
    String value = row[column] != null && row[column] != 0.0
        ? row[column].toString()
        : ''; // Oculta valores 0.0

    return DataCell(Text(value)); // Solo texto, sin TextFormField
  }
}
