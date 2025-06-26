import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:app_seminco/models/explosivos_uni.dart';

class FormularioDevolucionesScreen extends StatefulWidget {
  final int exploracionId; // Recibir el ID de Datos_trabajo_exploraciones
  final dynamic dni;
  final VoidCallback? onEstadoActualizado;
  const FormularioDevolucionesScreen({
    Key? key,
    required this.exploracionId,
    this.onEstadoActualizado,
    required this.dni,
  }) : super(key: key);

  @override
  _FormularioDevolucionesScreenState createState() =>
      _FormularioDevolucionesScreenState();
}

class _FormularioDevolucionesScreenState
    extends State<FormularioDevolucionesScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _detallesDespacho = [];
  List<Map<String, dynamic>> _detallesDevoluciones = [];
  int? _DevolucionesId;
  int? _despachoId;
  String nombreUsuario = ""; // Variable para el nombre completo
  String? firmaUsuario; // Variable para la ruta de la imagen de firma
  final Map<String, TextEditingController> _controllers = {};
  bool _registroCerrado = false;
  // Controladores adicionales
  List<ExplosivosUni> milisegundosList = [];
  List<ExplosivosUni> medioSegundosList = [];

    final TextEditingController _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 20; i++) {
      _controllers['msCant1_$i'] = TextEditingController();
      _controllers['lpCant1_$i'] = TextEditingController();
    }
    _loadDetallesDevoluciones();
    _loadDetallesDespacho();
    _verificarEstadoRegistro();
    _cargarUsuario();
    fetchExplosivosuni();
  }

  void fetchExplosivosuni() async {
    List<ExplosivosUni> explosivos = await DatabaseHelper().getExplosivosUni();

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

  Future<void> _cargarUsuario() async {
    try {
      final dbHelper = DatabaseHelper();
      final usuario = await dbHelper.getUserByDni(widget.dni);

      if (usuario != null) {
        setState(() {
          // Concatenar nombres y apellidos
          nombreUsuario = "${usuario['nombres']} ${usuario['apellidos']}";
          // Guardar la ruta de la imagen de la firma
          firmaUsuario = usuario['firma'];
        });
      } else {
        setState(() {
          nombreUsuario = "Usuario no encontrado";
          firmaUsuario = "";
        });
      }
    } catch (e) {
      print('Error obteniendo usuario: $e');
      setState(() {
        nombreUsuario = "Error al cargar usuario";
        firmaUsuario = "";
      });
    }
  }

  Future<void> _verificarEstadoRegistro() async {
    bool cerrado =
        await DatabaseHelper().estaRegistroCerrado(widget.exploracionId);
    setState(() {
      _registroCerrado = cerrado;
    });
  }

  void _loadDetallesDevoluciones() async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper()
        .getDetalleDevolucionesByExploracionId(widget.exploracionId);

    if (detalles.isNotEmpty) {
      var detail = detalles.first; // Toma el primer registro

      _DevolucionesId = detail['id']; // Guardar el ID del Devoluciones

      final obs = detail['observaciones'];
    if (obs != null) {
      _observacionesController.text = obs.toString();
    }

      setState(() {});

      // Llamar a _loadDetallesDevolucionesExplo() después de obtener el ID
      if (_DevolucionesId != null) {
        _loadDetallesDevolucionesExplo(_DevolucionesId!);
        _loadDetalleDevolucionesMateriales(_DevolucionesId!);
      }
    }
  }

  void _loadDetallesDespacho() async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper()
        .getDetalleDespachoByExploracionId(widget.exploracionId);

    if (detalles.isNotEmpty) {
      var detail = detalles.first; // Toma el primer registro

      _despachoId = detail['id']; // Guardar el ID del despacho

      setState(() {});

      // Llamar a _loadDetallesDespachoExplo() después de obtener el ID
      if (_despachoId != null) {
        _loadDetallesDespachoMateriales(_despachoId!);
      }
    }
  }

  

  void _loadDetalleDevolucionesMateriales(int DevolucionesId) async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper()
        .getDetalleDevolucionByDevolucionId(DevolucionesId);

    setState(() {
      _detallesDevoluciones =
          detalles.where((d) => d['cantidad'] != null).toList();
      _initializeControllers();
    });
  }

  void _loadDetallesDespachoMateriales(int despachoId) async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper()
        .getDetalleDespachoByDesapachoExposivosyAccesorios(despachoId);

    setState(() {
      _detallesDespacho = detalles.where((d) => d['cantidad'] != null).toList();
    });
  }

  void _initializeControllers() {
    for (var detalle in _detallesDevoluciones) {
      String key = detalle['nombre_material'];
      _controllers[key] =
          TextEditingController(text: detalle['cantidad']?.toString() ?? '');
    }
  }

  Future<Uint8List?> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("Error al cargar la imagen: Código ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error al obtener la imagen: $e");
      return null;
    }
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    Uint8List? firmaBytes;
    if (firmaUsuario != null && firmaUsuario!.isNotEmpty) {
      firmaBytes = await _loadImageFromUrl(firmaUsuario!);
    }

    // Obtener datos desde la base de datos
    List<Map<String, dynamic>> datos =
        await DatabaseHelper().obtenerEstructuraCompleta(widget.exploracionId);

    if (datos.isEmpty) {
      print("No se encontraron datos.");
      return;
    }

    Map<String, dynamic> trabajo = datos.first;

    // Extraer los valores
    String fecha = trabajo['fecha'] ?? '';
    String turno = trabajo['turno'] ?? '';
    String taladro = trabajo['taladro'] ?? '';
    String piesPorTaladro = trabajo['pies_por_taladro'] ?? '';
    String zona = trabajo['zona'] ?? '';
    String tipoLabor = trabajo['tipo_labor'] ?? '';
    String labor = trabajo['labor'] ?? '';
    String veta = trabajo['veta'] ?? '';
    String nivel = trabajo['nivel'] ?? '';
    String tipoPerforacion = trabajo['tipo_perforacion'] ?? '';

    // Obtener despachos y devoluciones
    List<Map<String, dynamic>> despachos = trabajo['despachos'] ?? [];
    List<Map<String, dynamic>> devoluciones = trabajo['devoluciones'] ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO GENERAL
              pw.Text("VALE DE SALIDA - EXPLOSIVOS A LABORES",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              // DATOS GENERALES
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Fecha: $fecha"),
                  pw.Text("Turno: $turno"),
                  pw.Text("Zona: $zona"),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Tipo de Labor: $tipoLabor"),
                  pw.Text("Labor: $labor"),
                  pw.Text("Veta: $veta"),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Nivel: $nivel"),
                  pw.Text("Tipo de Perforación: $tipoPerforacion"),
                  pw.Text("N° Tal Disp: $taladro"),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Pies por Taladro: $piesPorTaladro"),
                ],
              ),

              pw.SizedBox(height: 10),

              // SECCIÓN DESPACHO Y DEVOLUCIONES
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // DESPACHOS
                  _buildSection1(
                    title: "DESPACHOS",
                    data: _extraerDatosExplosivos(despachos),
                  ),

                  pw.SizedBox(width: 16),

                  // DEVOLUCIONES
                  _buildSection1(
                    title: "DEVOLUCIONES",
                    data: _extraerDatosExplosivos(devoluciones),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Tablas de detalles de materiales
              pw.Text("MATERIALES",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: despachos.isNotEmpty
                        ? _buildMaterialesTable(
                            despachos.first['detalles_materiales'] ?? [])
                        : pw.Container(),
                  ),
                  pw.SizedBox(width: 16), // Espacio entre las tablas
                  pw.Expanded(
                    child: devoluciones.isNotEmpty
                        ? _buildMaterialesTable(
                            devoluciones.first['detalles_materiales'] ?? [])
                        : pw.Container(),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Tablas de detalles de explosivos
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: despachos.isNotEmpty
                        ? _buildDetalleTable(
                            despachos.first['detalles_explosivos'] ?? [])
                        : pw.Container(),
                  ),
                  pw.SizedBox(width: 16), // Espacio entre las tablas
                  pw.Expanded(
                    child: devoluciones.isNotEmpty
                        ? _buildDetalleTable(
                            devoluciones.first['detalles_explosivos'] ?? [])
                        : pw.Container(),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // FIRMAS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Firma del Bodeguero
                  pw.Column(
                    children: [
                      if (firmaBytes != null)
                        pw.Image(
                          pw.MemoryImage(firmaBytes),
                          width: 150,
                          height: 100,
                        ),
                      pw.Text(nombreUsuario, style: pw.TextStyle(fontSize: 10)),
                      pw.Text("_______________________"),
                      pw.Text("Firma Bodeguero"),
                    ],
                  ),

                  // Firma del Supervisor (solo línea de firma)
                  pw.Column(
                    children: [
                      pw.SizedBox(
                          height:
                              50), // Espacio similar a la firma del bodeguero
                      pw.Text("_______________________"),
                      pw.Text("Firma Supervisor"),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // GUARDAR PDF
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/vale_salida.pdf");
    await file.writeAsBytes(await pdf.save());
    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exportado correctamente')),
    );
  }

// FUNCIÓN PARA CONVERTIR DATOS DE DESPACHO/DEVOLUCIÓN A MAPA
  Map<String, String> _extraerDatosExplosivos(
      List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) return {};

    Map<String, dynamic> datos = lista.first; // Tomamos solo el primer elemento

    return {
      "Milisegundo": datos["mili_segundo"]?.toString() ?? "0",
      "Medio Segundo": datos["medio_segundo"]?.toString() ?? "0",
      // Otros campos que puedan necesitarse
    };
  }

// FUNCIÓN PARA CREAR SECCIÓN (DESPACHO / DEVOLUCIONES)
  pw.Widget _buildSection1(
      {required String title, required Map<String, String> data}) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          for (var entry in data.entries)
            pw.Text("${entry.key}: ${entry.value}",
                style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

// FUNCIÓN PARA GENERAR TABLA DE DETALLES DE EXPLOSIVOS
  pw.Widget _buildDetalleTable(List<Map<String, dynamic>> detalles) {
    return detalles.isEmpty
        ? pw.Container()
        : pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            columnWidths: {
              0: pw.FlexColumnWidth(0.3),
              1: pw.FlexColumnWidth(2.0),
              2: pw.FlexColumnWidth(2.0),
            },
            children: [
              // ENCABEZADO DE LA TABLA
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildHeaderCell1("N°"),
                  _buildHeaderCell1("Milisegundo (MS)"),
                  _buildHeaderCell1("Medio Segundo (LP)"),
                ],
              ),
              // FILAS DINÁMICAS
              for (var detalle in detalles)
                pw.TableRow(
                  children: [
                    _buildNumberCell1(detalle["numero"] ?? 0),
                    _buildInputCell1(detalle["ms_cant1"] ?? "0"),
                    _buildInputCell1(detalle["lp_cant1"] ?? "0"),
                  ],
                ),
            ],
          );
  }

