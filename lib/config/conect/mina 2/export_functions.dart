import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/mina%202/services/Enviar%20nube/operacion_service.dart'; // Ajusta las rutas

class ExportFunctionsminaw2 {
  static final DatabaseHelper_Mina2 _dbHelper = DatabaseHelper_Mina2();

  // LARGO --------------------------------------------------------------------
  static Future<bool> exportLargoAuto(BuildContext context, List<int> idsTaladroLargo, List<Map<String, dynamic>> operacionDataLargo) async {
    print('IDs recibidos en exportLargoAuto Mina2: $idsTaladroLargo');
    if (idsTaladroLargo.isEmpty) return true;

    final List<Map<String, dynamic>> jsonDataParaCrear = [];
    final List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (var id in idsTaladroLargo) {
      // 1. Obtener datos básicos de la operación
      final operacion = operacionDataLargo.firstWhere((op) => op['id'] == id);

      // 2. Obtener todos los elementos relacionados
      final estados = await _dbHelper.getEstadosByOperacionId(id);
      final horometros = await _dbHelper.getHorometrosByOperacion(id);
      final checklists = await _dbHelper.getChecklistsByOperacion(id);

      // 3. Preparar datos limpios de la operación (sin ID)
      final operacionLimpia = {
        "turno": operacion['turno'],
        "equipo": operacion['equipo'],
        "codigo": operacion['codigo'],
        "empresa": operacion['empresa'],
        "fecha": operacion['fecha'],
        "tipo_operacion": operacion['tipo_operacion'],
        "estado": operacion['estado'],
        "envio": operacion['envio'] ?? 0
      };

      // 4. Procesar estados con sus perforaciones e interperforaciones anidadas
      final estadosLimpios = <Map<String, dynamic>>[];

      for (final estado in estados) {
        // Obtener perforaciones de este estado
        final perforaciones = await _dbHelper.getPerforacionesTaladroLargo(estado['id']);
        final perforacionesLimpias = <Map<String, dynamic>>[];

        for (final perforacion in perforaciones) {
          // Obtener interperforaciones de esta perforación
          final interPerforaciones = await _dbHelper.getInterPerforacionesTaladroLargo(perforacion['id']);

          perforacionesLimpias.add({
            "zona": perforacion['zona'],
            "tipo_labor": perforacion['tipo_labor'],
            "labor": perforacion['labor'],
            "ala": perforacion['ala'],
            "veta": perforacion['veta'],
            "nivel": perforacion['nivel'],
            "observacion": perforacion['observacion'],
            "tipo_perforacion": perforacion['tipo_perforacion'],
            "inter_perforaciones": interPerforaciones.map((ip) {
              return {
                "codigo_actividad": ip['codigo_actividad'],
                "nivel": ip['nivel'],
                "tajo": ip['tajo'],
                "nbroca": ip['nbroca'],
                "ntaladro": ip['ntaladro'],
                "material": ip['material'],
                "nbarras": ip['nbarras'] ?? 0,
                "longitud_perforacion": ip['longitud_perforacion'],
                "angulo_perforacion": ip['angulo_perforacion'],
                "nfilas_de_hasta": ip['nfilas_de_hasta'] ?? "",
                "detalles_trabajo_realizado": ip['detalles_trabajo_realizado'] ?? ""
              };
            }).toList()
          });
        }

        // Agregar estado con sus perforaciones
        estadosLimpios.add({
          "numero": estado['numero'],
          "estado": estado['estado'],
          "codigo": estado['codigo'],
          "hora_inicio": estado['hora_inicio'],
          "hora_final": estado['hora_final'],
          "perforaciones": perforacionesLimpias
        });
      }

      // 5. Procesar horómetros
      final horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final'],
          "EstaOP": h['EstaOP'] ?? 0,
          "EstaINOP": h['EstaINOP'] ?? 0
        };
      }).toList();

      // 6. Procesar checklists
      final checklistsLimpios = checklists.map((c) {
        return {
          "descripcion": c['descripcion'],
          "decision": c['decision'],
          "observacion": c['observacion'],
          "categoria": c['categoria']
        };
      }).toList();

      // 7. Construir el objeto final de la operación
      final operacionCompleta = {
        "local_id": id,
        "idNube": operacion['idNube'] ?? 0,
        "operacion": operacionLimpia,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "checklists": checklistsLimpios,
      };

      // 8. Clasificar para crear o actualizar
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
      print('Error durante el envío Largo Mina2: $e');
    }

    return allSuccess;
  }

  // HORIZONTAL ---------------------------------------------------------------
  static Future<bool> exportHorizontalAuto(BuildContext context, List<int> idsHorizontal, List<Map<String, dynamic>> operacionDataHorizontal) async {
    print('IDs recibidos en exportHorizontalAuto Mina2: $idsHorizontal');
    if (idsHorizontal.isEmpty) return true;

    final List<Map<String, dynamic>> jsonDataParaCrear = [];
    final List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (final id in idsHorizontal) {
      // 1. Obtener datos básicos de la operación
      final operacion = operacionDataHorizontal.firstWhere((op) => op['id'] == id);

      // 2. Obtener todos los elementos relacionados
      final estados = await _dbHelper.getEstadosByOperacionId(id);
      final horometros = await _dbHelper.getHorometrosByOperacion(id);
      final checklists = await _dbHelper.getChecklistsByOperacion(id);

      // 3. Preparar datos limpios de la operación (sin ID)
      final operacionLimpia = {
        "turno": operacion['turno'],
        "equipo": operacion['equipo'],
        "codigo": operacion['codigo'],
        "empresa": operacion['empresa'],
        "fecha": operacion['fecha'],
        "tipo_operacion": operacion['tipo_operacion'],
        "estado": operacion['estado'],
        "envio": operacion['envio'] ?? 0
      };

      // 4. Procesar estados con sus perforaciones horizontales
      final estadosLimpios = <Map<String, dynamic>>[];

      for (final estado in estados) {
        // Obtener perforaciones horizontales para este estado
        final perforaciones = await _dbHelper.getPerforacionesTaladroHorizontal(estado['id']);

        final perforacionesLimpias = <Map<String, dynamic>>[];

        for (final perforacion in perforaciones) {
          // Obtener interperforaciones de esta perforación
          final interPerforaciones = await _dbHelper.getInterPerforacionesHorizontal(perforacion['id']);

          perforacionesLimpias.add({
            "zona": perforacion['zona'],
            "tipo_labor": perforacion['tipo_labor'],
            "labor": perforacion['labor'],
            "veta": perforacion['veta'],
            "nivel": perforacion['nivel'],
            "observacion": perforacion['observacion'],
            "tipo_perforacion": perforacion['tipo_perforacion'],
            "inter_perforaciones": interPerforaciones.map((ip) {
              return {
                "codigo_actividad": ip['codigo_actividad'],
                "nivel": ip['nivel'],
                "labor": ip['labor'],
                "seccion_la_labor": ip['seccion_la_labor'],
                "nbroca": ip['nbroca'],
                "ntaladro": ip['ntaladro'],
                "material": ip['material'],
                "ntaladros_rimados": ip['ntaladros_rimados'],
                "longitud_perforacion": ip['longitud_perforacion'],
                "metros_perforados": ip['metros_perforados'] ?? 0.0,
                "detalles_trabajo_realizado": ip['detalles_trabajo_realizado'] ?? ""
              };
            }).toList()
          });
        }

        // Agregar estado con sus perforaciones horizontales
        estadosLimpios.add({
          "numero": estado['numero'],
          "estado": estado['estado'],
          "codigo": estado['codigo'],
          "hora_inicio": estado['hora_inicio'],
          "hora_final": estado['hora_final'],
          "perforaciones_horizontales": perforacionesLimpias
        });
      }

      // 5. Procesar horómetros
      final horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final'],
          "EstaOP": h['EstaOP'] ?? 0,
          "EstaINOP": h['EstaINOP'] ?? 0
        };
      }).toList();

      // 6. Procesar checklists
      final checklistsLimpios = checklists.map((c) {
        return {
          "descripcion": c['descripcion'],
          "decision": c['decision'],
          "observacion": c['observacion'],
          "categoria": c['categoria']
        };
      }).toList();

      // 7. Construir el objeto final de la operación
      final operacionCompleta = {
        "local_id": id,
        "idNube": operacion['idNube'] ?? 0,
        "operacion": operacionLimpia,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "checklists": checklistsLimpios,
      };

      // 8. Clasificar para crear o actualizar
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
      print('Error durante el envío Horizontal Mina2: $e');
    }

    return allSuccess;
  }

  // SOSTENIMIENTO ------------------------------------------------------------
  static Future<bool> exportSostenimientoAuto(BuildContext context, List<int> idsSostenimiento, List<Map<String, dynamic>> operacionDataSostenimiento) async {
    if (idsSostenimiento.isEmpty) return true;

    final List<Map<String, dynamic>> jsonDataParaCrear = [];
    final List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (final id in idsSostenimiento) {
      // 1. Obtener datos básicos de la operación
      final operacion = operacionDataSostenimiento.firstWhere((op) => op['id'] == id);

      // 2. Obtener todos los elementos relacionados
      final estados = await _dbHelper.getEstadosByOperacionId(id);
      final horometros = await _dbHelper.getHorometrosByOperacion(id);
      final checklists = await _dbHelper.getChecklistsByOperacion(id);

      // 3. Preparar datos limpios de la operación (sin ID)
      final operacionLimpia = {
        "turno": operacion['turno'],
        "equipo": operacion['equipo'],
        "codigo": operacion['codigo'],
        "empresa": operacion['empresa'],
        "fecha": operacion['fecha'],
        "tipo_operacion": operacion['tipo_operacion'],
        "estado": operacion['estado'] ?? 'activo',
        "envio": operacion['envio'] ?? 0
      };

      // 4. Procesar estados con sus sostenimientos
      final estadosLimpios = <Map<String, dynamic>>[];

      for (final estado in estados) {
        // Obtener sostenimientos para este estado
        final sostenimientos = await _dbHelper.getPerforacionesTaladroSostenimiento(estado['id']);

        final sostenimientosLimpios = <Map<String, dynamic>>[];

        for (final sostenimiento in sostenimientos) {
          // Obtener intersostenimientos de este sostenimiento
          final interSostenimientos = await _dbHelper.getInterSostenimientos(sostenimiento['id']);

          sostenimientosLimpios.add({
            "zona": sostenimiento['zona'],
            "tipo_labor": sostenimiento['tipo_labor'],
            "labor": sostenimiento['labor'],
            "ala": sostenimiento['ala'],
            "veta": sostenimiento['veta'],
            "nivel": sostenimiento['nivel'],
            "observacion": sostenimiento['observacion'],
            "tipo_perforacion": sostenimiento['tipo_perforacion'],
            "inter_sostenimientos": interSostenimientos.map((ip) {
              return {
                "codigo_actividad": ip['codigo_actividad'],
                "nivel": ip['nivel'],
                "labor": ip['labor'],
                "seccion_de_labor": ip['seccion_de_labor'],
                "nbroca": ip['nbroca'],
                "ntaladro": ip['ntaladro'],
                "material": ip['material'],
                "longitud_perforacion": ip['longitud_perforacion'],
                "metros_perforados": ip['metros_perforados'] ?? 0.0,
                "detalles_trabajo_realizado": ip['detalles_trabajo_realizado'] ?? "",
                "malla_instalada": ip['malla_instalada'] ?? false
              };
            }).toList()
          });
        }

        // Agregar estado con sus sostenimientos
        estadosLimpios.add({
          "numero": estado['numero'],
          "estado": estado['estado'],
          "codigo": estado['codigo'],
          "hora_inicio": estado['hora_inicio'],
          "hora_final": estado['hora_final'],
          "sostenimientos": sostenimientosLimpios
        });
      }

      // 5. Procesar horómetros
      final horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final'],
          "EstaOP": h['EstaOP'] ?? 0,
          "EstaINOP": h['EstaINOP'] ?? 0
        };
      }).toList();

      // 6. Procesar checklists
      final checklistsLimpios = checklists.map((c) {
        return {
          "descripcion": c['descripcion'],
          "decision": c['decision'],
          "observacion": c['observacion'],
          "categoria": c['categoria']
        };
      }).toList();

      // 7. Construir el objeto final de la operación
      final operacionCompleta = {
        "local_id": id,
        "idNube": operacion['idNube'] ?? 0,
        "operacion": operacionLimpia,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "checklists": checklistsLimpios,
      };

      // 8. Clasificar para crear o actualizar
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
      print('Error durante el envío Sostenimiento Mina2: $e');
    }

    return allSuccess;
  }

  // CARGUÍO ------------------------------------------------------------------
  static Future<bool> exportCarguioAuto(BuildContext context, List<int> idsCarguio, List<Map<String, dynamic>> operacionDataCarguio) async {
    if (idsCarguio.isEmpty) return true;

    final List<Map<String, dynamic>> jsonDataParaCrear = [];
    final List<Map<String, dynamic>> jsonDataParaActualizar = [];

    for (final id in idsCarguio) {
      // 1. Obtener datos básicos de la operación
      final operacion = operacionDataCarguio.firstWhere((op) => op['id'] == id);

      // 2. Obtener todos los elementos relacionados
      final estados = await _dbHelper.getEstadosByOperacionId(id);
      final horometros = await _dbHelper.getHorometrosByOperacion(id);
      final checklists = await _dbHelper.getChecklistsByOperacion(id);

      // 3. Preparar datos limpios de la operación (sin ID local)
      final operacionLimpia = {
        "turno": operacion['turno'],
        "equipo": operacion['equipo'],
        "codigo": operacion['codigo'],
        "empresa": operacion['empresa'],
        "fecha": operacion['fecha'],
        "tipo_operacion": operacion['tipo_operacion'],
        "estado": operacion['estado'] ?? 'activo',
        "envio": operacion['envio'] ?? 0
      };

      // 4. Procesar estados con sus carguios
      final estadosLimpios = <Map<String, dynamic>>[];

      for (final estado in estados) {
        // Obtener carguios para este estado
        final carguios = await _dbHelper.getCarguios(estado['id']);

        final carguiosLimpios = carguios.map((c) {
          return {
            "tipo_labor": c['tipo_labor'],
            "labor": c['labor'],
            "tipo_labor_manual": c['tipo_labor_manual'] ?? "",
            "labor_manual": c['labor_manual'] ?? "",
            "ncucharas": c['ncucharas'] ?? 0,
            "observacion": c['observacion'] ?? ""
          };
        }).toList();

        // Agregar estado con sus carguios
        estadosLimpios.add({
          "numero": estado['numero'],
          "estado": estado['estado'],
          "codigo": estado['codigo'],
          "hora_inicio": estado['hora_inicio'],
          "hora_final": estado['hora_final'],
          "carguios": carguiosLimpios
        });
      }

      // 5. Procesar horómetros
      final horometrosLimpios = horometros.map((h) {
        return {
          "nombre": h['nombre'],
          "inicial": h['inicial'],
          "final": h['final'],
          "EstaOP": h['EstaOP'] ?? 0,
          "EstaINOP": h['EstaINOP'] ?? 0
        };
      }).toList();

      // 6. Procesar checklists
      final checklistsLimpios = checklists.map((c) {
        return {
          "descripcion": c['descripcion'],
          "decision": c['decision'],
          "observacion": c['observacion'],
          "categoria": c['categoria']
        };
      }).toList();

      // 7. Construir el objeto final de la operación
      final operacionCompleta = {
        "local_id": id,
        "idNube": operacion['idNube'] ?? 0,
        "operacion": operacionLimpia,
        "estados": estadosLimpios,
        "horometros": horometrosLimpios,
        "checklists": checklistsLimpios,
      };

      // 8. Clasificar para crear o actualizar
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
    final operacionService = OperacionService();
    bool allSuccess = true;

    try {
      for (var operacion in jsonDataParaCrear) {
        int localId = operacion['local_id'];
        print('Creando en la nube operacion con ID local: $localId');

        final operacionSinLocalId = Map<String, dynamic>.from(operacion);
        operacionSinLocalId.remove('local_id');

        final idsNube = await operacionService.crearOperacionCarguio(operacionSinLocalId);

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

        final success = await operacionService.actualizarOperacionCarguio(operacionSinLocalId);

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
      print('Error durante el envío Carguío Mina2: $e');
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
      print('Error durante el envío Explosivos Mina2: $e');
    }

    return allSuccess;
  }

  // MÉTODOS AUXILIARES COMUNES -----------------------------------------------
  static Future<int> _actualizarEnvio(int operacionId) async {
    print('operacionId recibido Mina2: $operacionId');
    return await _dbHelper.actualizarEnvio(operacionId);
  }

  static Future<int> _actualizarEnvioParciales(int operacionId) async {
    print('operacionId recibido Mina2: $operacionId');
    return await _dbHelper.actualizarEnvioParcial(operacionId);
  }

  static Future<int> _actualizarIdNubeOperacion(int idOperacion, int idNube) async {
    return await _dbHelper.actualizarIdNubeOperacion(idOperacion, idNube);
  }

  static Future<int> _actualizarEnvioExplo(int operacionId) async {
    return await _dbHelper.actualizarEnvioDatos_trabajo_exploraciones(operacionId);
  }
}