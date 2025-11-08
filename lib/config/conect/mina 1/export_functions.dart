import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/mina%201/models/Envio%20Api/medicion_horizontal.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/aceros_service.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/api_service_mediciones_horizontal_programado.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/carguio_service.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/operacion_service.dart';
import 'package:flutter/material.dart';

class ExportFunctions {
  static final DatabaseHelper_Mina1 _dbHelper = DatabaseHelper_Mina1();

  // LARGO --------------------------------------------------------------------
  static Future<bool> exportLargoAuto(BuildContext context, List<int> idsTaladroLargo, List<Map<String, dynamic>> operacionDataLargo) async {
    print('IDs recibidos en exportLargoAuto: $idsTaladroLargo');
    if (idsTaladroLargo.isEmpty) return true;

    List<Map<String, dynamic>> jsonDataParaCrear = [];
    List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (var id in idsTaladroLargo) {
      var operacion = operacionDataLargo.firstWhere((op) => op['id'] == id);
      List<Map<String, dynamic>> estados = await _dbHelper.getEstadosByOperacionId(id);
      List<Map<String, dynamic>> perforaciones = await _dbHelper.getPerforacionesTaladroLargo(id);

      List<Map<String, dynamic>> interPerforaciones = [];
      for (var perforacion in perforaciones) {
        int perforacionId = perforacion['id'];
        List<Map<String, dynamic>> interData = await _dbHelper.getInterPerforacionesTaladroLargo(perforacionId);
        interPerforaciones.addAll(interData);
      }

      List<Map<String, dynamic>> horometros = await _dbHelper.getHorometrosByOperacion(id);

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

      if (operacion['idNube'] == null) {
        jsonDataParaCrear.add(operacionCompleta);
      } else {
        operacionCompleta['operacion']['id'] = operacion['idNube'];
        jsonDataParaActualizar.add(operacionCompleta);
      }
    }

    return await _enviarDatosALaNubeLargo(context, jsonDataParaCrear, jsonDataParaActualizar);
  }

  static Future<bool> _enviarDatosALaNubeLargo(
    BuildContext context,
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
          if (operacion['operacion']['estado'] == 'cerrado') {
            await _actualizarEnvio(localId);
          } else {
            await _actualizarEnvioParciales(localId);
          }
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío Largo: $e');
    }

