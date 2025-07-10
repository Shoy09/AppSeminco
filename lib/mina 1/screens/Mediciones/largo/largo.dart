import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/Explosivo.dart';
import 'package:app_seminco/mina%201/models/TipoPerforacion.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/largo/listar_mediciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistroExplosivoPagelargo extends StatefulWidget {
  @override
  _RegistroExplosivoPagelargoState createState() =>
      _RegistroExplosivoPagelargoState();
}

class _RegistroExplosivoPagelargoState
    extends State<RegistroExplosivoPagelargo> {
  final TextEditingController mesController = TextEditingController();
  final TextEditingController semanaController = TextEditingController();
  List<Map<String, dynamic>> exploraciones = [];
  List<Map<String, dynamic>> exploracionesFiltradas = [];
    List<Map<String, dynamic>> _exploraciones = [];
List<TipoPerforacion> _tiposPerforacion = [];
  List<Map<String, dynamic>> _exploracionesSucio = [];
  bool _isLoading = true;
  Map<String, TextEditingController> controllers = {};
    List<Explosivo> _explosivos = [];
  Map<int, Map<String, dynamic>> registrosEditados = {};
  // Función para calcular el número de semana ISO
  int _calcularSemanaISO(DateTime date) {
    final dayOfYear = _diaDelAnio(date);
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();

    if (woy < 1) {
      return _calcularSemanaISO(DateTime(date.year - 1, 12, 31));
    } else if (woy > 52 && DateTime(date.year, 12, 31).weekday < 4) {
      return 1;
    }
    return woy;
  }

  int _diaDelAnio(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  final List<String> meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    mesController.text = meses[now.month - 1];
    semanaController.text = _calcularSemanaISO(now).toString();
    _getTiposPerforacion();
    _cargarExploraciones();
    _cargarDatosExplosivos();
    
  }

    void _cargarDatosExplosivos() async {
    List<Explosivo> explosivos = await DatabaseHelper_Mina1().getExplosivos();
    print("explosivos local $explosivos");

    setState(() {
      _explosivos = explosivos;
    });
  }
Future<void> _getTiposPerforacion() async {
  try {
    final dbHelper = DatabaseHelper_Mina1();
    _tiposPerforacion = await dbHelper.getTiposPerforacionLargo();
    print("Tipos de Perforación obtenidos de la BD local: $_tiposPerforacion");
    
    // Después de obtener los tipos, aplicar el filtro si ya tenemos las exploraciones
    if (_exploracionesSucio.isNotEmpty) {
      _filtrarExploraciones();
    }
  } catch (e) {
    print("Error al obtener los tipos de perforación: $e");
  }
}

Future<void> _cargarExploraciones() async {
  try {
    final dbHelper = DatabaseHelper_Mina1();
    final exploraciones = await dbHelper.obtenerExploracionesCompletas();

    setState(() {
      _exploracionesSucio = exploraciones;
      _isLoading = false;
    });
    
    // Si ya tenemos los tipos de perforación, aplicar el filtro
    if (_tiposPerforacion.isNotEmpty) {
      _filtrarExploraciones();
    }
    if (_explosivos.isNotEmpty) {
        calcularKgExplosivos();
      }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cargar exploraciones: $e')),
    );
  }
}

  void calcularKgExplosivos() {
    for (var registro in _exploracionesSucio) {
      double totalKg = 0.0;

      Map<String, double> despachosTotales = {};
      for (var despacho in registro['despachos'] ?? []) {
        for (var detalle in despacho['detalles'] ?? []) {
          String nombre = detalle['nombre_material'];
          double cantidad =
              double.tryParse(detalle['cantidad'].toString()) ?? 0.0;

          despachosTotales[nombre] = (despachosTotales[nombre] ?? 0) + cantidad;
        }
      }

      // Procesar devoluciones
      Map<String, double> devolucionesTotales = {};
      for (var devolucion in registro['devoluciones'] ?? []) {
        for (var detalle in devolucion['detalles'] ?? []) {
          String nombre = detalle['nombre_material'];
          double cantidad =
              double.tryParse(detalle['cantidad'].toString()) ?? 0.0;

          devolucionesTotales[nombre] =
              (devolucionesTotales[nombre] ?? 0) + cantidad;
        }
      }

      // Calcular diferencias y totalKg
      despachosTotales.forEach((nombre, cantidadDespacho) {
        double cantidadDevolucion = devolucionesTotales[nombre] ?? 0.0;
        double diferencia = cantidadDespacho - cantidadDevolucion;

        // Buscar el explosivo correspondiente
        Explosivo? explosivo;
        try {
          explosivo = _explosivos.firstWhere((e) => e.tipoExplosivo == nombre);
        } catch (e) {
          explosivo = null;
        }

        if (explosivo != null) {
          double kg = diferencia * explosivo.pesoUnitario;
          totalKg += kg;
        }
      });

      // Guardar el resultado en el registro
      registro['kg_explosivos'] = totalKg.toStringAsFixed(2);
    }
  }

