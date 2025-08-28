import 'package:app_seminco/components/showPdfDialog_mina2.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class FormularioScreen extends StatefulWidget {
  final String estado;
  final String tipoOperacion; // 🔹 Parámetro recibido
  final int id;
  final String zona;
  final String tipo_labor;
  final String labor;
  final String nivel;
  final int operacionId;
  final String ala;

  FormularioScreen(
      {required this.id,
      required this.tipoOperacion,
      required this.estado,
      required this.operacionId,
      required this.zona,
      required this.tipo_labor,
            required this.ala,
      required this.labor,
      required this.nivel
      });

  @override
  _FormularioScreenState createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> _editableData = [];
  List<String> estados = [];
  String? area;

  @override
  void initState() {
    super.initState();
    _loadData();
    obtenerPlanMensual();
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
  String nivel = widget.nivel;

  var resultado = await dbHelper.getPlanMensualHori(
    zona: zona,
    tipoLabor: tipoLabor,
    labor: labor,
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
    TextEditingController ntaladroController = TextEditingController();
    TextEditingController ntaladrosRimadosController = TextEditingController();
    TextEditingController longitudPerforacionController =
        TextEditingController();
    TextEditingController metrosPerforadosController = TextEditingController(); // Nuevo controlador
    TextEditingController detallesTrabajoController = TextEditingController();
    // Lista de materiales disponibles (ejemplos)
    List<String> materiales = ['Desmonte', 'Mineral'];
    String? materialSeleccionado;
    List<String> errores = [];

    // Función para calcular metros perforados
    // Función para calcular metros perforados con la nueva fórmula
void calcularMetrosPerforados() {
  if (ntaladroController.text.isNotEmpty && 
      ntaladrosRimadosController.text.isNotEmpty &&
      longitudPerforacionController.text.isNotEmpty) {
    double ntaladros = double.tryParse(ntaladroController.text) ?? 0;
    double ntaladrosRimados = double.tryParse(ntaladrosRimadosController.text) ?? 0;
    double longitudPies = double.tryParse(longitudPerforacionController.text) ?? 0;
    
    // Nueva fórmula: (taladros normales + taladros rimados) * pies * 0.3048
    double metros = (ntaladros + ntaladrosRimados) * longitudPies * 0.3048;
    metrosPerforadosController.text = metros.toStringAsFixed(2);
  } else {
    metrosPerforadosController.text = '';
  }
}

    // Listeners para calcular automáticamente
    ntaladroController.addListener(calcularMetrosPerforados);
    ntaladrosRimadosController.addListener(calcularMetrosPerforados);
    longitudPerforacionController.addListener(calcularMetrosPerforados);

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
                              _buildNumberField("Nivel", nivelController,
                                  readOnly: true),
                              _buildTextField("Labor", laborController,
                                  readOnly: true),
                              
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "Material utilizado",
                                    border: OutlineInputBorder(),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: materialSeleccionado,
                                      isDense: true,
                                      isExpanded: true,
                                      hint: Text("Seleccione un material"),
                                      items: materiales.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          materialSeleccionado = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildNumberField("N° Taladros Rimados",
                                  ntaladrosRimadosController),
                              _buildDecimalField("Longitud De Perforación (pies)",
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
                                
                                if (ntaladroController.text.isEmpty) {
                                  errores.add("N° Taladro es requerido.");
                                }
                                if (ntaladrosRimadosController.text.isEmpty) {
                                  errores
                                      .add("N° Taladros Rimados es requerido.");
                                }
                                if (materialSeleccionado == null) {
                                  errores.add("Material es requerido.");
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
                                  nivelController.text,
                                  laborController.text,
                                  int.tryParse(ntaladroController.text) ?? 0,
                                  int.tryParse(
                                          ntaladrosRimadosController.text) ??
                                      0,
                                  double.tryParse(
                                          longitudPerforacionController.text) ??
                                      0.0,
                                  double.tryParse(metrosPerforadosController.text) ?? 0.0, // Guardar metros perforados
                                  detallesTrabajoController.text,
                                  materialSeleccionado!,
                                );

                                if (widget.operacionId != null) {
                                  await dbHelper.actualizarEstadoAParciales(
                                      widget.operacionId!);
                                }

                                _loadData();
                                Navigator.of(context).pop(); // Cierra el diálogo
                                Navigator.of(context).pop(); // Cierra FormularioScreen
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

    // Limpiar los listeners cuando se cierre el diálogo
    ntaladrosRimadosController.removeListener(calcularMetrosPerforados);
    longitudPerforacionController.removeListener(calcularMetrosPerforados);
  }

Future<void> _editRecord(Map<String, dynamic> record) async {
    TextEditingController nivelController =
        TextEditingController(text: record['nivel']);
    TextEditingController laborController =
        TextEditingController(text: record['labor']);

    TextEditingController ntaladroController =
        TextEditingController(text: record['ntaladro'].toString());
    TextEditingController ntaladrosRimadosController =
        TextEditingController(text: record['ntaladros_rimados'].toString());
    TextEditingController longitudPerforacionController =
        TextEditingController(text: record['longitud_perforacion'].toString());
    TextEditingController metrosPerforadosController =
        TextEditingController(text: record['metros_perforados']?.toString() ?? '');
    TextEditingController detallesTrabajoController =
        TextEditingController(text: record['detalles_trabajo_realizado']);

    // Lista de materiales disponibles (debe coincidir con la lista en _addNewRecord)
    List<String> materiales = ['Desmonte', 'Mineral'];
    String? materialSeleccionado = record['material']?.toString();

    List<String> errores = [];

    // Función para calcular metros perforados
    // Función para calcular metros perforados con la nueva fórmula
void calcularMetrosPerforados() {
  if (ntaladroController.text.isNotEmpty && 
      ntaladrosRimadosController.text.isNotEmpty &&
      longitudPerforacionController.text.isNotEmpty) {
    double ntaladros = double.tryParse(ntaladroController.text) ?? 0;
    double ntaladrosRimados = double.tryParse(ntaladrosRimadosController.text) ?? 0;
    double longitudPies = double.tryParse(longitudPerforacionController.text) ?? 0;
    
    // Nueva fórmula: (taladros normales + taladros rimados) * pies * 0.3048
    double metros = (ntaladros + ntaladrosRimados) * longitudPies * 0.3048;
    metrosPerforadosController.text = metros.toStringAsFixed(2);
  } else {
    metrosPerforadosController.text = '';
  }
}

    // Configurar listeners para el cálculo automático
    ntaladrosRimadosController.addListener(calcularMetrosPerforados);
    ntaladroController.addListener(calcularMetrosPerforados);
    longitudPerforacionController.addListener(calcularMetrosPerforados);
    // Calcular valor inicial
    calcularMetrosPerforados();

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
                              _buildNumberField("Nivel", nivelController,
                                  readOnly: true),
                              _buildTextField("Labor", laborController,
                                  readOnly: true),
                              _buildNumberField(
                                  "N° Taladro", ntaladroController),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: "Material utilizado",
                                    border: OutlineInputBorder(),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: materialSeleccionado,
                                      isDense: true,
                                      isExpanded: true,
                                      hint: Text("Seleccione un material"),
                                      items: materiales.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          materialSeleccionado = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildNumberField("N° Taladros Rimados",
                                  ntaladrosRimadosController),
                              _buildDecimalField("Longitud Perforación (pies)",
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
                              if (nivelController.text.isEmpty)
                                errores.add("El campo 'Nivel' es obligatorio.");
                              if (laborController.text.isEmpty)
                                errores.add("El campo 'Labor' es obligatorio.");
                              if (ntaladroController.text.isEmpty)
                                errores.add("El campo 'N° Taladro' es obligatorio.");
                              if (ntaladrosRimadosController.text.isEmpty)
                                errores.add("El campo 'N° Taladros Rimados' es obligatorio.");
                              if (longitudPerforacionController.text.isEmpty)
                                errores.add("El campo 'Longitud de Perforación' es obligatorio.");
                              if (detallesTrabajoController.text.isEmpty)
                                errores.add("El campo 'Detalles del Trabajo Realizado' es obligatorio.");
                              if (materialSeleccionado == null)
                                errores.add("El campo 'Material' es obligatorio.");

                              if (errores.isNotEmpty) {
                                setState(() {});
                                return;
                              }

                              // Actualizar el registro
                              await dbHelper.updateInterPerforacionHorizontal(
                                record['id'],
                                {
                                  "nivel": nivelController.text,
                                  "labor": laborController.text,
                                  "ntaladro": int.tryParse(ntaladroController.text) ?? 0,
                                  "ntaladros_rimados": int.tryParse(ntaladrosRimadosController.text) ?? 0,
                                  "longitud_perforacion": double.tryParse(longitudPerforacionController.text) ?? 0.0,
                                  "metros_perforados": double.tryParse(metrosPerforadosController.text) ?? 0.0,
                                  "detalles_trabajo_realizado": detallesTrabajoController.text,
                                  "material": materialSeleccionado,
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

    // Limpiar listeners
    ntaladrosRimadosController.removeListener(calcularMetrosPerforados);
    longitudPerforacionController.removeListener(calcularMetrosPerforados);
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
  columnSpacing: 12.0,
  border: TableBorder.all(color: Colors.grey),
  headingRowColor: MaterialStateColor.resolveWith(
    (states) => Colors.blue[200]!,
  ),
  columns: [
    DataColumn(label: Center(child: Text('N°', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Nivel', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Labor', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('N° Taladro', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(
                        label: Text('Material',
                            style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Center(child: Text('N° Taladros Rimados', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Longitud de perforación (pies)', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Metros Perforados', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Detalles del Trabajo realizado', style: TextStyle(fontWeight: FontWeight.bold)))),
    DataColumn(label: Center(child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)))),
  ],
  rows: _editableData.isNotEmpty
      ? _editableData.asMap().entries.map((entry) {
          int index = entry.key + 1;
          Map<String, dynamic> row = entry.value;
          return DataRow(
            cells: [
              DataCell(Text(index.toString())),
              _editableCell(row, 'nivel'),
              _editableCell(row, 'labor'),
              _editableCell(row, 'ntaladro'),
              _editableCell(row, 'material'),
              _editableCell(row, 'ntaladros_rimados'),
              _editableCell(row, 'longitud_perforacion'),
              _editableCell(row, 'metros_perforados'),
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
                        : () { _editRecord(row); },
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
                              int recordId = row['id'];
                              _confirmDelete(context, recordId);
                            } else {
                              print("Error: La fila no contiene un ID válido.");
                            }
                          },
                  ),
                ],
              )),
            ],
          );
        }).toList()
      : [
          DataRow(
            cells: List.generate(
              10, // Match the number of columns
              (index) => DataCell(Text('-')),
            ),
          ),
        ],
)
                ),
              ),
            ),
            SizedBox(height: 16),
Center(
  child: SizedBox(
    width: 200, // Ancho fijo que puedes ajustar
    child: ElevatedButton(
      onPressed: () {
        showPdfDialog(
          context,
          widget.tipoOperacion,
          tipoLabor: widget.tipo_labor,
          labor: widget.labor,
          ala: widget.ala,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF21899C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        textStyle: TextStyle(fontSize: 16),
      ),
      child: Text("Ver PDF", style: TextStyle(color: Colors.white)),
    ),
  ),
),
            SizedBox(height: 8),
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
