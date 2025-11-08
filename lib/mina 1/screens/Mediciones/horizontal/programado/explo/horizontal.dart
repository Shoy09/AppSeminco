import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/Explosivo.dart';
import 'package:app_seminco/mina%201/models/TipoPerforacion.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/ejecutado/listar_mediciones.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistroExplosivoPagehorizontal extends StatefulWidget {
  final String zona;

  const RegistroExplosivoPagehorizontal({Key? key, required this.zona})
      : super(key: key);


  @override
  _RegistroExplosivoPageHorizontalState createState() =>
      _RegistroExplosivoPageHorizontalState();
}

class _RegistroExplosivoPageHorizontalState
    extends State<RegistroExplosivoPagehorizontal> {
  List<Map<String, dynamic>> exploraciones = [];
  List<Map<String, dynamic>> exploracionesFiltradas = [];
  List<Map<String, dynamic>> _exploraciones = [];
  List<TipoPerforacion> _tiposPerforacion = [];
  List<Map<String, dynamic>> _exploracionesSucio = [];
  bool _isLoading = true;
  Map<String, TextEditingController> controllers = {};
  List<Explosivo> _explosivos = [];
  Map<int, Map<String, dynamic>> registrosEditados = {};
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController turnoController = TextEditingController();
  List<TipoPerforacion> perforacionesHorizontales = [];
  // Función para calcular el número de semana ISO

  // Variables para control de filtros
  bool _filtrosAplicados = false;
  String? _fechaFiltro;
  String? _turnoFiltro;
  
  int _diaDelAnio(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
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
      _tiposPerforacion = await dbHelper.getTiposPerforacionhorizontalfil();

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
      final exploraciones = await dbHelper.obtenerExploracionesCompletasPorZonaProgramado(widget.zona);

      setState(() {
        _exploracionesSucio = exploraciones;
        _isLoading = false;
      });

      if (_tiposPerforacion.isNotEmpty) {
        _filtrarExploraciones();
      }

      // Si ya cargaste explosivos, calcula kg_explosivos
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
    final nombresTipos =
        _tiposPerforacion.map((t) => t.nombre.toLowerCase()).toSet();

    setState(() {
      _exploraciones = _exploracionesSucio.where((exploracion) {
        final tipoExploracion =
            exploracion['tipo_perforacion']?.toString().toLowerCase();
        return tipoExploracion != null &&
            nombresTipos.contains(tipoExploracion);
      }).toList();
    });
  }

  // Función para aplicar filtros de fecha y turno
  void _aplicarFiltros() {
    if (fechaController.text.isEmpty && turnoController.text.isEmpty) {
      // Si no hay filtros, mostrar todos los datos
      setState(() {
        _filtrosAplicados = false;
        _fechaFiltro = null;
        _turnoFiltro = null;
      });
      _filtrarExploraciones();
      return;
    }

    setState(() {
      _filtrosAplicados = true;
      _fechaFiltro = fechaController.text.isEmpty ? null : fechaController.text;
      _turnoFiltro = turnoController.text.isEmpty ? null : turnoController.text;
    });

    // Extraemos los nombres de los tipos de perforación para comparar
    final nombresTipos =
        _tiposPerforacion.map((t) => t.nombre.toLowerCase()).toSet();

    setState(() {
      _exploraciones = _exploracionesSucio.where((exploracion) {
        // Filtro por tipo de perforación
        final tipoExploracion =
            exploracion['tipo_perforacion']?.toString().toLowerCase();
        final pasaTipo = tipoExploracion != null &&
            nombresTipos.contains(tipoExploracion);

        // Filtro por fecha
        final fechaExploracion = exploracion['fecha']?.toString();
        final pasaFecha = _fechaFiltro == null || fechaExploracion == _fechaFiltro;

        // Filtro por turno
        final turnoExploracion = exploracion['turno']?.toString();
        final pasaTurno = _turnoFiltro == null || 
            (_turnoFiltro == 'Día' && turnoExploracion == 'Dia') ||
            (_turnoFiltro == 'Noche' && turnoExploracion == 'Noche');

        return pasaTipo && pasaFecha && pasaTurno;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtros aplicados: ${_obtenerTextoFiltros()}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Función para quitar todos los filtros
  void _quitarFiltros() {
    setState(() {
      fechaController.clear();
      turnoController.clear();
      _filtrosAplicados = false;
      _fechaFiltro = null;
      _turnoFiltro = null;
    });

    _filtrarExploraciones();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Todos los filtros han sido removidos'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Función para obtener texto descriptivo de los filtros aplicados
  String _obtenerTextoFiltros() {
    List<String> filtros = [];
    if (_fechaFiltro != null) filtros.add('Fecha: $_fechaFiltro');
    if (_turnoFiltro != null) filtros.add('Turno: $_turnoFiltro');
    return filtros.isEmpty ? 'Sin filtros' : filtros.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar exploraciones por empresa
    final Map<String, List<Map<String, dynamic>>> exploracionesPorEmpresa = {};
    for (var exploracion in _exploraciones) {
      final empresa = exploracion['empresa']?.toString() ?? 'Sin empresa';
      if (!exploracionesPorEmpresa.containsKey(empresa)) {
        exploracionesPorEmpresa[empresa] = [];
      }
      exploracionesPorEmpresa[empresa]!.add(exploracion);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtros mejorados
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros de Búsqueda',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_filtrosAplicados) ...[
                          Icon(Icons.filter_alt, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Filtros activos',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12),
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
                              prefixIcon: Icon(Icons.calendar_today, size: 20),
                              hintText: 'Seleccionar fecha',
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
                              prefixIcon: Icon(Icons.access_time, size: 20),
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
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.search, size: 20),
                          label: Text('Buscar'),
                          onPressed: _aplicarFiltros,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (_filtrosAplicados)
                          ElevatedButton.icon(
                            icon: Icon(Icons.clear, size: 20),
                            label: Text('Quitar Filtros'),
                            onPressed: _quitarFiltros,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                    if (_filtrosAplicados) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Filtros aplicados: ${_obtenerTextoFiltros()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Información de resultados
            if (_exploraciones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de registros: ${_exploraciones.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (_filtrosAplicados)
                      Text(
                        'Filtrado de ${_exploracionesSucio.length} registros',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 12),
            
            // Tablas dinámicas por empresa
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _exploraciones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _filtrosAplicados
                                    ? 'No se encontraron registros con los filtros aplicados'
                                    : 'No hay registros disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_filtrosAplicados) ...[
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _quitarFiltros,
                                  child: Text('Ver todos los registros'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView(
                          children: exploracionesPorEmpresa.entries.map((entry) {
                            final empresa = entry.key;
                            final exploracionesEmpresa = entry.value;
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
                                              4: FlexColumnWidth(1.7),
                                              5: FlexColumnWidth(1.2),
                                              6: FlexColumnWidth(1.2),
                                              7: FlexColumnWidth(1.2),
                                              8: FlexColumnWidth(1.0),
                                              9: FlexColumnWidth(1.0),
                                              10: FlexColumnWidth(0.8),
                                              11: FlexColumnWidth(1.0),
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
                                                  tableCellBold(context, 'LABOR'),
                                                  tableCellBold(
                                                      context, 'TIPO PERFORACIÓN'),
                                                  tableCellBold(context, 'KG EXPLOSIVOS'),
                                                  tableCellBold(
                                                      context, 'AVANCE PROGRAMADO (m)'),
                                                  tableCellBold(context, 'ANCHO (m)'),
                                                  tableCellBold(context, 'ALTO (m)'),
                                                  tableCellBold(context, 'NO APLICA'),
                                                  tableCellBold(context, 'REMANENTE'),
                                                ],
                                              ),
                                              // Filas con datos
                                              for (int i = 0;
                                                  i < exploracionesEmpresa.length;
                                                  i++)
                                                TableRow(children: [
                                                  tableCell((i + 1).toString()),
                                                  tableCell(exploracionesEmpresa[i]
                                                              ['fecha']
                                                          ?.toString() ??
                                                      ''),
                                                  tableCell(exploracionesEmpresa[i]
                                                              ['semanaDefault']
                                                          ?.toString() ??
                                                      ''),
                                                  tableCell(exploracionesEmpresa[i]
                                                              ['turno']
                                                          ?.toString() ??
                                                      ''),
                                                  
                                                  tableCellMulti([
                                                    exploracionesEmpresa[i]['tipo_labor']
                                                            ?.toString() ??
                                                        '',
                                                    exploracionesEmpresa[i]['labor']
                                                            ?.toString() ??
                                                        '',
                                                    exploracionesEmpresa[i]['ala']
                                                            ?.toString() ??
                                                        ''
                                                  ]),
                                                  tableCell(exploracionesEmpresa[i]
                                                              ['tipo_perforacion']
                                                          ?.toString() ??
                                                      ''),
                                                  tableCell(exploracionesEmpresa[i]
                                                              ['kg_explosivos']
                                                          ?.toString() ??
                                                      ''),
                                                  tableCellEditable(
                                                    'exploraciones',
                                                    'avance_programado',
                                                    _exploraciones.indexOf(
                                                        exploracionesEmpresa[i]),
                                                    'avance_programado',
                                                    exploracionesEmpresa[i]
                                                        ['avance_programado'],
                                                    !(exploracionesEmpresa[i]['activo'] ==
                                                        1),
                                                  ),
                                                  tableCellEditable(
                                                    'exploraciones',
                                                    'dimensiones',
                                                    _exploraciones
                                                        .indexOf(exploracionesEmpresa[i]),
                                                    'ancho',
                                                    exploracionesEmpresa[i]['ancho'],
                                                    !(exploracionesEmpresa[i]['activo'] ==
                                                            1 ||
                                                        exploracionesEmpresa[i]
                                                                ['remanente'] ==
                                                            1),
                                                  ),
                                                  tableCellEditable(
                                                    'exploraciones',
                                                    'dimensiones',
                                                    _exploraciones
                                                        .indexOf(exploracionesEmpresa[i]),
                                                    'alto',
                                                    exploracionesEmpresa[i]['alto'],
                                                    !(exploracionesEmpresa[i]['activo'] ==
                                                            1 ||
                                                        exploracionesEmpresa[i]
                                                                ['remanente'] ==
                                                            1),
                                                  ),
                                                  // Checkbox para Activo
                                                  TableCell(
                                                    verticalAlignment:
                                                        TableCellVerticalAlignment.middle,
                                                    child: Checkbox(
                                                      value: exploracionesEmpresa[i]
                                                              ['activo'] ==
                                                          1,
                                                      onChanged: (exploracionesEmpresa[i]
                                                                  ['remanente'] ==
                                                              1)
                                                          ? null
                                                          : (bool? value) {
                                                              setState(() {
                                                                final index =
                                                                    _exploraciones.indexOf(
                                                                        exploracionesEmpresa[
                                                                            i]);
                                                                _exploraciones[index]
                                                                        ['activo'] =
                                                                    value! ? 1 : 0;
                                                                if (!registrosEditados
                                                                    .containsKey(index)) {
                                                                  registrosEditados[
                                                                      index] = Map<String,
                                                                          dynamic>.from(
                                                                      _exploraciones[
                                                                          index]);
                                                                } else {
                                                                  registrosEditados[
                                                                              index]![
                                                                          'activo'] =
                                                                      value ? 1 : 0;
                                                                }
                                                              });
                                                            },
                                                    ),
                                                  ),
                                                  // Checkbox para Remanente
                                                  TableCell(
                                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                                    child: Checkbox(
                                                      value: exploracionesEmpresa[i]['remanente'] == 1,
                                                      onChanged: (exploracionesEmpresa[i]['activo'] == 1)
                                                          ? null
                                                          : (bool? value) {
                                                              final index = _exploraciones.indexOf(exploracionesEmpresa[i]);
                                                              setState(() {
                                                                _exploraciones[index]['remanente'] = value! ? 1 : 0;
                                                                if (!registrosEditados.containsKey(index)) {
                                                                  registrosEditados[index] = Map<String, dynamic>.from(_exploraciones[index]);
                                                                } else {
                                                                  registrosEditados[index]!['remanente'] = value ? 1 : 0;
                                                                }
                                                              });
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
                                                onPressed: () {},
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
                                                  await insertarYActualizarMedicionesHorizontal();
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
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Resto de los métodos se mantienen igual...
  Widget tableCellEditable(String tipoPerforacion, String labor, int index,
      String campo, dynamic valor, bool enabled) {
    final key = '$tipoPerforacion-$labor-$index-$campo';
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

  Future<void> insertarYActualizarMedicionesHorizontal() async {
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

        int idInsertado = await dbHelper.insertarMedicionHorizontalprogramado(registro);
        print(
            "Registro insertado con id: $idInsertado, id_explosivo original: $idExplosivo");
        idsParaActualizar.add(idExplosivo);
      }

      if (idsParaActualizar.isNotEmpty) {
        await dbHelper.actualizarMedicionEXplosivoProgramado(idsParaActualizar);
        print(
            "Registros actualizados en nube_Datos_trabajo_exploraciones con medicion=1");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos guardados exitosamente')),
        );

        await _recargarDatos();
      }
    } catch (e) {
      if (!mounted) return;
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
        'id_explosivo': registro['id'],
        'fecha': registro['fecha'],
        'semana': registro['semanaDefault'], 
        'turno': registro['turno'],
        'empresa': registro['empresa'],
        'zona': registro['zona'],
        'labor': tipoLaborLaborAla,
        'veta': registro['veta'],
        'tipo_perforacion': registro['tipo_perforacion'],
        'kg_explosivos': registro['kg_explosivos'],
        'avance_programado': registro['avance_programado'],
        'ancho': registro['ancho'],
        'alto': registro['alto'],
        'idnube': registro['idnube'],
        'no_aplica': registro['activo'] ?? 0,
        'remanente': registro['remanente'] ?? 0,
      };

      listaDatos.add(datos);
    });

    return listaDatos;
  }

  Future<void> _recargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    _limpiarControladores();
    _exploracionesSucio = [];
    _exploraciones = [];
    registrosEditados = {};

    await _getTiposPerforacion();
    await _cargarExploraciones();
    _cargarDatosExplosivos();

    setState(() {
      _isLoading = false;
    });
  }

  void _limpiarControladores() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
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

  void actualizarValor(String tipoPerforacion, String labor, int index,
      String campo, String nuevoValor) {
    setState(() {
      _exploraciones[index][campo] = nuevoValor;
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
        screenWidth < 600 ? 8 : 12;

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