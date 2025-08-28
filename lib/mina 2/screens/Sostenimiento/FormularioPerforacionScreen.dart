import 'package:app_seminco/components/showPdfDialog_mina2.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class FormularioScreen extends StatefulWidget {
  final String estado;
  final String tipoOperacion; // 🔹 Parámetro recibido
  final int id;
  final String zona;
final int operacionId;
  final String tipo_labor;
  final String labor;
  final String nivel;
  final String ala;

  FormularioScreen(
      {required this.id,
      required this.estado,
      required this.ala,

      required this.operacionId,
      required this.tipoOperacion,
      required this.zona,
      required this.tipo_labor,
      required this.labor,
      required this.nivel});

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
    obtenerEstadosBD();
    obtenerPlanMensual();
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

  void obtenerEstadosBD() async {
    List<Map<String, dynamic>> estadosObtenidos =
        await DatabaseHelper_Mina2().getEstadosBDOPERATIVO(widget.tipoOperacion);

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
        await dbHelper.getInterSostenimientos(widget.id);
    setState(() {
      _editableData = data;
    });
  }

Future<void> _addNewRecord() async {
  TextEditingController nivelController = TextEditingController(text: widget.nivel);
  TextEditingController laborController = TextEditingController(text: widget.labor);
  TextEditingController ntaladroController = TextEditingController();
  TextEditingController longitudPerforacionController = TextEditingController();
  TextEditingController metrosPerforadosController = TextEditingController(); // Nuevo controlador
  TextEditingController mallaInstaladaController = TextEditingController();
  TextEditingController detallesController = TextEditingController();
  
  // Lista de materiales disponibles
  List<String> materiales = ['Desmonte', 'Mineral'];
  String? materialSeleccionado;

  // Función para calcular metros perforados
  void calcularMetrosPerforados() {
    if (ntaladroController.text.isNotEmpty && 
        longitudPerforacionController.text.isNotEmpty) {
      double ntaladros = double.tryParse(ntaladroController.text) ?? 0;
      double longitudPies = double.tryParse(longitudPerforacionController.text) ?? 0;
      // Convertir pies a metros y multiplicar por número de taladros
      double metros = longitudPies * 0.3048 * ntaladros;
      metrosPerforadosController.text = metros.toStringAsFixed(2);
    } else {
      metrosPerforadosController.text = '';
    }
  }

  // Configurar listeners
  ntaladroController.addListener(calcularMetrosPerforados);
  longitudPerforacionController.addListener(calcularMetrosPerforados);

  List<String> errores = [];

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Agregar Nuevo Registro",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildNumberField("Nivel", nivelController, readOnly: true),
                            _buildTextField("Labor", laborController, readOnly: true),
                            _buildNumberField("N° Taladro", ntaladroController),
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
                            _buildDecimalField("Longitud De Perforación (pies)", longitudPerforacionController),
                            _buildDecimalField("Malla instalada (m²)", mallaInstaladaController),
                            
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: detallesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: "Detalles del trabajo realizado",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            
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

                            if (nivelController.text.isEmpty)
                              errores.add("El campo 'Nivel' es obligatorio.");
                            if (laborController.text.isEmpty)
                              errores.add("El campo 'Labor' es obligatorio.");
                            if (ntaladroController.text.isEmpty)
                              errores.add("El campo 'N° Taladro' es obligatorio.");
                            if (longitudPerforacionController.text.isEmpty)
                              errores.add("El campo 'Longitud de Perforación' es obligatorio.");
                            if (metrosPerforadosController.text.isEmpty)
                              errores.add("El cálculo de metros perforados no es válido.");
                            if (mallaInstaladaController.text.isEmpty)
                              errores.add("El campo 'Malla instalada' es obligatorio.");
                            if (materialSeleccionado == null)
                              errores.add("Debe seleccionar un material.");

                            if (errores.isNotEmpty) {
                              setState(() {});
                              return;
                            }

                            await dbHelper.insertInterSostenimiento(
                              widget.id,
                              nivelController.text,
                              laborController.text,
                              int.tryParse(ntaladroController.text) ?? 0,
                              double.tryParse(longitudPerforacionController.text) ?? 0.0,
                              mallaInstaladaController.text,
                              double.tryParse(metrosPerforadosController.text) ?? 0.0,
                              detallesController.text,
                              materialSeleccionado!,
                            );

                            if (widget.operacionId != null) {
                              await dbHelper.actualizarEstadoAParciales(widget.operacionId!);
                            }
                            
                            _loadData();
                            Navigator.of(context).pop();
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

  // Limpiar listeners
  ntaladroController.removeListener(calcularMetrosPerforados);
  longitudPerforacionController.removeListener(calcularMetrosPerforados);
}