    return allSuccess;
  }

  // HORIZONTAL ---------------------------------------------------------------
  static Future<bool> exportHorizontalAuto(BuildContext context, List<int> idsHorizontal, List<Map<String, dynamic>> operacionDataHorizontal) async {
    print('IDs recibidos en exportHorizontalAuto: $idsHorizontal');
    if (idsHorizontal.isEmpty) return true;

    List<Map<String, dynamic>> jsonDataParaCrear = [];
    List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (var id in idsHorizontal) {
      var operacion = operacionDataHorizontal.firstWhere((op) => op['id'] == id);
      List<Map<String, dynamic>> estados = await _dbHelper.getEstadosByOperacionId(id);
      List<Map<String, dynamic>> perforaciones = await _dbHelper.getPerforacionesTaladroHorizontal(id);

      List<Map<String, dynamic>> interPerforaciones = [];
      for (var perforacion in perforaciones) {
        int perforacionId = perforacion['id'];
        List<Map<String, dynamic>> interData = await _dbHelper.getInterPerforacionesHorizontal(perforacionId);
        interPerforaciones.addAll(interData);
      }

      List<Map<String, dynamic>> horometros = await _dbHelper.getHorometrosByOperacion(id);

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

    return await _enviarDatosALaNubeHorizontal(context, jsonDataParaCrear, jsonDataParaActualizar);
  }

  static Future<bool> _enviarDatosALaNubeHorizontal(
    BuildContext context,
    List<Map<String, dynamic>> jsonDataParaCrear,
    List<Map<String, dynamic>> jsonDataParaActualizar,
  ) async {
    final operacionService = OperacionService();
    bool allSuccess = true;

    try {
      for (var operacion in jsonDataParaCrear) {
        int localId = operacion['local_id'];
        print('Creando en la nube operacion con ID local: $localId');

        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        final idsNube = await operacionService.crearOperacionHorizontal(operacionSinLocalId);

        if (idsNube != null && idsNube.isNotEmpty) {
          final idNube = idsNube.length == 1 ? idsNube.first : idsNube[0];
          await _actualizarIdNubeOperacion(localId, idNube);
          
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
          if (operacion['operacion']['estado'] == 'cerrado') {
            await _actualizarEnvio(localId);
          } else {
            await _actualizarEnvioParciales(localId);
          }
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío Horizontal: $e');
    }

    return allSuccess;
  }

  // SOSTENIMIENTO ------------------------------------------------------------
  static Future<bool> exportSostenimientoAuto(BuildContext context, List<int> idsSostenimiento, List<Map<String, dynamic>> operacionDataSostenimiento) async {
    if (idsSostenimiento.isEmpty) return true;

    List<Map<String, dynamic>> jsonDataParaCrear = [];
    List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (var id in idsSostenimiento) {
      var operacion = operacionDataSostenimiento.firstWhere((op) => op['id'] == id);
      List<Map<String, dynamic>> estados = await _dbHelper.getEstadosByOperacionId(id);
      List<Map<String, dynamic>> perforaciones = await _dbHelper.getPerforacionesTaladroSostenimiento(id);

      List<Map<String, dynamic>> interPerforaciones = [];
      for (var perforacion in perforaciones) {
        int perforacionId = perforacion['id'];
        List<Map<String, dynamic>> interData = await _dbHelper.getInterSostenimientos(perforacionId);
        interPerforaciones.addAll(interData);
      }

      List<Map<String, dynamic>> horometros = await _dbHelper.getHorometrosByOperacion(id);

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

    return await _enviarDatosALaNubeSostenimiento(context, jsonDataParaCrear, jsonDataParaActualizar);
  }

  static Future<bool> _enviarDatosALaNubeSostenimiento(
    BuildContext context,
    List<Map<String, dynamic>> jsonDataParaCrear,
    List<Map<String, dynamic>> jsonDataParaActualizar,
  ) async {
    final operacionService = OperacionService();
    bool allSuccess = true;

    try {
      for (var operacion in jsonDataParaCrear) {
        int localId = operacion['local_id'];
        print('Creando en la nube operacion con ID local: $localId');

        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        final idsNube = await operacionService.crearOperacionSostenimiento(operacionSinLocalId);

        if (idsNube != null && idsNube.isNotEmpty) {
          final idNube = idsNube.length == 1 ? idsNube.first : idsNube[0];
          await _actualizarIdNubeOperacion(localId, idNube);
          
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
          if (operacion['operacion']['estado'] == 'cerrado') {
            await _actualizarEnvio(localId);
          } else {
            await _actualizarEnvioParciales(localId);
          }
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío Sostenimiento: $e');
    }

    return allSuccess;
  }

  // EXPLOSIVOS ---------------------------------------------------------------
  static Future<bool> exportExplosivosAuto(BuildContext context, List<int> idsExplosivos) async {
    if (idsExplosivos.isEmpty) return true;

    List<Map<String, dynamic>> jsonData = [];

    for (var id in idsExplosivos) {
      List<Map<String, dynamic>> estructuraCompleta = await _dbHelper.obtenerEstructuraCompleta(id);

      if (estructuraCompleta.isNotEmpty) {
        jsonData.add(estructuraCompleta.first);
      }
    }

    return await _enviarDatosALaNubeExplo(context, jsonData);
  }

  static Future<bool> _enviarDatosALaNubeExplo(BuildContext context, List<Map<String, dynamic>> jsonData) async {
    final operacionService = ExploracionService();
    bool allSuccess = true;

    try {
      for (var operacion in jsonData) {
        bool success = await operacionService.crearExploracionCompleta(operacion);

        if (success) {
          int operacionId = operacion['id'];
          await _actualizarEnvioExplo(operacionId);
        } else {
          allSuccess = false;
          print('Error al enviar operación: ${operacion['id']}');
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío Explosivos: $e');
    }

    return allSuccess;
  }

  // MEDICIONES HORIZONTAL ----------------------------------------------------
  static Future<bool> exportMedicionesHorizontalAuto(BuildContext context, List<int> idsMedicionesHorizontal) async {
    if (idsMedicionesHorizontal.isEmpty) return true;

    final List<Map<String, dynamic>> jsonCrear = [];
    final List<Map<String, dynamic>> jsonActualizar = [];

    for (final id in idsMedicionesHorizontal) {
      final medicion = await _dbHelper.obtenerMedicionHorizontalPorIdProgramado(id);
      if (medicion == null) continue;

      if (medicion['idNube_medicion'] != null && medicion['idNube_medicion'] != 0) {
        final updateMap = Map<String, dynamic>.from(medicion);
        updateMap['id'] = updateMap['idNube_medicion'];
        updateMap.remove('idNube_medicion');
        jsonActualizar.add(updateMap);
      } else {
        jsonCrear.add(medicion);
      }
    }

    bool crearSuccess = true;
    bool actualizarSuccess = true;

    if (jsonCrear.isNotEmpty) {
      crearSuccess = await _enviarDatosALaNubeMedicionHorizontal(context, jsonCrear);
    }
    if (jsonActualizar.isNotEmpty) {
      actualizarSuccess = await _actualizarDatosEnLaNubeMedicionHorizontal(context, jsonActualizar);
    }

    return crearSuccess && actualizarSuccess;
  }

  static Future<bool> _actualizarDatosEnLaNubeMedicionHorizontal(BuildContext context, List<Map<String, dynamic>> jsonData) async {
    final medicionService = ApiServiceMedicionesHorizontalProgramado();
    bool allSuccess = true;

    try {
      final success = await medicionService.putMedicionHorizontal(jsonData);
      if (success) {
        for (final item in jsonData) {
          await _actualizarEnvioMedicionHorizontal(item['id_local'] ?? item['id']);
        }
      } else {
        allSuccess = false;
      }
    } catch (e) {
      allSuccess = false;
      print('Error actualizando mediciones horizontales: $e');
    }

    return allSuccess;
  }

  static Future<bool> _enviarDatosALaNubeMedicionHorizontal(BuildContext context, List<Map<String, dynamic>> jsonData) async {
    final medicionService = ApiServiceMedicionesHorizontalProgramado();
    final exploracionService = ExploracionService();
    bool allSuccess = true;
    List<int> idsNubeParaMarcar = [];

    try {
      for (var medicionMap in jsonData) {
        try {
          final medicion = MedicionHorizontal.fromJson(medicionMap);
          bool success = await medicionService.postMedicionHorizontal(medicion.toApiJson());

          if (success) {
            await _actualizarEnvioMedicionHorizontal(medicionMap['id']);
            
            if (medicionMap['idnube'] != null) {
              idsNubeParaMarcar.add(medicionMap['idnube']);
            }
          } else {
            allSuccess = false;
            print("Error al enviar medición ID: ${medicionMap['id']}");
          }
        } catch (e) {
          allSuccess = false;
          print("Error procesando medición ID: ${medicionMap['id']} - ${e.toString()}");
        }
      }

      if (idsNubeParaMarcar.isNotEmpty) {
        bool marcadoExitoso = await exploracionService.marcarComoUsadosEnMedicionesProgramadas(idsNubeParaMarcar);
        
        if (!marcadoExitoso) {
          allSuccess = false;
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error enviando mediciones horizontales: $e');
    }

    return allSuccess;
  }

  // ACEROS -------------------------------------------------------------------
  static Future<bool> exportAcerosAuto(BuildContext context, List<int> idsIngresosAceros, List<int> idsSalidasAceros) async {
    if (idsIngresosAceros.isEmpty && idsSalidasAceros.isEmpty) return true;

    final List<Map<String, dynamic>> ingresosParaEnviar = [];
    final List<Map<String, dynamic>> salidasParaEnviar = [];

    for (final id in idsIngresosAceros) {
      final ingreso = await _dbHelper.obtenerIngresoPorId(id);
      if (ingreso != null) {
        ingresosParaEnviar.add(ingreso);
      }
    }

    for (final id in idsSalidasAceros) {
      final salida = await _dbHelper.obtenerSalidaPorId(id);
      if (salida != null) {
        salidasParaEnviar.add(salida);
      }
    }

    bool ingresosSuccess = true;
    bool salidasSuccess = true;

    if (ingresosParaEnviar.isNotEmpty) {
      ingresosSuccess = await _enviarIngresosAcerosALaNube(context, ingresosParaEnviar);
    }
    if (salidasParaEnviar.isNotEmpty) {
      salidasSuccess = await _enviarSalidasAcerosALaNube(context, salidasParaEnviar);
    }

    return ingresosSuccess && salidasSuccess;
  }

  static Future<bool> _enviarIngresosAcerosALaNube(BuildContext context, List<Map<String, dynamic>> ingresosData) async {
    final acerosService = AcerosService();
    bool allSuccess = true;

    try {
      for (var ingreso in ingresosData) {
        try {
          bool success = await acerosService.enviarIngresos(ingreso);
          
          if (success) {
            await _actualizarEnvioIngresoAcero(ingreso['id']);
          } else {
            allSuccess = false;
            print("Error al enviar ingreso ID: ${ingreso['id']}");
          }
        } catch (e) {
          allSuccess = false;
          print("Error procesando ingreso ID: ${ingreso['id']} - ${e.toString()}");
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error enviando ingresos de aceros: $e');
    }

    return allSuccess;
  }

  static Future<bool> _enviarSalidasAcerosALaNube(BuildContext context, List<Map<String, dynamic>> salidasData) async {
    final acerosService = AcerosService();
    bool allSuccess = true;

    try {
      for (var salida in salidasData) {
        try {
          bool success = await acerosService.enviarSalidas(salida);
          
          if (success) {
            await _actualizarEnvioSalidaAcero(salida['id']);
          } else {
            allSuccess = false;
            print("Error al enviar salida ID: ${salida['id']}");
          }
        } catch (e) {
          allSuccess = false;
          print("Error procesando salida ID: ${salida['id']} - ${e.toString()}");
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error enviando salidas de aceros: $e');
    }

    return allSuccess;
  }

  // CARGUÍO ------------------------------------------------------------------
  static Future<bool> exportCarguioAuto(BuildContext context, List<int> idscarguio, List<Map<String, dynamic>> operacionDatacarguio) async {
    if (idscarguio.isEmpty) return true;

    List<Map<String, dynamic>> jsonDataParaCrear = [];
    List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (var operacionId in idscarguio) {
      var operacion = operacionDatacarguio.firstWhere((op) => op['id'] == operacionId);

      List<Map<String, dynamic>> estados = await _dbHelper.getEstadosByOperacionId(operacionId);
      List<Map<String, dynamic>> horometros = await _dbHelper.getHorometrosByOperacion(operacionId);
      List<Map<String, dynamic>> carguios = await _dbHelper.getCarguiosByOperacionId(operacionId);

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

      List<Map<String, dynamic>> horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final']
        };
      }).toList();

      List<Map<String, dynamic>> carguiosLimpios = carguios.map((carguio) {
        return {
          "nivel": carguio['nivel'],
          "labor_origen": carguio['labor_origen'],
          "material": carguio['material'],
          "labor_destino": carguio['labor_destino'],
          "num_cucharas": carguio['num_cucharas'],
          "observaciones": carguio['observaciones'] ?? ""
        };
      }).toList();

      Map<String, dynamic> operacionCompleta = {
        "local_id": operacionId,
        "operacion": operacionSinId,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "carguios": carguiosLimpios,
      };

      if (operacion['idNube'] == null) {
        jsonDataParaCrear.add(operacionCompleta);
      } else {
        operacionCompleta['operacion']['id'] = operacion['idNube'];
        jsonDataParaActualizar.add(operacionCompleta);
      }
    }

    return await _enviarDatosALaNubeCarguio(context, jsonDataParaCrear, jsonDataParaActualizar);
  }

  static Future<bool> _enviarDatosALaNubeCarguio(
    BuildContext context,
    List<Map<String, dynamic>> jsonDataParaCrear,
    List<Map<String, dynamic>> jsonDataParaActualizar,
  ) async {
    final carguioService = CarguioService();
    bool allSuccess = true;

    try {
      for (var operacion in jsonDataParaCrear) {
        int localId = operacion['local_id'];
        print('Creando en la nube operación de CARGUÍO con ID local: $localId');

        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        final idsNube = await carguioService.enviarCarguio(operacionSinLocalId);

        if (idsNube != null && idsNube.isNotEmpty) {
          final idNube = idsNube.first;
          await _actualizarIdNubeOperacion(localId, idNube);

          if (operacion['operacion']['estado'] == 'cerrado') {
            await _actualizarEnvio(localId);
          } else {
            await _actualizarEnvioParciales(localId);
          }
        } else {
          allSuccess = false;
          print('Error al crear operación de carguío con ID local: $localId');
        }
      }

      for (var operacion in jsonDataParaActualizar) {
        int localId = operacion['local_id'];
        print('Actualizando en la nube operación de CARGUÍO con ID local: $localId');

        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        final success = await carguioService.actualizarCarguio(operacionSinLocalId);

        if (success) {
          if (operacion['operacion']['estado'] == 'cerrado') {
            await _actualizarEnvio(localId);
          } else {
            await _actualizarEnvioParciales(localId);
          }
        } else {
          allSuccess = false;
          print('Error al actualizar operación de carguío local $localId');
        }
      }
    } catch (e) {
      allSuccess = false;
      print('Error durante el envío de carguío: $e');
    }

    return allSuccess;
  }

  // MÉTODOS AUXILIARES COMUNES -----------------------------------------------
  static Future<int> _actualizarEnvio(int operacionId) async {
    print('operacionId recibido: $operacionId');
    return await _dbHelper.actualizarEnvio(operacionId);
  }

  static Future<int> _actualizarEnvioParciales(int operacionId) async {
    print('operacionId recibido: $operacionId');
    return await _dbHelper.actualizarEnvioParcial(operacionId);
  }

  static Future<int> _actualizarIdNubeOperacion(int idOperacion, int idNube) async {
    return await _dbHelper.actualizarIdNubeOperacion(idOperacion, idNube);
  }

  static Future<int> _actualizarEnvioExplo(int operacionId) async {
    return await _dbHelper.actualizarEnvioDatos_trabajo_exploraciones(operacionId);
  }

  static Future<int> _actualizarEnvioMedicionHorizontal(int medicionId) async {
    return await _dbHelper.actualizarEnvioMedicionesHorizontalProgramado([medicionId]);
  }

  static Future<int> _actualizarEnvioIngresoAcero(int ingresoId) async {
    return await _dbHelper.actualizarEnvioIngresos([ingresoId]);
  }

  static Future<int> _actualizarEnvioSalidaAcero(int salidaId) async {
    return await _dbHelper.actualizarEnvioSalidas([salidaId]);
  }
}