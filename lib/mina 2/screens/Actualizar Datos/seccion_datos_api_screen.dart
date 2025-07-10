import 'dart:convert';

import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Largo/detalle_largo_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Explosivos/detalle_explosivos_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Horizontal/detalle_horizontal_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Largo/detalle_largo_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Mediciones/horizontal/detalle_mediciones_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Mediciones/largo/detalle_mediciones_screen.dart';
import 'package:app_seminco/mina%202/screens/Actualizar%20Datos/Sostenimiento/detalle_sostenimiento_screen.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/operacion_service.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/operacion_service.dart';
import 'package:flutter/material.dart';

class SeccionesScreen extends StatefulWidget {
  @override
  _SeccionesScreenState createState() => _SeccionesScreenState();
}

class _SeccionesScreenState extends State<SeccionesScreen> {
  final Map<String, Widget Function(BuildContext)> _pantallas = {
    "PERFORACIÓN TALADROS LARGOS": (context) =>
        DetalleSeccionScreen(tipoOperacion: "PERFORACIÓN TALADROS LARGOS"),
    "PERFORACIÓN HORIZONTAL": (context) =>
        DetalleHorizontalScreen(tipoOperacion: "PERFORACIÓN HORIZONTAL"),
    "SOSTENIMIENTO": (context) =>
        DetalleSostenimientoScreen(tipoOperacion: "SOSTENIMIENTO"),
    "EXPLOSIVOS": (context) => DetalleExplosivos(tipoOperacion: "EXPLOSIVOS"),
    "MEDICIONES TAL. HORIZONTAL": (context) => ListaMedicionesScreen(tipoPerforacion: "MEDICIONES TAL. HORIZONTAL"),
    "MEDICIONES TAL. LARGO": (context) => ListaMedicionesLargoScreen(tipoPerforacion: "MEDICIONES TAL. LARGO"),
  };

  final List<String> _secciones = [
    "PERFORACIÓN TALADROS LARGOS",
    "PERFORACIÓN HORIZONTAL",
    "SOSTENIMIENTO",
    "EXPLOSIVOS",
    "MEDICIONES",
    "CARGUÍO",
    "MEDICIONES TAL. HORIZONTAL",
    "MEDICIONES TAL. LARGO"
  ];

  Map<String, bool> _seccionesExpandida = {};
  Map<String, List<Map<String, dynamic>>> operacionesPorSeccion = {};
  //id
  Set<int> idsTaladroLargo = {};
  Set<int> idsSostenimiento = {};
  Set<int> idsHorizontal = {};
  Set<int> idsExplosivos = {};
  Set<int> idsMediciones = {};
  List<Map<String, dynamic>> operacionDataLargo = [];
  List<Map<String, dynamic>> operacionDataHorizontal = [];
  List<Map<String, dynamic>> operacionDataSostenimiento = [];
  List<Map<String, dynamic>> operacionDataExplosi = [];
  List<Map<String, dynamic>> operacionDataMediciones = [];

  bool isLoading = true;
  String mensajeUsuario = "Cargando registros...";

  @override
  void initState() {
    super.initState();
    _seccionesExpandida = {for (var seccion in _pantallas.keys) seccion: false};
    _fetchOperacionDataLargo();
    _fetchOperacionDataHorizontal();
    _fetchExploracionesDataExplo();
    // _fetchMedicionesDataExplo();
    _fetchOperacionDataSostenimiento();
  }

  Future<void> _fetchOperacionDataLargo() async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> data = await dbHelper
        .getOperacionBytipoOperacion("PERFORACIÓN TALADROS LARGOS");

    print('Datos recibidos de la base de datos: $data');