Future<void> _editRecord(Map<String, dynamic> record) async {
  TextEditingController nivelController = TextEditingController(text: record['nivel']);
  TextEditingController laborController = TextEditingController(text: record['labor']);
  TextEditingController ntaladroController = TextEditingController(text: record['ntaladro'].toString());
  TextEditingController longitudPerforacionController = TextEditingController(text: record['longitud_perforacion'].toString());
  TextEditingController metrosPerforadosController = TextEditingController(text: record['metros_perforados']?.toString() ?? '');
  TextEditingController mallaInstaladaController = TextEditingController(text: record['malla_instalada'].toString());
  TextEditingController detallesController = TextEditingController(text: record['detalles_trabajo_realizado']?.toString() ?? '');
  
  // Lista de materiales disponibles
  List<String> materiales = ['Desmonte', 'Mineral'];
  String? materialSeleccionado = record['material']?.toString();

  // Función para calcular metros perforados
  void calcularMetrosPerforados() {
    if (ntaladroController.text.isNotEmpty && 
        longitudPerforacionController.text.isNotEmpty) {
      double ntaladros = double.tryParse(ntaladroController.text) ?? 0;
      double longitudPies = double.tryParse(longitudPerforacionController.text) ?? 0;
      // Convertir pies a metros y multiplicar por número de taladros
      double metros = longitudPies * 0.3048 * ntaladros;
      metrosPerforadosController.text = metros.toStringAsFixed(2);
    } else {
      metrosPerforadosController.text = '';
    }
  }

  // Configurar listeners
  ntaladroController.addListener(calcularMetrosPerforados);
  longitudPerforacionController.addListener(calcularMetrosPerforados);
  // Calcular valor inicial
  calcularMetrosPerforados();

  List<String> errores = [];

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Actualizar Registro",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildNumberField("Nivel", nivelController, readOnly: true),
                            _buildTextField("Labor", laborController, readOnly: true),
                            _buildNumberField("N° Taladro", ntaladroController),
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
                            _buildDecimalField("Longitud De Perforación (pies)", longitudPerforacionController),
                            _buildDecimalField("Malla instalada (m²)", mallaInstaladaController),
                            
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextField(
                                controller: detallesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: "Detalles del trabajo realizado",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            
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

                            if (nivelController.text.isEmpty)
                              errores.add("El campo 'Nivel' es obligatorio.");
                            if (laborController.text.isEmpty)
                              errores.add("El campo 'Labor' es obligatorio.");
                            if (ntaladroController.text.isEmpty)
                              errores.add("El campo 'N° Taladro' es obligatorio.");
                            if (longitudPerforacionController.text.isEmpty)
                              errores.add("El campo 'Longitud de Perforación' es obligatorio.");
                            if (metrosPerforadosController.text.isEmpty)
                              errores.add("El cálculo de metros perforados no es válido.");
                            if (mallaInstaladaController.text.isEmpty)
                              errores.add("El campo 'Malla instalada' es obligatorio.");
                            if (materialSeleccionado == null)
                              errores.add("Debe seleccionar un material.");

                            if (errores.isNotEmpty) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errores.join("\n")),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }

                            await dbHelper.updateInterSostenimiento(
                              record['id'],
                              {
                                "nivel": nivelController.text,
                                "labor": laborController.text,
                                "ntaladro": int.tryParse(ntaladroController.text) ?? 0,
                                "longitud_perforacion": double.tryParse(longitudPerforacionController.text) ?? 0.0,
                                "metros_perforados": double.tryParse(metrosPerforadosController.text) ?? 0.0, // Nuevo campo
                                "malla_instalada": mallaInstaladaController.text,
                                "detalles_trabajo_realizado": detallesController.text,
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
  ntaladroController.removeListener(calcularMetrosPerforados);
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
        content: Text("¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Cerrar el diálogo sin eliminar
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
    await dbHelper.deleteInterostenimiento(recordId); // Eliminar en BD

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


  Future<void> _saveData() async {
    for (var row in _editableData) {
      await dbHelper.updateInterSostenimiento(row['id'], row);
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
                          label: Text('N°',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      
                      DataColumn(
                          label: Text('Nivel',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Labor',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      
                     
                      DataColumn(
                          label: Text('N° Taladro',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Longitud de\nperforación (m)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Center(child: Text('Metros Perforados', style: TextStyle(fontWeight: FontWeight.bold)))),

                      DataColumn(
                          label: Text('Malla instalada (m2)',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                              
                              DataColumn(
                        label: Text('Material',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Detalles',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                              
                              DataColumn(
                          label: Text('Acciones',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _editableData.isNotEmpty
                        ? _editableData.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            Map<String, dynamic> row = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(index.toString())),
                              _editableCell(row, 'nivel'),
                              _editableCell(row, 'labor'),
                              _editableCell(row, 'ntaladro'),
                              _editableCell(row, 'longitud_perforacion'),
                              _editableCell(row, 'metros_perforados'),
                              _editableCell(row, 'malla_instalada'),
                              _editableCell(row, 'material'),
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
                                10,
                                (index) => DataCell(Text('-')),
                              ),
                            ),
                          ],
                  ),
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
