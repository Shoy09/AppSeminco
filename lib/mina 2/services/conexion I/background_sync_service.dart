import 'dart:convert';

import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/operacion_service.dart';
import 'package:flutter/foundation.dart';
import 'package:app_seminco/mina%202/services/conexion I/ConnectivityService.dart';
import 'dart:async'; // Necesario para Timer

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

class BackgroundSyncService {
  final ConnectivityService connectivityService;
  final Debouncer _debouncer;
  bool _isSyncing = false;
  DateTime? _lastSync;

    final Set<int> idsTaladroLargo = {};
  final Set<int> idsSostenimiento = {};
  final Set<int> idsHorizontal = {};
  final Set<int> idsExplosivos = {};
  final Set<int> idsMediciones = {};

  List<Map<String, dynamic>> operacionDataLargo = [];
  List<Map<String, dynamic>> operacionDataHorizontal = [];
  List<Map<String, dynamic>> operacionDataSostenimiento = [];
  List<Map<String, dynamic>> operacionDataExplosi = [];
  List<Map<String, dynamic>> operacionDataMediciones = [];


  BackgroundSyncService({required this.connectivityService})
      : _debouncer = Debouncer(delay: Duration(seconds: 5)) {
    _init();
  }

  void _init() {
    connectivityService.connectionStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        // Solo sincronizar si la última sincronización fue hace más de 1 minuto
        if (_lastSync == null ||
            DateTime.now().difference(_lastSync!) > Duration(minutes: 1)) {
          _debouncer.run(() {
            _executeBackgroundTasks();
          });
        }
      }
    });
  }

Future<void> _executeBackgroundTasks() async {
  _isSyncing = true;
  print("📡 Ejecutando tareas en segundo plano...");

  try {

    await _loadAllOperationData();
    print("✅ Datos de operaciones cargados");

    await _loadAllOperationDataPendientes();
    print("✅ Datos pendientes cargados");

    _lastSync = DateTime.now();
    print("🎉 Todas las tareas completadas correctamente");
  } catch (e) {
    print("❌ Error en tareas: $e");
    rethrow; 
  } finally {
    _isSyncing = false;
  }
}

  void dispose() {
    _debouncer.cancel();
  }

Future<void> _loadAllOperationData() async {
    try {
      debugPrint("🔄 Cargando datos de operaciones...");
      final dbHelper = DatabaseHelper_Mina2();
      
      // Ejecutar todas las cargas en paralelo
      await Future.wait([
        _fetchOperacionDataLargo(),
        _fetchOperacionDataHorizontal(),
        _fetchOperacionDataSostenimiento(),
        _fetchExploracionesDataExplo(),
        // _fetchMedicionesDataExplo(),
      ]);
      
      debugPrint("✅ Todos los datos de operaciones cargados");
    } catch (e) {
      debugPrint("❌ Error al cargar datos de operaciones: $e");
      rethrow;
    }
  }


  Future<void> _loadAllOperationDataPendientes() async {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

    // Limpiar las estructuras antes de llenarlas
    idsTaladroLargo.clear();
    idsSostenimiento.clear();
    idsHorizontal.clear();
    idsExplosivos.clear();
    idsMediciones.clear();

    try {
      // Definir las secciones disponibles
      final secciones = [
        "PERFORACIÓN TALADROS LARGOS",
        "SOSTENIMIENTO",
        "PERFORACIÓN HORIZONTAL",
        "EXPLOSIVOS",
        "MEDICIONES"
      ];

      // Procesar cada sección
      for (var seccion in secciones) {
        List<Map<String, dynamic>> datos;

        if (seccion == "EXPLOSIVOS") {
          datos = await dbHelper.getExploracionesPendientes();
        } //else if (seccion == "MEDICIONES") {
          //datos = await dbHelper.getMedicionesPendientes();} 
        else {
          datos = await dbHelper.getOperacionPendienteByTipo(seccion);
          if (kDebugMode) {
            print("Datos recibidos para $seccion: $datos");
          }
        }

        // Guardar los datos completos

        // Guardar solo los IDs en Sets según la sección
        for (var operacion in datos) {
          int id = operacion['id'] as int;
          switch (seccion) {
            case "PERFORACIÓN TALADROS LARGOS":
              idsTaladroLargo.add(id);
              break;
            case "SOSTENIMIENTO":
              idsSostenimiento.add(id);
              break;
            case "PERFORACIÓN HORIZONTAL":
              idsHorizontal.add(id);
              break;
            case "EXPLOSIVOS":
              idsExplosivos.add(id);
              break;
            case "MEDICIONES":
              idsMediciones.add(id);
              break;
          }
        }
      }

      if (kDebugMode) {
        print("Taladro Largo IDs: $idsTaladroLargo");
        print("Sostenimiento IDs: $idsSostenimiento");
        print("Horizontal IDs: $idsHorizontal");
        print("Explosivos IDs: $idsExplosivos");
        print("Mediciones IDs: $idsMediciones");
      }

      // Proceder con los envíos si hay datos
      await _ejecutarEnviosAutomaticos();
    } catch (e) {
      debugPrint("❌ Error al cargar datos pendientes: $e");
      // Podrías agregar aquí lógica para reintentar después de un tiempo
    }
  }
  

    Future<void> _ejecutarEnviosAutomaticos() async {
    try {
      bool algunEnvioRealizado = false;

      // Envíos secuenciales
      if (idsTaladroLargo.isNotEmpty) {
        await _exportSelectedItemsLargo();
        algunEnvioRealizado = true;
        debugPrint("✅ Datos de Taladro Largo enviados");
      }

      if (idsHorizontal.isNotEmpty) {
        await _exportSelectedItemsHorizontal();
        algunEnvioRealizado = true;
        debugPrint("✅ Datos de Perforación Horizontal enviados");
      }

      if (idsSostenimiento.isNotEmpty) {
        await _exportSelectedItemsSostenimiento();
        algunEnvioRealizado = true;
        debugPrint("✅ Datos de Sostenimiento enviados");
      }

      if (idsExplosivos.isNotEmpty) {
        await _exportSelectedItemsExplo();
        algunEnvioRealizado = true;
        debugPrint("✅ Datos de Explosivos enviados");
      }

      // if (idsMediciones.isNotEmpty) {
      //   await _exportSelectedItemsMediciones();
      //   algunEnvioRealizado = true;
      //   debugPrint("✅ Datos de Mediciones enviados");
      // }

      if (!algunEnvioRealizado) {
        debugPrint("ℹ️ No se encontraron datos pendientes para enviar");
      }
    } catch (e) {
      debugPrint("❌ Error durante el envío automático: $e");
      // Podrías agregar aquí lógica para reintentar después de un tiempo
    }
  }


