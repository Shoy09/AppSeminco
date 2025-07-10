import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper.dart';

class FormularioScreen extends StatefulWidget {
  final String estado;
  final String tipoOperacion; // 🔹 Parámetro recibido
  final int id;
  final int? idOperacion;
  final String nivel;
  final String labor;

  FormularioScreen(
      {required this.id,
      required this.idOperacion,
      required this.estado,
      required this.tipoOperacion,
      required this.nivel,
      required this.labor});

  @override
  _FormularioScreenState createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final DatabaseHelper_Mina1 dbHelper = DatabaseHelper_Mina1();
  List<Map<String, dynamic>> _editableData = [];
  List<String> estados = [];

  @override
  void initState() {
    print('🛠️ idOperacion recibido: ${widget.idOperacion}');
    print('🛠️ id: ${widget.id}');
    super.initState();
    _loadData();
    obtenerEstadosBD();
  }

  void obtenerEstadosBD() async {
    List<Map<String, dynamic>> estadosObtenidos =
        await DatabaseHelper_Mina1().getEstadosBDOPERATIVO(widget.tipoOperacion);

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
        await dbHelper.getInterPerforacionesTaladroLargo(widget.id);
    setState(() {
      _editableData = data;
    });
  }

  Future<void> _addNewRecord() async {
    TextEditingController nivelController =
        TextEditingController(text: widget.nivel);
    TextEditingController tajoController =
        TextEditingController(text: widget.labor);
    TextEditingController nbrocaController = TextEditingController();
    TextEditingController ntaladroController = TextEditingController();
    TextEditingController nbarrasController = TextEditingController();
    TextEditingController longitudPerforacionController =
        TextEditingController();
    TextEditingController anguloPerforacionController = TextEditingController();
    TextEditingController nfilasDeHastaController = TextEditingController();
    TextEditingController detallesTrabajoController = TextEditingController();

    String? selectedCodigoActividad;

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
                      Text("Agregar Nuevo Registro",
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
                              _buildTextField("Tajo", tajoController,
                                  readOnly: true),
                              _buildNumberField("N° Broca", nbrocaController),
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              _buildNumberField("N° Barras", nbarrasController),
                              _buildDecimalField("Longitud Perforación (m)",
                                  longitudPerforacionController),
                              _buildDecimalField("Ángulo Perforación (m)",
                                  anguloPerforacionController),
                              _buildDecimalField("N° Filas (De - Hasta)",
                                  nfilasDeHastaController),
                              _buildTextField("Detalles Trabajo Realizado",
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
                              List<String> missingFields = [];

                              if (selectedCodigoActividad == null ||
                                  selectedCodigoActividad!.isEmpty) {
                                missingFields.add("Código Actividad");
                              }
                              if (nbrocaController.text.isEmpty) {
                                missingFields.add("N° Broca");
                              }
                              if (ntaladroController.text.isEmpty) {
                                missingFields.add("N° Taladro");
                              }
                              if (nbarrasController.text.isEmpty) {
                                missingFields.add("N° Barras");
                              }
                              if (longitudPerforacionController.text.isEmpty) {
                                missingFields.add("Longitud Perforación");
                              }
                              if (anguloPerforacionController.text.isEmpty) {
                                missingFields.add("Ángulo Perforación");
                              }
                              if (nfilasDeHastaController.text.isEmpty) {
                                missingFields.add("N° Filas (De - Hasta)");
                              }
                              if (detallesTrabajoController.text.isEmpty) {
                                missingFields.add("Detalles Trabajo Realizado");
                              }

                              if (missingFields.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Faltan los siguientes campos: ${missingFields.join(', ')}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              await dbHelper.insertInterPerforacionTaladroLargo(
                                widget.id,
                                selectedCodigoActividad ?? "",
                                nivelController.text,
                                tajoController.text,
                                int.tryParse(nbrocaController.text) ?? 0,
                                int.tryParse(ntaladroController.text) ?? 0,
                                int.tryParse(nbarrasController.text) ?? 0,
                                double.tryParse(
                                        longitudPerforacionController.text) ??
                                    0.0,
                                double.tryParse(
                                        anguloPerforacionController.text) ??
                                    0.0,
                                nfilasDeHastaController.text,
                                detallesTrabajoController.text,
                              );

                              // 🔹 Actualiza el estado en Operacion a "parciales"
                              if (widget.idOperacion != null) {
                                await dbHelper.actualizarEstadoAParciales(
                                    widget.idOperacion!);
                              }

                              _loadData();
                              Navigator.of(context).pop();
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

  Future<void> _updateRecord(Map<String, dynamic> record) async {
    TextEditingController nivelController =
        TextEditingController(text: record['nivel']);
    TextEditingController tajoController =
        TextEditingController(text: record['tajo']);
    TextEditingController nbrocaController =
        TextEditingController(text: record['nbroca'].toString());
    TextEditingController ntaladroController =
        TextEditingController(text: record['ntaladro'].toString());
    TextEditingController nbarrasController =
        TextEditingController(text: record['nbarras'].toString());
    TextEditingController longitudPerforacionController =
        TextEditingController(text: record['longitud_perforacion'].toString());
    TextEditingController anguloPerforacionController =
        TextEditingController(text: record['angulo_perforacion'].toString());
    TextEditingController nfilasDeHastaController =
        TextEditingController(text: record['nfilas_de_hasta']);
    TextEditingController detallesTrabajoController =
        TextEditingController(text: record['detalles_trabajo_realizado']);

    String? selectedCodigoActividad = record['codigo_actividad'];

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
                      Text("Actualizar Registro",
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
                              _buildTextField("Tajo", tajoController,
                                  readOnly: true),
                              _buildNumberField("N° Broca", nbrocaController),
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              _buildNumberField("N° Barras", nbarrasController),
                              _buildDecimalField("Longitud Perforación (m)",
                                  longitudPerforacionController),
                              _buildDecimalField("Ángulo Perforación (m)",
                                  anguloPerforacionController),
                              _buildDecimalField("N° Filas (De - Hasta)",
                                  nfilasDeHastaController),
                              _buildTextField("Detalles Trabajo Realizado",
                                  detallesTrabajoController),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              List<String> missingFields = [];

                              if (selectedCodigoActividad == null ||
                                  selectedCodigoActividad!.trim().isEmpty) {
                                missingFields.add("Código Actividad");
                              }
                              if (nbrocaController.text.trim().isEmpty ||
                                  int.tryParse(nbrocaController.text) == null) {
                                missingFields.add(
                                    "N° Broca (Debe ser un número válido)");
                              }
                              if (ntaladroController.text.trim().isEmpty ||
                                  int.tryParse(ntaladroController.text) ==
                                      null) {
                                missingFields.add(
                                    "N° Taladro (Debe ser un número válido)");
                              }
                              if (nbarrasController.text.trim().isEmpty ||
                                  int.tryParse(nbarrasController.text) ==
                                      null) {
                                missingFields.add(
                                    "N° Barras (Debe ser un número válido)");
                              }
                              if (longitudPerforacionController.text
                                      .trim()
                                      .isEmpty ||
                                  double.tryParse(
                                          longitudPerforacionController.text) ==
                                      null) {
                                missingFields.add(
                                    "Longitud Perforación (Debe ser un número válido)");
                              }
                              if (anguloPerforacionController.text
                                      .trim()
                                      .isEmpty ||
                                  double.tryParse(
                                          anguloPerforacionController.text) ==
                                      null) {
                                missingFields.add(
                                    "Ángulo Perforación (Debe ser un número válido)");
                              }
                              if (nfilasDeHastaController.text.trim().isEmpty) {
                                missingFields.add("N° Filas (De - Hasta)");
                              }
                              if (detallesTrabajoController.text
                                  .trim()
                                  .isEmpty) {
                                missingFields.add("Detalles Trabajo Realizado");
                              }

                              if (missingFields.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Faltan los siguientes campos:\n- ${missingFields.join('\n- ')}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              await dbHelper.updateInterPerforacionTaladroLargo(
                                record['id'], // ID del registro a actualizar
                                {
                                  "codigo_actividad":
                                      selectedCodigoActividad ?? "",
                                  "nivel": nivelController.text,
                                  "tajo": tajoController.text,
                                  "nbroca":
                                      int.tryParse(nbrocaController.text) ??
                                          0, // Sin guion bajo
                                  "ntaladro":
                                      int.tryParse(ntaladroController.text) ??
                                          0,
                                  "nbarras":
                                      int.tryParse(nbarrasController.text) ?? 0,
                                  "longitud_perforacion": double.tryParse(
                                          longitudPerforacionController.text) ??
                                      0.0,
                                  "angulo_perforacion": double.tryParse(
                                          anguloPerforacionController.text) ??
                                      0.0,
                                  "nfilas_de_hasta":
                                      nfilasDeHastaController.text,
                                  "detalles_trabajo_realizado":
                                      detallesTrabajoController
                                          .text, // Nombre corregido
                                },
                              );

                              _loadData(); // Recargar los datos actualizados
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
          .deleteInterPerforacionTaladroLargo(recordId); // Eliminar en BD

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
        readOnly: readOnly, // Bloquear edición si es necesario
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

  Future<void> _saveData() async {
    for (var row in _editableData) {
      await dbHelper.updateInterPerforacionTaladroLargo(row['id'], row);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Datos guardados exitosamente")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tabla de taladro largo"),
        backgroundColor: Color(0xFF21899C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical, // Permite scroll vertical
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.grey),
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.blue[200]!),
                    columns: [
                      DataColumn(
                          label: Text('N°',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Código\nde actividad',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Nivel',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Tajo',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('N°Broca',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('N° Taladro',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('N° Barras',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Longitud de\nperforación (m)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Angulo de\nperforación (m)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('N° de Filas\n(De - Hasta)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Detalles Trabajo realizado',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Acciones',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _editableData.isNotEmpty
                        ? _editableData.asMap().entries.map((entry) {
                            int index = entry.key + 1; // Enumerar desde 1
                            Map<String, dynamic> row = entry.value;
                            return DataRow(cells: [
                              DataCell(
                                  Text(index.toString())), // Número de fila
                              _editableCell(row, 'codigo_actividad'),
                              _editableCell(row, 'nivel'),
                              _editableCell(row, 'tajo'),
                              _editableCell(row, 'nbroca'),
                              _editableCell(row, 'ntaladro'),
                              _editableCell(row, 'nbarras'),
                              _editableCell(row, 'longitud_perforacion'),
                              _editableCell(row, 'angulo_perforacion'),
                              _editableCell(row, 'nfilas_de_hasta'),
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
                                            _updateRecord(row);
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
                                12,
                                (index) => DataCell(Text('-')),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
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