// FUNCIÓN PARA GENERAR TABLA DE MATERIALES
  pw.Widget _buildMaterialesTable(List<Map<String, dynamic>> materiales) {
    if (materiales.isEmpty) return pw.Container();

    // Dividir los materiales en grupos de 4 para mostrarlos en filas
    List<List<Map<String, dynamic>>> grupos = [];
    for (var i = 0; i < materiales.length; i += 4) {
      grupos.add(materiales.sublist(
          i, i + 4 > materiales.length ? materiales.length : i + 4));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(1.0),
      },
      children: [
        // FILAS DINÁMICAS SIN ENCABEZADO
        for (var grupo in grupos) ...[
          // FILA DE NOMBRES
          pw.TableRow(
            children: [
              for (var material in grupo)
                _buildInputCell1(material["nombre_material"] ?? ""),
              for (var i = grupo.length;
                  i < 4;
                  i++) // Celdas vacías si faltan materiales
                _buildInputCell1(""),
            ],
          ),
          // FILA DE CANTIDADES
          pw.TableRow(
            children: [
              for (var material in grupo)
                _buildInputCell1("${material["cantidad"] ?? "0"}"),
              for (var i = grupo.length;
                  i < 4;
                  i++) // Celdas vacías si faltan cantidades
                _buildInputCell1(""),
            ],
          ),
          // Línea separadora (opcional)
          pw.TableRow(
            children: List.generate(
                4, (index) => pw.Container(height: 1, color: PdfColors.grey)),
          ),
        ],
      ],
    );
  }