void _filtrarExploraciones() {
  // Extraemos los nombres de los tipos de perforación para comparar
  final nombresTipos = _tiposPerforacion.map((t) => t.nombre.toLowerCase()).toSet();
  
  setState(() {
    _exploraciones = _exploracionesSucio.where((exploracion) {
      final tipoExploracion = exploracion['tipo_perforacion']?.toString().toLowerCase();
      return tipoExploracion != null && nombresTipos.contains(tipoExploracion);
    }).toList();
  });
}

  void borrarCampos() {
    mesController.clear();
    semanaController.clear();
    setState(() {});
  }

  void buscarDatos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Filtrando datos para ${mesController.text}, semana ${semanaController.text}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mediciones'),
        backgroundColor: Color(0xFF21899C),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListaPantalla()),
    );
    // Esta línea se ejecutará cuando regreses de ListaPantalla
    _recargarDatos();
  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value:
                        mesController.text.isEmpty ? null : mesController.text,
                    decoration: InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: meses.map((String mes) {
                      return DropdownMenuItem<String>(
                        value: mes,
                        child: Text(mes),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        mesController.text = newValue ?? '';
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: TextField(
                    controller: semanaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Semana',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.search, size: 20),
                  label: Text('Buscar'),
                  onPressed: buscarDatos,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Tablas dinámicas por tipo de perforación
            Expanded(
              child: ListView(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 3,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        'PERFORACIÓN TALADRO LARGO',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              // Tabla con todos los campos solicitados
                              SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Table(
                                  border: TableBorder.all(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.2),
                                    1: FlexColumnWidth(1.2),
                                    2: FlexColumnWidth(1.2),
                                    3: FlexColumnWidth(1.4),
                                    4: FlexColumnWidth(1.2),
                                    5: FlexColumnWidth(1.3),
                                    6: FlexColumnWidth(1.4),
                                    7: FlexColumnWidth(1.3),
                                    8: FlexColumnWidth(1.3),
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
                                        tableCellBold(context, 'FECHA'),
                                        tableCellBold(context, 'TURNO'),
                                        tableCellBold(context, 'EMPRESA'),
                                        tableCellBold(context, 'ZONA'),
                                        tableCellBold(context, 'LABOR'),
                                        tableCellBold(context, 'VETA'),
                                        tableCellBold(
                                            context, 'TIPO PERFORACIÓN'),
                                        tableCellBold(context, 'KG EXPLOSIVOS'),
                                        tableCellBold(
                                            context, 'TONELADAS'),
                                      ],
                                    ),

                                    // Filas con datos
                                    for (int i = 0;
                                        i < _exploraciones.length;
                                        i++)
                                      TableRow(children: [
                                        tableCell(_exploraciones[i]['fecha']
                                                ?.toString() ??
                                            ''),
                                            tableCell(_exploraciones[i]['turno']
                                                ?.toString() ??
                                            ''),
                                        tableCell(_exploraciones[i]['empresa']
                                                ?.toString() ??
                                            ''),
                                        tableCell(_exploraciones[i]['zona']
                                                ?.toString() ??
                                            ''),
                                        tableCellMulti([
                                          _exploraciones[i]['tipo_labor']
                                                  ?.toString() ??
                                              '',
                                          _exploraciones[i]['labor']
                                                  ?.toString() ??
                                              '',
                                          _exploraciones[i]['ala']
                                                  ?.toString() ??
                                              ''
                                        ]),
                                        tableCell(_exploraciones[i]['veta']
                                                ?.toString() ??
                                            ''),
                                        tableCell(_exploraciones[i]
                                                    ['tipo_perforacion']
                                                ?.toString() ??
                                            ''),
                                        tableCell(_exploraciones[i]
                                                    ['kg_explosivos']
                                                ?.toString() ??
                                            ''),
                                            tableCell(_exploraciones[i]
                                                    ['toneladas']
                                                ?.toString() ??
                                            ''),
                                        
                                      ]),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Botones de acción
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: borrarCampos,
                                      label: Text('BORRAR'),
                                    ),
                                    SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      icon: Icon(Icons.send, size: 18),
                                      label: Text('ENVIAR'),
                                      onPressed: () async {
                                      await insertarYActualizarMedicionesLargo();
                                      },
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> insertarYActualizarMedicionesLargo() async {
  List<Map<String, dynamic>> registros = obtenerDatosEditadosFormateados();

  if (registros.isEmpty) {
    print("No hay registros editados para insertar.");
    return;
  }

  final dbHelper = DatabaseHelper_Mina1();
  List<int> idsParaActualizar = [];

  try {
    for (var registro in registros) {
      int? idExplosivo = registro['id_explosivo'];
      if (idExplosivo == null) {
        print("⚠️ Registro sin id_explosivo. Se omite: $registro");
        continue;
      }

      int idInsertado = await dbHelper.insertarMedicionLargo(registro);
      print("Registro insertado con id: $idInsertado, id_explosivo original: $idExplosivo");
      idsParaActualizar.add(idExplosivo);
    }

    if (idsParaActualizar.isNotEmpty) {
      await dbHelper.actualizarMedicionEXplosivo(idsParaActualizar);
      print("Registros actualizados en nube_Datos_trabajo_exploraciones con medicion=1");
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos guardados exitosamente')),
      );
      
      // Recargar los datos
      await _recargarDatos();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar datos: $e')),
    );
    print("Error al insertar/actualizar mediciones: $e");
  }
}

  List<Map<String, dynamic>> obtenerDatosEditadosFormateados() {
    List<Map<String, dynamic>> listaDatos = [];

    registrosEditados.forEach((index, registro) {
      String tipoLaborLaborAla =
          "${registro['tipo_labor'] ?? ''} ${registro['labor'] ?? ''} ${registro['ala'] ?? ''}"
              .trim();

      Map<String, dynamic> datos = {
        // 'id_registro': registro['id'], // 🔴 no incluir en insert, pero sí guardarlo aparte si lo necesitas
        'id_explosivo': registro['id'], // ✅ lo guardamos para otro uso
        'fecha': registro['fecha'],
        'turno': registro['turno'],
        'empresa': registro['empresa'],
        'zona': registro['zona'],
        'labor': tipoLaborLaborAla,
        'veta': registro['veta'],
        'tipo_perforacion': registro['tipo_perforacion'],
        'kg_explosivos': registro['kg_explosivos'],
        'toneladas': registro['toneladas'],
        'idnube': registro['idnube'],
      };

      listaDatos.add(datos);
    });

    return listaDatos;
  }

Future<void> _recargarDatos() async {
  setState(() {
    _isLoading = true;
  });
  
  // Limpia los datos existentes y los controladores
  _limpiarControladores();
  _exploracionesSucio = [];
  _exploraciones = [];
  registrosEditados = {};
  
  // Vuelve a cargar todos los datos
  await _getTiposPerforacion();
  await _cargarExploraciones();
  _cargarDatosExplosivos();
  
  setState(() {
    _isLoading = false;
  });
}

void _limpiarControladores() {
  // Disponse de todos los controladores existentes
  controllers.forEach((key, controller) {
    controller.dispose();
  });
  // Limpia el mapa de controladores
  controllers.clear();
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


  Widget tableCellEditable(String tipoPerforacion, String labor, int index,
      String campo, dynamic valor) {
    final key = '$tipoPerforacion-$labor-$index-$campo';

    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: valor?.toString() ?? '');
    }

    final controller = controllers[key]!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        onChanged: (newValue) {
          if (newValue.isEmpty || double.tryParse(newValue) != null) {
            actualizarValor(tipoPerforacion, labor, index, campo, newValue);
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

    void actualizarValor(String tipoPerforacion, String labor, int index,
      String campo, String nuevoValor) {
    setState(() {
      _exploraciones[index][campo] = nuevoValor;

      // Guarda la fila completa editada
      registrosEditados[index] =
          Map<String, dynamic>.from(_exploraciones[index]);
    });
  }


  Widget tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(text)),
    );
  }

  Widget tableCellBold(BuildContext context, String text) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize =
        screenWidth < 600 ? 8 : 12; // Ajusta el umbral y tamaños a gusto

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
}