    if (data.isNotEmpty) {
      setState(() {
        operacionDataLargo = data;
      });
    } else {
      setState(() {
        mensajeUsuario = "No se encontraron registros.";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchOperacionDataHorizontal() async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> data =
        await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN HORIZONTAL");

    print('Datos recibidos de la base de datos: $data');

    if (data.isNotEmpty) {
      setState(() {
        operacionDataHorizontal = data;
        isLoading = false;
      });
    } else {
      setState(() {
        mensajeUsuario = "No se encontraron registros.";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchOperacionDataSostenimiento() async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> data =
        await dbHelper.getOperacionBytipoOperacion("SOSTENIMIENTO");

    print('Datos recibidos de la base de datos: $data');

    if (data.isNotEmpty) {
      setState(() {
        operacionDataSostenimiento = data;
        isLoading = false;
      });
    } else {
      setState(() {
        mensajeUsuario = "No se encontraron registros.";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchExploracionesDataExplo() async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> data = await dbHelper.getExploraciones();

    print('Datos de exploraciones recibidos: $data');

    if (data.isNotEmpty) {
      setState(() {
        operacionDataExplosi = data;
        isLoading = false;
      });
    } else {
      setState(() {
        mensajeUsuario = "No se encontraron registros de exploraciones.";
        isLoading = false;
      });
    }
  }

  //  Future<void> _fetchMedicionesDataExplo() async {
  //   DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  //   List<Map<String, dynamic>> data = await dbHelper.obtenerPerforacionesConDetalles();

  //   print('Datos de Mediciones recibidos: $data');

  //   if (data.isNotEmpty) {
  //     setState(() {
  //       operacionDataMediciones = data;
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       mensajeUsuario = "No se encontraron registros de Mediciones.";
  //       isLoading = false;
  //     });
  //   }
  // }

  void _mostrarDialogo(BuildContext context) async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

    // Limpiar las estructuras antes de llenarlas
    operacionesPorSeccion.clear();
    idsTaladroLargo.clear();
    idsSostenimiento.clear();
    idsHorizontal.clear();
    idsExplosivos.clear();
    idsMediciones.clear();

    for (var seccion in _pantallas.keys) {
      List<Map<String, dynamic>> datos;

      if (seccion == "EXPLOSIVOS") {
        datos = await dbHelper.getExploracionesPendientes();
      }
    //   else if (seccion == "MEDICIONES") {
    //   datos = await dbHelper.getMedicionesPendientes(); // Necesitarás implementar este método
    // }
    else {
        datos = await dbHelper.getOperacionPendienteByTipo(seccion);
        print("Datos recibidos para $seccion: $datos");

      }

      // Guardar los datos completos
      operacionesPorSeccion[seccion] = datos;

      // Guardar solo los IDs en Sets según la sección
      for (var operacion in datos) {
        int id = operacion['id'] as int;
        if (seccion == "PERFORACIÓN TALADROS LARGOS") {
          idsTaladroLargo.add(id);
        } else if (seccion == "SOSTENIMIENTO") {
          idsSostenimiento.add(id);
        } else if (seccion == "PERFORACIÓN HORIZONTAL") {
          idsHorizontal.add(id);
        } else if (seccion == "EXPLOSIVOS") {
          idsExplosivos.add(id);
        } else if (seccion == "MEDICIONES") {
        idsMediciones.add(id);
      }
      }
    }

    print("Taladro Largo IDs: $idsTaladroLargo");
    print("Sostenimiento IDs: $idsSostenimiento");
    print("Horizontal IDs: $idsHorizontal");
    print("Explosivos IDs: $idsExplosivos");
 print("Mediciones IDs: $idsMediciones");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Operaciones Pendientes por Sección",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _pantallas.keys.map((seccion) {
                      var operaciones = operacionesPorSeccion[seccion] ?? [];
                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(seccion,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${operaciones.length}",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        children: operaciones.map((operacion) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: seccion == "EXPLOSIVOS"
                                  ? [
                                      Text("Fecha: ${operacion['fecha']}",
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Turno: ${operacion['turno']}",
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Taladro: ${operacion['taladro']}",
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Zona: ${operacion['zona']}",
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Labor: ${operacion['labor']}",
                                          style: TextStyle(fontSize: 14)),
                                      SizedBox(width: 10),
                                      Text("Estado: ${operacion['estado']}",
                                          style: TextStyle(fontSize: 14)),
                                    ]
                                    : seccion == "MEDICIONES"
                                    ? [
                                        Text("Mes: ${operacion['mes']}",
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 10),
                                        Text("Semana: ${operacion['semana']}",
                                            style: TextStyle(fontSize: 14)),
                                        SizedBox(width: 10),
                                        Text("Tipo perforacion: ${operacion['tipo_perforacion']}",
                                            style: TextStyle(fontSize: 14)),
                                      ]
                                  : [
                                      Text("Fecha: ${operacion['fecha']}",
                                          style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 10),
                                      Text("Turno: ${operacion['turno']}",
                                          style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 10),
                                      Text("Equipo: ${operacion['equipo']}",
                                          style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 10),
                                      Text("Código: ${operacion['codigo']}",
                                          style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 10),
                                      Text("Empresa: ${operacion['empresa']}",
                                          style: TextStyle(fontSize: 15)),
                                      SizedBox(width: 10),
                                      Text("Estado: ${operacion['estado']}",
                                          style: TextStyle(fontSize: 15)),
                                          SizedBox(width: 10),
                                      Text("idNube: ${operacion['idNube']}",
                                          style: TextStyle(fontSize: 14)),
                                    ],
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cerrar"),
                  ),
                  ElevatedButton(
                    onPressed: () => ejecutarEnviosSecuencialmente(context),
                    child: const Text('Enviar todo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> ejecutarEnviosSecuencialmente(BuildContext dialogContext) async {
    try {
      bool algunEnvioRealizado = false;
      String mensajeResultado = '';

      if (idsTaladroLargo.isNotEmpty) {
        await _exportSelectedItemsLargo();
        algunEnvioRealizado = true;
        mensajeResultado += '- Datos de Taladro Largo enviados\n';
      }

      if (idsHorizontal.isNotEmpty) {
        await _exportSelectedItemsHorizontal();
        algunEnvioRealizado = true;
        mensajeResultado += '- Datos de Perforación Horizontal enviados\n';
      }

      if (idsSostenimiento.isNotEmpty) {
        await _exportSelectedItemsSostenimiento();
        algunEnvioRealizado = true;
        mensajeResultado += '- Datos de Sostenimiento enviados\n';
      }

      if (idsExplosivos.isNotEmpty) {
        await _exportSelectedItemsExplo();
        algunEnvioRealizado = true;
        mensajeResultado += '- Datos de Explosivos enviados\n';
      }

    //   if (idsMediciones.isNotEmpty) {
    //   await _exportSelectedItemsMediciones();
    //   algunEnvioRealizado = true;
    //   mensajeResultado += '- Datos de Mediciones enviados\n';
    // }

      // Cerrar el diálogo padre
      Navigator.of(dialogContext).pop();

      // Mostrar resultado al usuario
      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title:
              Text(algunEnvioRealizado ? 'Proceso completado' : 'Información'),
          content: Text(
            mensajeResultado.isNotEmpty
                ? mensajeResultado
                : 'No se encontraron datos pendientes para enviar en ninguna sección.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(dialogContext).pop(); // Cierra el diálogo padre si hay error

      showDialog(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Ocurrió un error durante el envío: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Secciones de Perforación"),
        backgroundColor: Color(0xFF21899C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seleccione una sección",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _secciones.length,
                itemBuilder: (context, index) {
                  String seccion = _secciones[index];
                  bool tienePantalla = _pantallas.containsKey(seccion);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        if (tienePantalla) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: _pantallas[seccion]!,
                            ),
                          );
                        } else {
                          _mostrarDialogo(context);
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: tienePantalla
                              ? Colors.blue[100]
                              : Colors.grey[300],
                          border: Border.all(
                              color: tienePantalla ? Colors.blue : Colors.grey,
                              width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            seccion,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: tienePantalla
                                  ? Colors.blue[900]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _mostrarDialogo(context),
                child: Text("Enviar Datos"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Color(0xFF21899C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //LARGO------------------------------------------------------------------------------------------------------------

Future<void> _exportSelectedItemsLargo() async {
  print('IDs recibidos en _exportItemsLargo: $idsTaladroLargo');
  if (idsTaladroLargo.isEmpty) return;

  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> jsonDataParaCrear = [];
  List<Map<String, dynamic>> jsonDataParaActualizar = [];

  for (var id in idsTaladroLargo) {
    var operacion = operacionDataLargo.firstWhere((op) => op['id'] == id);
    List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(id);
    List<Map<String, dynamic>> perforaciones = await dbHelper.getPerforacionesTaladroLargo(id);

    List<Map<String, dynamic>> interPerforaciones = [];
    for (var perforacion in perforaciones) {
      int perforacionId = perforacion['id'];
      List<Map<String, dynamic>> interData = await dbHelper.getInterPerforacionesTaladroLargo(perforacionId);
      interPerforaciones.addAll(interData);
    }

    List<Map<String, dynamic>> horometros = await dbHelper.getHorometrosByOperacion(id);

    Map<String, dynamic> operacionSinId = {
      "turno": operacion['turno'],
      "equipo": operacion['equipo'],
      "codigo": operacion['codigo'],
      "empresa": operacion['empresa'],
      "fecha": operacion['fecha'],
      "tipo_operacion": operacion['tipo_operacion'],
      "estado": operacion['estado']
    };

    List<Map<String, dynamic>> estadosLimpios = estados.map((estado) {
      return {
        "numero": estado['numero'],
        "estado": estado['estado'],
        "codigo": estado['codigo'],
        "hora_inicio": estado['hora_inicio'],
        "hora_final": estado['hora_final']
      };
    }).toList();

    List<Map<String, dynamic>> perforacionesLimpias = perforaciones.map((perforacion) {
      int pId = perforacion['id'];
      return {
        "zona": perforacion['zona'],
        "tipo_labor": perforacion['tipo_labor'],
        "labor": perforacion['labor'],
        "ala": perforacion['ala'],
        "veta": perforacion['veta'],
        "nivel": perforacion['nivel'],
        "tipo_perforacion": perforacion['tipo_perforacion'],
        "inter_perforaciones": interPerforaciones
            .where((ip) => ip['perforaciontaladrolargo_id'] == pId)
            .map((ip) {
          return {
            "codigo_actividad": ip['codigo_actividad'],
            "nivel": ip['nivel'],
            "tajo": ip['tajo'],
            "nbroca": ip['nbroca'],
            "ntaladro": ip['ntaladro'],
            "nbarras": ip['nbarras'] ?? 0,
            "longitud_perforacion": ip['longitud_perforacion'],
            "angulo_perforacion": ip['angulo_perforacion'],
            "nfilas_de_hasta": ip['nfilas_de_hasta'] ?? "",
            "detalles_trabajo_realizado": ip['detalles_trabajo_realizado'] ?? ""
          };
        }).toList()
      };
    }).toList();

    List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
      return {
        "nombre": h['nombre'],
        "inicial": h['inicial'],
        "final": h['final']
      };
    }).toList();

    Map<String, dynamic> operacionCompleta = {
      "local_id": id,
      "operacion": operacionSinId,
      "estados": estadosLimpios,
      "perforaciones": perforacionesLimpias,
      "horometros": horometrosLimpios,
    };

    // Verificar si tiene idNube para decidir si es creación o actualización
    if (operacion['idNube'] == null) {
      jsonDataParaCrear.add(operacionCompleta);
    } else {
      // Agregar el idNube al objeto operacion para la actualización
      operacionCompleta['operacion']['id'] = operacion['idNube'];
      jsonDataParaActualizar.add(operacionCompleta);
    }
  }

  await _enviarDatosALaNubeLargo(jsonDataParaCrear, jsonDataParaActualizar);
}

Future<void> _enviarDatosALaNubeLargo(
  List<Map<String, dynamic>> jsonDataParaCrear,
  List<Map<String, dynamic>> jsonDataParaActualizar,
) async {
  final operacionService = OperacionService();
  bool allSuccess = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Procesar operaciones para crear
    for (var operacion in jsonDataParaCrear) {
      int localId = operacion['local_id'];
      print('Creando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final idsNube = await operacionService.crearOperacionLargo(operacionSinLocalId);

      if (idsNube != null && idsNube.isNotEmpty) {
        final idNube = idsNube.length == 1 ? idsNube.first : idsNube[0];
        await _actualizarIdNubeOperacion(localId, idNube);
        
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      } else {
        allSuccess = false;
        print('Error al crear operación con ID local: $localId');
      }
    }

    // Procesar operaciones para actualizar
    for (var operacion in jsonDataParaActualizar) {
      int localId = operacion['local_id'];
      print('Actualizando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final success = await operacionService.actualizarOperacionLargo(operacionSinLocalId);

      if (!success) {
        allSuccess = false;
        print('Error al actualizar operación con ID local: $localId');
      } else {
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      }
    }
  } catch (e) {
    allSuccess = false;
    print('Error durante el envío: $e');
  }

  if (mounted) {
    Navigator.of(context).pop();
    
    // Mostrar resultado al usuario
    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos enviados exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo errores al enviar algunos datos')),
      );
    }
  }
}

//BD local envio------------------------------------------------------------------------------------------------------------

Future<int> _actualizarEnvio(int operacionId) async {
  print('operacionId recibido: $operacionId'); // <-- Agrega este print
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  return await dbHelper.actualizarEnvio(operacionId);
}

Future<int> _actualizarEnvioParciales(int operacionId) async {
  print('operacionId recibido: $operacionId'); // <-- Agrega este print
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  return await dbHelper.actualizarEnvioParcial(operacionId);
}

// Nuevo método para actualizar el ID nube
Future<int> _actualizarIdNubeOperacion(int idOperacion, int idNube) async {
  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  return await dbHelper.actualizarIdNubeOperacion(idOperacion, idNube);
}

//HORIZONTAL------------------------------------------------------------------------------------------------------------

Future<void> _exportSelectedItemsHorizontal() async {
  print('IDs recibidos en _exportItemsHorizontal: $idsHorizontal');
  if (idsHorizontal.isEmpty) return;

  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> jsonDataParaCrear = [];
  List<Map<String, dynamic>> jsonDataParaActualizar = [];

  for (var id in idsHorizontal) {
    var operacion = operacionDataHorizontal.firstWhere((op) => op['id'] == id);
    List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(id);
    List<Map<String, dynamic>> perforaciones = await dbHelper.getPerforacionesTaladroHorizontal(id);

    List<Map<String, dynamic>> interPerforaciones = [];
    for (var perforacion in perforaciones) {
      int perforacionId = perforacion['id'];
      List<Map<String, dynamic>> interData = await dbHelper.getInterPerforacionesHorizontal(perforacionId);
      interPerforaciones.addAll(interData);
    }

    List<Map<String, dynamic>> horometros = await dbHelper.getHorometrosByOperacion(id);

    Map<String, dynamic> operacionSinId = {
      "turno": operacion['turno'],
      "equipo": operacion['equipo'],
      "codigo": operacion['codigo'],
      "empresa": operacion['empresa'],
      "fecha": operacion['fecha'],
      "tipo_operacion": operacion['tipo_operacion'],
      "estado": operacion['estado']
    };

    List<Map<String, dynamic>> estadosLimpios = estados.map((estado) {
      return {
        "numero": estado['numero'],
        "estado": estado['estado'],
        "codigo": estado['codigo'],
        "hora_inicio": estado['hora_inicio'],
        "hora_final": estado['hora_final']
      };
    }).toList();

    List<Map<String, dynamic>> perforacionesLimpias = perforaciones.map((perforacion) {
      int pId = perforacion['id'];
      return {
        "zona": perforacion['zona'],
        "tipo_labor": perforacion['tipo_labor'],
        "labor": perforacion['labor'],
        "veta": perforacion['veta'],
        "nivel": perforacion['nivel'],
        "tipo_perforacion": perforacion['tipo_perforacion'],
        "inter_perforaciones": interPerforaciones
            .where((ip) => ip['perforacionhorizontal_id'] == pId)
            .map((ip) {
          return {
            "codigo_actividad": ip['codigo_actividad'],
            "nivel": ip['nivel'],
            "labor": ip['labor'],
            "seccion_la_labor": ip['seccion_la_labor'],
            "nbroca": ip['nbroca'],
            "ntaladro": ip['ntaladro'],
            "ntaladros_rimados": ip['ntaladros_rimados'],
            "longitud_perforacion": ip['longitud_perforacion'],
            "detalles_trabajo_realizado": ip['detalles_trabajo_realizado'] ?? ""
          };
        }).toList()
      };
    }).toList();

    List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
      return {
        "nombre": h['nombre'],
        "inicial": h['inicial'],
        "final": h['final']
      };
    }).toList();

    Map<String, dynamic> operacionCompleta = {
      "local_id": id,
      "operacion": operacionSinId,
      "estados": estadosLimpios,
      "perforaciones": perforacionesLimpias,
      "horometros": horometrosLimpios,
    };

    if (operacion['idNube'] == null) {
      jsonDataParaCrear.add(operacionCompleta);
    } else {
      operacionCompleta['operacion']['id'] = operacion['idNube'];
      jsonDataParaActualizar.add(operacionCompleta);
    }
  }

  await _enviarDatosALaNubeHorizo(jsonDataParaCrear, jsonDataParaActualizar);
}


  Future<void> _enviarDatosALaNubeHorizo(
      List<Map<String, dynamic>> jsonDataParaCrear,
  List<Map<String, dynamic>> jsonDataParaActualizar,
) async {
  final operacionService = OperacionService();
  bool allSuccess = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Procesar operaciones para crear
    for (var operacion in jsonDataParaCrear) {
      int localId = operacion['local_id'];
      print('Creando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final idsNube = await operacionService.crearOperacionHorizontal(operacionSinLocalId);

      if (idsNube != null && idsNube.isNotEmpty) {
        final idNube = idsNube.length == 1 ? idsNube.first : idsNube[0];
        await _actualizarIdNubeOperacion(localId, idNube);
        
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      } else {
        allSuccess = false;
        print('Error al crear operación con ID local: $localId');
      }
    }

    // Procesar operaciones para actualizar
    for (var operacion in jsonDataParaActualizar) {
      int localId = operacion['local_id'];
      print('Actualizando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final success = await operacionService.actualizarOperacionHorizontal(operacionSinLocalId);

      if (!success) {
        allSuccess = false;
        print('Error al actualizar operación con ID local: $localId');
      } else {
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      }
    }
  } catch (e) {
    allSuccess = false;
    print('Error durante el envío: $e');
  }

  if (mounted) {
    Navigator.of(context).pop();
    
    // Mostrar resultado al usuario
    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos enviados exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo errores al enviar algunos datos')),
      );
    }
  }
}

//SOSTENIMIENTO------------------------------------------------------------------------------------------------------------
Future<void> _exportSelectedItemsSostenimiento() async {
  if (idsSostenimiento.isEmpty) return;

  DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
  List<Map<String, dynamic>> jsonDataParaCrear = [];
  List<Map<String, dynamic>> jsonDataParaActualizar = [];

  for (var id in idsSostenimiento) {
    var operacion = operacionDataSostenimiento.firstWhere((op) => op['id'] == id);
    List<Map<String, dynamic>> estados = await dbHelper.getEstadosByOperacionId(id);
    List<Map<String, dynamic>> perforaciones = await dbHelper.getPerforacionesTaladroSostenimiento(id);

    List<Map<String, dynamic>> interPerforaciones = [];
    for (var perforacion in perforaciones) {
      int perforacionId = perforacion['id'];
      List<Map<String, dynamic>> interData = await dbHelper.getInterSostenimientos(perforacionId);
      interPerforaciones.addAll(interData);
    }

    List<Map<String, dynamic>> horometros = await dbHelper.getHorometrosByOperacion(id);

    Map<String, dynamic> operacionSinId = {
      "turno": operacion['turno'],
      "equipo": operacion['equipo'],
      "codigo": operacion['codigo'],
      "empresa": operacion['empresa'],
      "fecha": operacion['fecha'],
      "tipo_operacion": operacion['tipo_operacion'],
      "estado": operacion['estado'] ?? 'activo'
    };

    List<Map<String, dynamic>> estadosLimpios = estados.map((estado) {
      return {
        "numero": estado['numero'],
        "estado": estado['estado'],
        "codigo": estado['codigo'],
        "hora_inicio": estado['hora_inicio'],
        "hora_final": estado['hora_final']
      };
    }).toList();

    List<Map<String, dynamic>> sostenimientosLimpios = perforaciones.map((perforacion) {
      int pId = perforacion['id'];
      return {
        "zona": perforacion['zona'],
        "tipo_labor": perforacion['tipo_labor'],
        "labor": perforacion['labor'],
        "ala": perforacion['ala'],
        "veta": perforacion['veta'],
        "nivel": perforacion['nivel'],
        "tipo_perforacion": perforacion['tipo_perforacion'],
        "inter_sostenimientos": interPerforaciones
            .where((ip) => ip['sostenimiento_id'] == pId)
            .map((ip) {
          return {
            "codigo_actividad": ip['codigo_actividad'],
            "nivel": ip['nivel'],
            "labor": ip['labor'],
            "seccion_de_labor": ip['seccion_de_labor'],
            "nbroca": ip['nbroca'],
            "ntaladro": ip['ntaladro'],
            "longitud_perforacion": ip['longitud_perforacion'],
            "malla_instalada": ip['malla_instalada'] ?? false
          };
        }).toList()
      };
    }).toList();

    List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
      return {
        "nombre": h['nombre'],
        "inicial": h['inicial'],
        "final": h['final']
      };
    }).toList();

    Map<String, dynamic> operacionCompleta = {
      "local_id": id,
      "operacion": operacionSinId,
      "estados": estadosLimpios,
      "sostenimientos": sostenimientosLimpios,
      "horometros": horometrosLimpios,
    };

    if (operacion['idNube'] == null) {
      jsonDataParaCrear.add(operacionCompleta);
    } else {
      operacionCompleta['operacion']['id'] = operacion['idNube'];
      jsonDataParaActualizar.add(operacionCompleta);
    }
  }

  await _enviarDatosALaNubeSostenimiento(jsonDataParaCrear, jsonDataParaActualizar);
}

  Future<void> _enviarDatosALaNubeSostenimiento(

      List<Map<String, dynamic>> jsonDataParaCrear,
  List<Map<String, dynamic>> jsonDataParaActualizar,
) async {
  final operacionService = OperacionService();
  bool allSuccess = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Procesar operaciones para crear
    for (var operacion in jsonDataParaCrear) {
      int localId = operacion['local_id'];
      print('Creando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final idsNube = await operacionService.crearOperacionSostenimiento(operacionSinLocalId);

      if (idsNube != null && idsNube.isNotEmpty) {
        final idNube = idsNube.length == 1 ? idsNube.first : idsNube[0];
        await _actualizarIdNubeOperacion(localId, idNube);
        
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      } else {
        allSuccess = false;
        print('Error al crear operación con ID local: $localId');
      }
    }

    // Procesar operaciones para actualizar
    for (var operacion in jsonDataParaActualizar) {
      int localId = operacion['local_id'];
      print('Actualizando en la nube operacion con ID local: $localId');

      final operacionSinLocalId = Map<String, dynamic>.from(operacion);
      operacionSinLocalId.remove('local_id');

      final success = await operacionService.actualizarOperacionSostenimiento(operacionSinLocalId);

      if (!success) {
        allSuccess = false;
        print('Error al actualizar operación con ID local: $localId');
      } else {
        // Determinar qué función de actualización usar según el estado
        if (operacion['operacion']['estado'] == 'cerrado') {
          await _actualizarEnvio(localId);
        } else {
          await _actualizarEnvioParciales(localId);
        }
      }
    }
  } catch (e) {
    allSuccess = false;
    print('Error durante el envío: $e');
  }

  if (mounted) {
    Navigator.of(context).pop();
    
    // Mostrar resultado al usuario
    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos enviados exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo errores al enviar algunos datos')),
      );
    }
  }
}
//EXPLOSIVOS--------------------------------------------------------------------------------------------------------------------------------

  Future<void> _exportSelectedItemsExplo() async {
    if (idsExplosivos.isEmpty) return;

    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    List<Map<String, dynamic>> jsonData = [];

    for (var id in idsExplosivos) {
      List<Map<String, dynamic>> estructuraCompleta =
          await dbHelper.obtenerEstructuraCompleta(id);

      // Como `obtenerEstructuraCompleta` devuelve una lista, pero solo hay un dato por ID, tomamos el primer elemento.
      if (estructuraCompleta.isNotEmpty) {
        jsonData.add(estructuraCompleta.first);
      }
    }

    // Mostrar diálogo de confirmación antes de enviar
    await _enviarDatosALaNubeExplo(jsonData);
  }

  Future<void> _showConfirmationDialogexplo(
    List<Map<String, dynamic>> jsonData,
  ) async {
    String prettyJson = const JsonEncoder.withIndent('  ').convert(jsonData);

    bool? confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar envío'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    '¿Estás seguro que deseas enviar los siguientes datos a la nube?'),
                const SizedBox(height: 16),
                Text(
                  'Operaciones a enviar: ${jsonData.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      await _enviarDatosALaNubeExplo(jsonData);
    }
  }

  Future<void> _enviarDatosALaNubeExplo(
      List<Map<String, dynamic>> jsonData) async {
    final operacionService = ExploracionService();
    bool allSuccess = true;

    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var operacion in jsonData) {
        bool success = await operacionService.crearExploracionCompleta(
          operacion,
        );

        if (success) {
          // Si la operación fue exitosa, actualizar el estado de envío en la base de datos
          int operacionId = operacion['id'];
          await _actualizarEnvioExplo(
              operacionId); // Actualizar el campo 'envio'
        } else {
          allSuccess = false;
          print('Error al enviar operación: ${operacion['id']}');
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío: $e');
    }

    // Cerrar el diálogo de progreso
    Navigator.of(context).pop();
  }

  Future<int> _actualizarEnvioExplo(int operacionId) async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

    // Llamada a la función que actualizará el estado de 'envio' en la base de datos
    return await dbHelper.actualizarEnvioDatos_trabajo_exploraciones(
      operacionId,
    );
  }
  //MEDICIONES--------------------------------------------------------------------------------------------------------------------------------
//   Future<void> _exportSelectedItemsMediciones() async {
//     if (idsMediciones.isEmpty) return;

//     DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
//     List<Map<String, dynamic>> jsonData = [];

//     for (var id in idsMediciones) {
//       List<Map<String, dynamic>> estructuraCompleta = await dbHelper
//           .obtenerPerforacionMedicionesEstructura(id);

//       // Como `obtenerEstructuraCompleta` devuelve una lista, pero solo hay un dato por ID, tomamos el primer elemento.
//       if (estructuraCompleta.isNotEmpty) {
//         jsonData.add(estructuraCompleta.first);
//       }
//     }

//     // Mostrar diálogo de confirmación antes de enviar
//     await _enviarDatosALaNubeMedicion(jsonData);
//   }

//   Future<void> _enviarDatosALaNubeMedicion(List<Map<String, dynamic>> jsonData) async {
//   final medicionService = PerforacionMedicionService();
//   bool allSuccess = true;
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const Center(child: CircularProgressIndicator()),
//   );

//   try {
//     for (var operacion in jsonData) {
//       final prettyJson = const JsonEncoder.withIndent('  ').convert(operacion);

//       bool success = await medicionService.crearPerforacion(operacion);

//       if (success) {
//         await _actualizarEnvioMedicion(operacion['id']);
//       } else {
//         allSuccess = false;
//       }
//     }
//   } catch (e) {
//     allSuccess = false;
//   }

//   Navigator.of(context).pop();
// }

//  Future<int> _actualizarEnvioMedicion(int operacionId) async {
//     DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

//     // Llamada a la función que actualizará el estado de 'envio' en la base de datos
//     return await dbHelper.actualizarEnvioDatos_mediociones(
//       operacionId,
//     );
//   }

}