// FUNCIÓN PARA CELDAS DE ENCABEZADO
  pw.Widget _buildHeaderCell1(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

// FUNCIÓN PARA CELDAS NUMÉRICAS
  pw.Widget _buildNumberCell1(dynamic number) {
    int num = number is int ? number : int.tryParse(number.toString()) ?? 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        num.toString(),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8),
      ),
    );
  }

// FUNCIÓN PARA CELDAS DE ENTRADA
  pw.Widget _buildInputCell1(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8),
      ),
    );
  }

//-------------------------------------------------------------------------------------------------------

  // Carga los detalles de Devoluciones desde la BD y actualiza los controladores correspondientes.
  void _loadDetallesDevolucionesExplo(int DevolucionesId) async {
    List<Map<String, dynamic>> detalles = await DatabaseHelper()
        .getDetalleDevolucionesByDevolucionesId(DevolucionesId);

    for (var detail in detalles) {
      int numero = detail['numero'];
      if (numero >= 1 && numero <= 20) {
        _controllers['msCant1_$numero']?.text = detail['ms_cant1'] ?? "";
        _controllers['lpCant1_$numero']?.text = detail['lp_cant1'] ?? "";
      }
    }

    setState(() {});
  }

  Future<bool> _actualizarDevoluciones() async {
    if (_DevolucionesId == null) {
      throw Exception('No hay un Devoluciones para actualizar');
    }

    Map<String, dynamic> updatedData = {};

    int result = await DatabaseHelper()
        .updateDevoluciones(_DevolucionesId!, updatedData);
    if (result > 0) {
      return true; // Éxito
    } else {
      throw Exception('Error al actualizar el Devoluciones');
    }
  }

  Future<void> _actualizarTodosLosDetalles() async {
    try {
      if (_detallesDevoluciones.isEmpty) return;

      List<Future<void>> actualizaciones = [];

      for (var detalle in _detallesDevoluciones) {
        int id = detalle['id']; // ID de la devolución
        String key = detalle['nombre_material'];
        String cantidadStr =
            _controllers[key]?.text ?? ""; // Cantidad ingresada
        double cantidadDevolucion = double.tryParse(cantidadStr) ?? 0.0;

        // Buscar la cantidad despachada correspondiente
        var detalleDespacho = _detallesDespacho.firstWhere(
          (d) => d['nombre_material'] == key,
          orElse: () => {},
        );

        double cantidadDespachada = double.tryParse(detalleDespacho.isNotEmpty
                ? detalleDespacho['cantidad'].toString()
                : "0") ??
            0.0;

        // Verificar si la devolución es mayor que el despacho
        if (cantidadDevolucion > cantidadDespachada) {
          // Mostrar notificación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Error: $key tiene una devolución mayor al despacho."),
              backgroundColor: Colors.red,
            ),
          );
          continue; // No actualizar este detalle
        }

        // Si la cantidad es válida, agregar la actualización a la lista
        if (cantidadStr.isNotEmpty) {
          actualizaciones.add(
            DatabaseHelper()
                .updateDevolucionDetalle(id, {'cantidad': cantidadStr}),
          );
        }
      }

      await Future.wait(actualizaciones);
      print("Todos los detalles de la devolución fueron actualizados.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Error al actualizar detalles: $e"),
    backgroundColor: Colors.red,
  ),
);
    }
  }

  Future<void> _actualizarEstadoEnProceso() async {
    if (widget.exploracionId > 0) {
      // Verifica que sea un ID válido
      await DatabaseHelper()
          .updateEstadoExploracion(widget.exploracionId, 'Finalizado');

      // 🔹 Notificar al padre que el estado se actualizó
      if (widget.onEstadoActualizado != null) {
        widget.onEstadoActualizado!();
      }
    }
  }

  Future<void> _actualizarTiempos() async {
  if (_DevolucionesId == null) {
    throw Exception('No se encontró un ID de despacho');
  }

  final selectedMs = _getSelectedMsOption();
  final selectedLp = _getSelectedLpOption();

  double? ms = selectedMs != null ? double.tryParse(selectedMs) : null;
  double? lp = selectedLp != null ? double.tryParse(selectedLp) : null;

  if (ms == null && lp == null) return;

  int filasActualizadas = await DatabaseHelper().actualizarTiemposDevoluciones(
    _DevolucionesId!,
    ms,
    lp,
  );

  if (filasActualizadas > 0) {
    print('Tiempos actualizados correctamente: MS=$ms, LP=$lp');
  }
}

  void _mostrarDialogoConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar cierre'),
          content:
              const Text('¿Estás seguro de que deseas cerrar este registro?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // Cerrar sin hacer nada
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar diálogo

                // 🔹 Llamar directamente a la función en DatabaseHelper
                await DatabaseHelper().cerrarRegistro(widget.exploracionId);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Registro cerrado correctamente')),
                );

                // 🔹 Notificar al padre si es necesario
                if (widget.onEstadoActualizado != null) {
                  widget.onEstadoActualizado!();
                }
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