Future<void> _fetchOperacionDataLargo() async {
  try {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    operacionDataLargo = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN TALADROS LARGOS");
    debugPrint('📊 Datos de Taladro Largo cargados: ${operacionDataLargo.length} registros');
  } catch (e) {
    debugPrint('❌ Error al cargar datos de Taladro Largo: $e');
    operacionDataLargo = []; // Asegurar que la lista esté vacía en caso de error
  }
}

Future<void> _fetchOperacionDataHorizontal() async {
  try {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    operacionDataHorizontal = await dbHelper.getOperacionBytipoOperacion("PERFORACIÓN HORIZONTAL");
    debugPrint('📊 Datos de Horizontal cargados: ${operacionDataHorizontal.length} registros');
  } catch (e) {
    debugPrint('❌ Error al cargar datos de Horizontal: $e');
    operacionDataHorizontal = [];
  }
}

Future<void> _fetchOperacionDataSostenimiento() async {
  try {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    operacionDataSostenimiento = await dbHelper.getOperacionBytipoOperacion("SOSTENIMIENTO");
    debugPrint('📊 Datos de Sostenimiento cargados: ${operacionDataSostenimiento.length} registros');
  } catch (e) {
    debugPrint('❌ Error al cargar datos de Sostenimiento: $e');
    operacionDataSostenimiento = [];
  }
}

Future<void> _fetchExploracionesDataExplo() async {
  try {
    DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
    operacionDataExplosi = await dbHelper.getExploraciones();
    debugPrint('📊 Datos de Explosivos cargados: ${operacionDataExplosi.length} registros');
  } catch (e) {
    debugPrint('❌ Error al cargar datos de Explosivos: $e');
    operacionDataExplosi = [];
  }
}

// Future<void> _fetchMedicionesDataExplo() async {
//   try {
//     DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();
//     operacionDataMediciones = await dbHelper.obtenerPerforacionesConDetalles();
//     debugPrint('📊 Datos de Mediciones cargados: ${operacionDataMediciones.length} registros');
//   } catch (e) {
//     debugPrint('❌ Error al cargar datos de Mediciones: $e');
//     operacionDataMediciones = [];
//   }
// }




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
  Future<void> _enviarDatosALaNubeExplo(
      List<Map<String, dynamic>> jsonData) async {
    final operacionService = ExploracionService();
    bool allSuccess = true;

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


// }

//  Future<int> _actualizarEnvioMedicion(int operacionId) async {
//     DatabaseHelper_Mina2 dbHelper = DatabaseHelper_Mina2();

//     // Llamada a la función que actualizará el estado de 'envio' en la base de datos
//     return await dbHelper.actualizarEnvioDatos_mediociones(
//       operacionId,
//     );
//   }

}