Future<bool> _guardarFormulario() async {
  if (_DevolucionesId == null) {
    throw Exception('No se encontró un ID de Devoluciones');
  }

  // Obtener los detalles del despacho correspondiente
  List<Map<String, dynamic>> detallesDespacho =
      await DatabaseHelper().getDetalleDespachoByDespachoId(_despachoId!);

  // Convertir detalles de despacho en un mapa para acceso rápido
  Map<int, Map<String, dynamic>> despachoMap = {};
  for (var detalle in detallesDespacho) {
    despachoMap[detalle['numero']] = detalle;
  }

  List<Map<String, dynamic>> detalles = [];

  for (int i = 1; i <= 20; i++) {
    final msCant1 = _controllers['msCant1_$i']!.text;
    final lpCant1 = _controllers['lpCant1_$i']!.text;

    if (msCant1.isNotEmpty || lpCant1.isNotEmpty) {
      double msDevolucion = double.tryParse(msCant1) ?? 0;
      double lpDevolucion = double.tryParse(lpCant1) ?? 0;

      double msDespacho = double.tryParse(despachoMap[i]?['ms_cant1'] ?? "0") ?? 0;
      double lpDespacho = double.tryParse(despachoMap[i]?['lp_cant1'] ?? "0") ?? 0;

      // Validar que la devolución no sea mayor que el despacho
      if (msDevolucion > msDespacho) {
        throw Exception('Error en : La cantidad de devolución en el número $i es mayor que la del despacho.');
      }
      if (lpDevolucion > lpDespacho) {
        throw Exception('Error en Medio Segundo: La cantidad de devolución en el número $i es mayor que la del despacho.');
      }

      detalles.add({
        'numero': i,
        'ms_cant1': msCant1,
        'lp_cant1': lpCant1,
      });
    }
  }

  if (detalles.isNotEmpty) {
    await DatabaseHelper().insertDetallesDevoluciones(_DevolucionesId!, detalles);
    return true; // Éxito
  } else {
    throw Exception('No hay datos para guardar en el formulario');
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0), // Reducido
                child: TextFormField(
                  controller: controller,
                  style: TextStyle(fontSize: 12), // Texto más pequeño
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_registroCerrado,
                  decoration: InputDecoration(
                    hintText: 'Cant',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 4, horizontal: 6), // Reducido
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
                      onPressed: () => onTap(option),
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

  Future<void> _actualizarObservaciones() async {
  if (_DevolucionesId == null) {
    throw Exception('No se encontró un ID de despacho');
  }

  final observaciones = _observacionesController.text.trim();

  if (observaciones.isEmpty) return; // No actualiza si está vacío

  await DatabaseHelper().actualizarDetalleDevolucion(_DevolucionesId!, observaciones);

  print("Observaciones actualizadas correctamente.");
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
    (_detallesDevoluciones.length / 2).ceil(),
    (index) {
      int startIndex = index * 2;
      int endIndex = startIndex + 2;
      List detallesFila = _detallesDevoluciones.sublist(
        startIndex,
        endIndex > _detallesDevoluciones.length
            ? _detallesDevoluciones.length
            : endIndex,
      );

      return Row(
        children: detallesFila.map((detalle) {
          String key = detalle['nombre_material'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextFormField(
                enabled: !_registroCerrado, // ← Aquí se desactiva si el registro está cerrado
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: detalle['nombre_material'],
                  border: const OutlineInputBorder(),
                  filled: _registroCerrado, // Opcional: cambia el fondo si está desactivado
                  fillColor: _registroCerrado ? Colors.grey[200] : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
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
              // Observaciones
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // Botón para guardar
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // Ajusta el tamaño del Row a su contenido
                  children: [
                    ElevatedButton(
                      onPressed: _registroCerrado
                          ? null
                          : () async {
                              try {
                                await Future.wait([
                                  _actualizarTodosLosDetalles(),
                                  _guardarFormulario(),
                                  _actualizarObservaciones(),
                                  // _actualizarDevoluciones(),
                                  _actualizarEstadoEnProceso(),
                                  _actualizarTiempos(),
                                ]);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Se guardaron correctamente')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: ${e.toString()}')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _registroCerrado
                            ? Colors.grey
                            : Colors.blue, // ⚠️ Cambia color si está cerrado
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          _registroCerrado ? 'Registro Cerrado' : 'Guardar'),
                    ),

                    const SizedBox(width: 10), // Espaciado entre los botones
                    ElevatedButton(
                      onPressed: () async {
                        await generatePdf();
                      },
                      child: const Text('Exportar'),
                    ),
                    const SizedBox(width: 10), // Espaciado entre los botones
                    ElevatedButton(
                      onPressed: _registroCerrado
                          ? null
                          : () {
                              _mostrarDialogoConfirmacion(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _registroCerrado
                            ? Colors.grey
                            : Colors.blue, // Cambia color si está cerrado
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_registroCerrado
                          ? 'Registro Cerrado'
                          : 'Cerrar Registro'),
                    ),
                  ],
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
