import 'dart:async';
import 'dart:convert';
import 'package:app_seminco/mina%202/models/Accesorio.dart';
import 'package:app_seminco/mina%202/models/PlanMensual.dart';
import 'package:crypt/crypt.dart';
import 'package:app_seminco/mina%202/models/Empresa.dart';
import 'package:app_seminco/mina%202/models/Equipo.dart';
import 'package:app_seminco/mina%202/models/Explosivo.dart';
import 'package:app_seminco/mina%202/models/PlanMetraje.dart';
import 'package:app_seminco/mina%202/models/PlanProduccion.dart';
import 'package:app_seminco/mina%202/models/TipoPerforacion.dart';
import 'package:app_seminco/mina%202/models/destinatario_correo.dart';
import 'package:app_seminco/mina%202/models/explosivos_uni.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper_Mina2 {
  static final DatabaseHelper_Mina2 _instance = DatabaseHelper_Mina2._internal();
  factory DatabaseHelper_Mina2() => _instance;

  static Database? _database;
  static String? _currentUserDni;
  static bool _isInitialized = false;
  static const int _currentDbVersion = 1;

  DatabaseHelper_Mina2._internal() {
    // Inicialización única para evitar múltiples llamadas
    if (!_isInitialized) {
      _initializeDatabaseFactory();
      _isInitialized = true;
    }
  }

  /// Inicializa el database factory según la plataforma
  static void _initializeDatabaseFactory() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<void> setCurrentUserDni(String dni) async {
    _currentUserDni = dni;
    _database = await _initDatabase();
  }

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_currentUserDni == null) {
      throw Exception('DNI de usuario no establecido');
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> actualizarHoraFinal(int estadoId, String horaFinal) async {
    final db = await database;
    await db.update(
      'Estado',
      {'hora_final': horaFinal},
      where: 'id = ?',
      whereArgs: [estadoId],
    );
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    Directory documentsDirectory;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        documentsDirectory = await getApplicationDocumentsDirectory();
      } else {
        // Para Windows/Linux/MacOS
        documentsDirectory = await getApplicationSupportDirectory();
        // Alternativa: Guardar en AppData
        // documentsDirectory = Directory(join(Platform.environment['APPDATA']!, 'Seminco'));
      }

      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }

      String path =
          join(documentsDirectory.path, 'Seminco_db_mina02_${_currentUserDni!}.db');

      return await openDatabase(
        path,
        version: _currentDbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }

  // Método de creación de tablas
  Future<void> _onCreate(Database db, int version) async {
    // Crear las tablas necesarias
    await db.execute('''CREATE TABLE FormatoPlanMineral(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mina TEXT,
        zona TEXT,
        estructura TEXT,
        tipo_material TEXT,
        nivel TEXT,
        block TEXT,
        labor TEXT,
        metodo_minado TEXT,
        metros REAL,
        densidad REAL,
        toneladas REAL,
        ag REAL,
        au REAL,
        pb REAL,
        zn REAL,
        cu REAL,
        vpt REAL
      )''');

    await db.execute('''CREATE TABLE Operacion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idNube INTEGER,
        turno TEXT,
        equipo TEXT,
        codigo TEXT,
        empresa TEXT,
        fecha TEXT,
        tipo_operacion TEXT,
        estado TEXT DEFAULT 'activo',
        envio INTEGER DEFAULT 0
      )''');

    await db.execute('''
    CREATE TABLE Horometros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operacion_id INTEGER,
        nombre TEXT,
        inicial REAL,
        final REAL,
        EstaOP INTEGER DEFAULT 0,
        EstaINOP INTEGER DEFAULT 0,
        FOREIGN KEY (operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
    )
''');

    // Crear la tabla PerforacionTaladroLargo
    await db.execute('''CREATE TABLE PerforacionTaladroLargo(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zona TEXT,
        tipo_labor TEXT,
        labor TEXT, 
        veta TEXT,
        nivel TEXT,
        ala TEXT DEFAULT "",
        tipo_perforacion TEXT,
        operacion_id INTEGER,
        FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
      )''');

    await db.execute('''CREATE TABLE InterPerforacionTaladroLargo(
         id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_actividad TEXT,
    nivel TEXT,
    tajo TEXT,
    nbroca INTEGER,
    ntaladro INTEGER,
    nbarras INTEGER,
    longitud_perforacion REAL,
    angulo_perforacion REAL,
    nfilas_de_hasta TEXT,
    detalles_trabajo_realizado TEXT,
    perforaciontaladrolargo_id INTEGER,
    FOREIGN KEY(perforaciontaladrolargo_id) REFERENCES PerforacionTaladroLargo(id) ON DELETE CASCADE
 
      )''');

    // 🔹 Perforación Horizontal
    await db.execute('''
        CREATE TABLE PerforacionHorizontal(
           id INTEGER PRIMARY KEY AUTOINCREMENT,
      zona TEXT,
      tipo_labor TEXT,
      labor TEXT,
      veta TEXT,
      nivel TEXT,
      ala TEXT DEFAULT "",
      tipo_perforacion TEXT,
      operacion_id INTEGER,
      FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE InterPerforacionHorizontal(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          perforacionhorizontal_id INTEGER NOT NULL,
          codigo_actividad TEXT,
          nivel TEXT,
          labor TEXT,
          seccion_la_labor TEXT,
          nbroca INTEGER,
          ntaladro INTEGER,
          ntaladros_rimados INTEGER,
          longitud_perforacion REAL,
          detalles_trabajo_realizado TEXT,
          FOREIGN KEY(perforacionhorizontal_id) REFERENCES PerforacionHorizontal(id) ON DELETE CASCADE
        )
      ''');

    // 🔹 Sostenimiento
    await db.execute('''
        CREATE TABLE Sostenimiento(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operacion_id INTEGER,
          zona TEXT,
      tipo_labor TEXT,
      labor TEXT,
      veta TEXT,
      nivel TEXT,
      ala TEXT DEFAULT "",
      tipo_perforacion TEXT,
          FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE InterSostenimiento(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo_actividad TEXT,
          nivel TEXT,
          labor TEXT,
          seccion_de_labor TEXT,
          nbroca INTEGER,
          ntaladro INTEGER,
          longitud_perforacion REAL,
          malla_instalada TEXT,
          sostenimiento_id INTEGER,
          FOREIGN KEY(sostenimiento_id) REFERENCES Sostenimiento(id) ON DELETE CASCADE
        )
      ''');

    // 🔹 Servicios Auxiliares
    await db.execute('''
        CREATE TABLE ServiciosAuxiliares(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operacion_id INTEGER,
          tipo_servicio TEXT,
          descripcion TEXT,
          cantidad REAL,
          FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
        )
      ''');

    // 🔹 Carguío
    await db.execute('''
        CREATE TABLE Carguio(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operacion_id INTEGER,
          tipo_material TEXT,
          volumen REAL,
          maquinaria TEXT,
          operador TEXT,
          FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
        )
      ''');

    // 🔹 Acarreo
    await db.execute('''
        CREATE TABLE Acarreo(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operacion_id INTEGER,
          destino TEXT,
          distancia_km REAL,
          tiempo_min REAL,
          equipo_transporte TEXT,
          operador TEXT,
          FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
        )
      ''');

    // Crear la tabla Estado
    await db.execute('''CREATE TABLE Estado(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operacion_id INTEGER,
      numero INTEGER,
      estado TEXT,
      codigo TEXT,
      hora_inicio TEXT,
      hora_final TEXT,
      FOREIGN KEY(operacion_id) REFERENCES Operacion(id) ON DELETE CASCADE
    )''');

    // Crear la tabla Usuario
    await db.execute('''
  CREATE TABLE Usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_dni TEXT NOT NULL,
    apellidos TEXT NOT NULL,
    nombres TEXT NOT NULL,
    cargo TEXT,
    empresa TEXT,
    guardia TEXT,
    autorizado_equipo TEXT,
    area TEXT,
    clasificacion TEXT,
    correo TEXT UNIQUE,
    password TEXT NOT NULL,
    firma TEXT,
    rol TEXT,
    operaciones_autorizadas TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
''');

    await db.execute('''CREATE TABLE EstadostBD(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estado_principal TEXT,
    codigo TEXT,
    tipo_estado TEXT,
    categoria TEXT,
    proceso TEXT
  )''');

    await db.execute('''
  CREATE TABLE Datos_trabajo_exploraciones(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT,
    turno TEXT,
    taladro TEXT,
    pies_por_taladro TEXT,
    zona TEXT,
    tipo_labor TEXT,
    labor TEXT,
    ala TEXT,
    veta TEXT,
    nivel TEXT,
    tipo_perforacion TEXT,
    estado TEXT DEFAULT 'Creado',
    cerrado INTEGER DEFAULT 0,
    envio INTEGER DEFAULT 0,
    semanaDefault TEXT,
    semanaSelect TEXT,
    empresa TEXT,
    seccion TEXT,
    medicion INTEGER DEFAULT 0
  )
''');

    await db.execute('''
  CREATE TABLE Despacho (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    datos_trabajo_id INTEGER,
    mili_segundo REAL,
    medio_segundo REAL,
    observaciones TEXT,
    FOREIGN KEY(datos_trabajo_id) REFERENCES Datos_trabajo_exploraciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE DespachoDetalle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    despacho_id INTEGER,
    nombre_material TEXT NOT NULL,  
    cantidad TEXT NOT NULL,
    FOREIGN KEY(despacho_id) REFERENCES Despacho(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE Devoluciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    datos_trabajo_id INTEGER,
    mili_segundo REAL,
    medio_segundo REAL,
    observaciones TEXT,
    FOREIGN KEY(datos_trabajo_id) REFERENCES Datos_trabajo_exploraciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE DevolucionDetalle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    devolucion_id INTEGER,
    nombre_material TEXT NOT NULL,  
    cantidad TEXT NOT NULL,         
    FOREIGN KEY(devolucion_id) REFERENCES Devoluciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE DetalleDespachoExplosivos(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_despacho INTEGER,
    numero INTEGER,
    ms_cant1 TEXT,
    lp_cant1 TEXT,
    FOREIGN KEY (id_despacho) REFERENCES Despacho(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE DetalleDevolucionesExplosivos(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_devolucion INTEGER,
    numero INTEGER,
    ms_cant1 TEXT,
    lp_cant1 TEXT,
    FOREIGN KEY (id_devolucion) REFERENCES Devoluciones(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE nube_Datos_trabajo_exploraciones(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT,
    turno TEXT,
    taladro TEXT,
    pies_por_taladro TEXT,
    zona TEXT,
    tipo_labor TEXT,
    labor TEXT,
    ala TEXT,
    veta TEXT,
    nivel TEXT,
    tipo_perforacion TEXT,
    estado TEXT DEFAULT 'Creado',
    cerrado INTEGER DEFAULT 0,
    envio INTEGER DEFAULT 0,
    semanaDefault TEXT,
    semanaSelect TEXT,
    empresa TEXT,
    seccion TEXT,
    idnube TEXT,
    medicion INTEGER DEFAULT 0
  )
''');

    await db.execute('''
  CREATE TABLE nube_Despacho (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    datos_trabajo_id INTEGER,
    mili_segundo REAL,
    medio_segundo REAL,
    observaciones TEXT,
    FOREIGN KEY(datos_trabajo_id) REFERENCES nube_Datos_trabajo_exploraciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE nube_DespachoDetalle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    despacho_id INTEGER,
    nombre_material TEXT NOT NULL,  
    cantidad TEXT NOT NULL,
    FOREIGN KEY(despacho_id) REFERENCES nube_Despacho(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE nube_Devoluciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    datos_trabajo_id INTEGER,
    mili_segundo REAL,
    medio_segundo REAL,
    observaciones TEXT,
    FOREIGN KEY(datos_trabajo_id) REFERENCES nube_Datos_trabajo_exploraciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE nube_DevolucionDetalle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    devolucion_id INTEGER,
    nombre_material TEXT NOT NULL,  
    cantidad TEXT NOT NULL,         
    FOREIGN KEY(devolucion_id) REFERENCES nube_Devoluciones(id) ON DELETE CASCADE
  );
''');

    await db.execute('''
  CREATE TABLE nube_DetalleDespachoExplosivos(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_despacho INTEGER,
    numero INTEGER,
    ms_cant1 TEXT,
    lp_cant1 TEXT,
    FOREIGN KEY (id_despacho) REFERENCES nube_Despacho(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE nube_DetalleDevolucionesExplosivos(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_devolucion INTEGER,
    numero INTEGER,
    ms_cant1 TEXT,
    lp_cant1 TEXT,
    FOREIGN KEY (id_devolucion) REFERENCES nube_Devoluciones(id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE PlanMensual(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    anio INTEGER,
    mes TEXT,
    minado_tipo TEXT, 
    empresa TEXT,
    zona TEXT,
    area TEXT,
    tipo_mineral TEXT,
    fase TEXT,
    estructura_veta TEXT,
    nivel TEXT,
    tipo_labor TEXT,
    labor TEXT,
    ala TEXT,
    avance_m REAL,
    ancho_m REAL,
    alto_m REAL,
    tms REAL,
    ${List.generate(28, (i) => "col_${i + 1}A TEXT").join(", ")},
    ${List.generate(28, (i) => "col_${i + 1}B TEXT").join(", ")}
  )
''');

    await db.execute('''
  CREATE TABLE PlanProduccion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    anio INTEGER,
    mes TEXT NOT NULL,
    semana TEXT NOT NULL,
    mina TEXT NOT NULL,
    zona TEXT NOT NULL,
    area TEXT NOT NULL,
    fase TEXT NOT NULL,
    minado_tipo TEXT NOT NULL,
    tipo_labor TEXT NOT NULL,
    tipo_mineral TEXT NOT NULL,
    estructura_veta TEXT NOT NULL,
    nivel TEXT,
    block TEXT,
    labor TEXT NOT NULL,
    ala TEXT,
    ancho_veta REAL,
    ancho_minado_sem REAL,
    ancho_minado_mes REAL,
    ag_gr REAL,
    porcentaje_cu REAL,
    porcentaje_pb REAL,
    porcentaje_zn REAL,
    vpt_act REAL,
    vpt_final REAL,
    cut_off_1 REAL,
    cut_off_2 REAL,
    
    programado TEXT CHECK(programado IN ('Programado', 'No Programado')) NOT NULL DEFAULT 'Programado',

    ${List.generate(28, (i) => "columna_${i + 1}A TEXT").join(", ")},
    ${List.generate(28, (i) => "columna_${i + 1}B TEXT").join(", ")},

    createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
''');

    await db.execute('''
  CREATE TABLE PlanMetraje (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    anio INTEGER,
    mes TEXT NOT NULL,
    semana TEXT NOT NULL,
    mina TEXT NOT NULL,
    zona TEXT NOT NULL,
    area TEXT NOT NULL,
    fase TEXT NOT NULL,
    minado_tipo TEXT NOT NULL,
    tipo_labor TEXT NOT NULL,
    tipo_mineral TEXT NOT NULL,
    estructura_veta TEXT NOT NULL,
    nivel TEXT,
    block TEXT,
    labor TEXT NOT NULL,
    ala TEXT,
    ancho_veta REAL,
    ancho_minado_sem REAL,
    ancho_minado_mes REAL,
    burden REAL,
    espaciamiento REAL,
    longitud_perforacion REAL,
    programado TEXT CHECK(programado IN ('Programado', 'No Programado')) NOT NULL DEFAULT 'Programado',
    ${List.generate(28, (i) => "columna_${i + 1}A TEXT").join(", ")},
    ${List.generate(28, (i) => "columna_${i + 1}B TEXT").join(", ")},
    createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
''');

    await db.execute('''
  CREATE TABLE TipoPerforacion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    proceso TEXT NULL
  )
''');

    await db.execute('''
  CREATE TABLE Empresa (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL
  )
''');

    await db.execute('''
  CREATE TABLE Equipo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    proceso TEXT NOT NULL,
    codigo TEXT NOT NULL,
    marca TEXT NOT NULL,
    modelo TEXT NOT NULL,
    serie TEXT NOT NULL,
    anioFabricacion INTEGER NOT NULL,
    fechaIngreso TEXT NOT NULL,
    capacidadYd3 REAL,
    capacidadM3 REAL
  )
''');

    await db.execute('''
  CREATE TABLE accesorios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_accesorio TEXT NOT NULL,
    costo REAL NOT NULL,
    unidad_medida TEXT NOT NULL
  );
''');

    await db.execute('''
  CREATE TABLE explosivos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_explosivo TEXT NOT NULL,
    cantidad_por_caja INTEGER NOT NULL,
    peso_unitario REAL NOT NULL,
    costo_por_kg REAL NOT NULL,
    unidad_medida TEXT NOT NULL
  );
''');

    await db.execute('''
  CREATE TABLE ExplosivosUni (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dato REAL NOT NULL,
    tipo TEXT NOT NULL
  )
''');

    await db.execute('''
          CREATE TABLE destinatarios_correo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            correo TEXT NOT NULL UNIQUE
          )
        ''');

await db.execute('''
  CREATE TABLE mediciones_horizontal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    turno TEXT,
    empresa TEXT,
    zona TEXT,
    labor TEXT,
    veta TEXT,
    tipo_perforacion TEXT,
    kg_explosivos REAL,
    avance_programado REAL,
    ancho REAL,
    alto REAL,
    envio INTEGER DEFAULT 0,
    id_explosivo INTEGER,
    idnube INTEGER
  )
''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS mediciones_largo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      turno TEXT,
      empresa TEXT,
      zona TEXT,
      labor TEXT,
      veta TEXT,
      tipo_perforacion TEXT,
      kg_explosivos REAL,
      toneladas REAL,
      envio INTEGER DEFAULT 0,
      id_explosivo INTEGER,
      idnube INTEGER
    )
  ''');


    print(
        'Base de datos y tablas creadas: FormatoPlanMineral, Operacion, PerforacionTaladroLargo, Slot, Taladro, Estado, Usuario');
  }

  //Actualizar bd---------------------------------------------------------------------------------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    
  }

  Future<bool> _columnaExiste(Database db, String tabla, String columna) async {
    final result = await db.rawQuery("PRAGMA table_info($tabla)");
    return result.any((col) => col['name'] == columna);
  }

  // Insertar datos en cualquier tabla
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Obtener todos los registros de cualquier tabla
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Eliminar un registro de cualquier tabla
// Eliminar un registro de cualquier tabla
  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Método para eliminar todos los registros de una tabla
  Future<int> deleteAll(String table) async {
    final db = await database;
    return await db.delete(table); // Elimina todos los registros de la tabla
  }

  // Actualizar un registro en cualquier tabla
  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getDistinctValues(String columnName) async {
    final db = await database;
    final results = await db.rawQuery(
        'SELECT DISTINCT $columnName FROM FormatoPlanMineral WHERE $columnName IS NOT NULL');

    return results.map((row) => row[columnName] as String).toList();
  }

  Future<List<Map<String, dynamic>>> searchFormatoPlanMineral({
    String? mina,
    String? zona,
    String? nivel,
    String? block,
    String? estructura,
    String? labor,
  }) async {
    final db = await database;

    // Construir la consulta dinámica con filtros
    final whereClauses = <String>[];
    final whereArgs = <String>[];

    if (mina != null) {
      whereClauses.add('mina = ?');
      whereArgs.add(mina);
    }
    if (zona != null) {
      whereClauses.add('zona = ?');
      whereArgs.add(zona);
    }
    if (nivel != null) {
      whereClauses.add('nivel = ?');
      whereArgs.add(nivel);
    }
    if (block != null) {
      whereClauses.add('block = ?');
      whereArgs.add(block);
    }
    if (estructura != null) {
      whereClauses.add('estructura = ?');
      whereArgs.add(estructura);
    }
    if (labor != null) {
      whereClauses.add('labor = ?');
      whereArgs.add(labor);
    }

    // Combinar las cláusulas WHERE
    final whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    // Ejecutar la consulta
    final results = await db.query(
      'FormatoPlanMineral',
      where: whereString,
      whereArgs: whereArgs,
    );

    return results;
  }

  Future<List<Map<String, dynamic>>> getPerforacionesTaladroLargo(
      int operacionId) async {
    final db = await database;

    final List<Map<String, dynamic>> perforacionesRaw = await db.rawQuery('''
    SELECT id, zona, tipo_labor, labor, ala, veta, nivel, tipo_perforacion 
    FROM PerforacionTaladroLargo
    WHERE operacion_id = ?
  ''', [operacionId]);

    return perforacionesRaw.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  Future<int> insertarPerforacionTaladroLargo({
    required String zona,
    required String tipoLabor,
    required String labor,
    required String ala,
    required String veta,
    required String nivel,
    required String tipoPerforacion,
    required int operacionId, // ID de la Operacion relacionada
  }) async {
    final Database db =
        await DatabaseHelper_Mina2().database; // Obtener la base de datos

    // Crear el mapa con los datos a insertar
    Map<String, dynamic> datos = {
      'zona': zona,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'veta': veta,
      'nivel': nivel,
      'tipo_perforacion': tipoPerforacion,
      'operacion_id': operacionId, // Relación con la tabla Operacion
    };

    // Insertar en la base de datos y devolver el ID generado
    return await db.insert('PerforacionTaladroLargo', datos);
  }

  Future<int> insertarPerforacionTaladroHorizontal({
    required String zona,
    required String tipoLabor,
    required String labor,
    required String ala,
    required String veta,
    required String nivel,
    required String tipoPerforacion,
    required int operacionId, // ID de la Operacion relacionada
  }) async {
    final Database db =
        await DatabaseHelper_Mina2().database; // Obtener la base de datos

    // Crear el mapa con los datos a insertar
    Map<String, dynamic> datos = {
      'zona': zona,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'veta': veta,
      'nivel': nivel,
      'tipo_perforacion': tipoPerforacion,
      'operacion_id': operacionId, // Relación con la tabla Operacion
    };

    // Insertar en la base de datos y devolver el ID generado
    return await db.insert('PerforacionHorizontal', datos);
  }

  Future<int> insertarPerforacionSostenimiento({
    required String zona,
    required String tipoLabor,
    required String labor,
    required String ala,
    required String veta,
    required String nivel,
    required String tipoPerforacion,
    required int operacionId, // ID de la Operacion relacionada
  }) async {
    final Database db =
        await DatabaseHelper_Mina2().database; // Obtener la base de datos

    // Crear el mapa con los datos a insertar
    Map<String, dynamic> datos = {
      'zona': zona,
      'tipo_labor': tipoLabor,
      'labor': labor,
      'ala': ala,
      'veta': veta,
      'nivel': nivel,
      'tipo_perforacion': tipoPerforacion,
      'operacion_id': operacionId, // Relación con la tabla Operacion
    };

    // Insertar en la base de datos y devolver el ID generado
    return await db.insert('Sostenimiento', datos);
  }

  Future<List<Map<String, dynamic>>> getPerforacionesTaladroHorizontal(
      int operacionId) async {
    final db = await database;

    final List<Map<String, dynamic>> perforacionesRaw = await db.rawQuery('''
    SELECT id, zona, tipo_labor, labor, ala, veta, nivel, tipo_perforacion 
    FROM PerforacionHorizontal
    WHERE operacion_id = ?
  ''', [operacionId]);

    return perforacionesRaw.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  Future<List<Map<String, dynamic>>> getPerforacionesTaladroSostenimiento(
      int operacionId) async {
    final db = await database;

    final List<Map<String, dynamic>> perforacionesRaw = await db.rawQuery('''
    SELECT id, zona, tipo_labor, labor, ala, veta, nivel, tipo_perforacion 
    FROM Sostenimiento
    WHERE operacion_id = ?
  ''', [operacionId]);

    return perforacionesRaw.map((p) => Map<String, dynamic>.from(p)).toList();
  }

//Metodos de operaciones:
  Future<List<Map<String, dynamic>>> getOperacionByTurnoAndFecha(
      String turno, String fecha, String tipoOperacion) async {
    final db = await database; // Obtén una instancia de la base de datos

    // Consulta SQL buscando por turno, fecha y tipo_operacion
    final List<Map<String, dynamic>> result = await db.query(
      'Operacion',
      where: 'turno = ? AND fecha = ? AND tipo_operacion = ?',
      whereArgs: [turno, fecha, tipoOperacion],
    );

    return result; // Devuelve el resultado de la consulta
  }

  Future<List<Map<String, dynamic>>> getOperacionByTurnoAndFechaMaster(
      String turno, String fecha, String tipoOperacion) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Operacion',
      where:
          'turno = ? AND fecha = ? AND tipo_operacion = ? AND estado IN (?, ?)',
      whereArgs: [turno, fecha, tipoOperacion, 'activo', 'parciales'],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getOperacionBytipoOperacion(
      String tipoOperacion) async {
    final db = await database; // Obtén una instancia de la base de datos

    // Consulta SQL buscando por turno, fecha y tipo_operacion
    final List<Map<String, dynamic>> result = await db.query(
      'Operacion',
      where: 'tipo_operacion = ?',
      whereArgs: [tipoOperacion],
    );

    return result; // Devuelve el resultado de la consulta
  }

  Future<List<Map<String, dynamic>>> getOperacionPendienteByTipo(
      String tipoOperacion) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'Operacion',
      where:
          'tipo_operacion = ? AND ((estado = ?) OR (estado = ? AND envio < 1))',
      whereArgs: [tipoOperacion, 'parciales', 'cerrado'],
      orderBy: 'id DESC',
    );

    return result;
  }

  Future<int> insertOperacion(String turno, String equipo, String codigo,
      String empresa, String fecha, String tipoOperacion) async {
    final db = await database; // Obtén una instancia de la base de datos

    // Insertar los datos en la tabla 'Operacion'
    Map<String, dynamic> row = {
      'turno': turno,
      'equipo': equipo,
      'codigo': codigo,
      'empresa': empresa,
      'fecha': fecha,
      'tipo_operacion': tipoOperacion,
    };

    // Insertar operación y obtener el ID
    int operacionId = await db.insert(
      'Operacion',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insertar los tres Horometros
    List<String> nombresHorometros = ["Diesel", "Percusion", "Electrico"];

    for (String nombre in nombresHorometros) {
      Map<String, dynamic> horometroRow = {
        'operacion_id': operacionId,
        'nombre': nombre,
        'inicial': 0.0,
        'final': 0.0,
        'EstaOP': 0, // false
        'EstaINOP': 0 // false
      };

      await db.insert(
        'Horometros',
        horometroRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return operacionId; // Regresa el ID de la operación creada
  }

//Metodos de estados
  Future<int> createEstado(int operacionId, int numero, String estado,
      String codigo, String horaInicio, String horaFinal) async {
    final db = await database;

    return await db.insert(
      'Estado',
      {
        'operacion_id': operacionId,
        'numero': numero,
        'estado': estado,
        'codigo': codigo,
        'hora_inicio': horaInicio,
        'hora_final': horaFinal,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEstadosByOperacionId(
      int operacionId) async {
    final db = await database;
    return await db.query(
      'Estado',
      where: 'operacion_id = ?',
      whereArgs: [operacionId],
      orderBy: 'numero ASC', // o 'hora_inicio ASC'
    );
  }

  Future<int> updateHoraFinal(int id, String horaFinal) async {
    final db = await database;

    return await db.update(
      'Estado',
      {
        'hora_final': horaFinal,
      },
      where: 'id = ?', // Usamos el ID real
      whereArgs: [id],
    );
  }

  Future<int> deleteEstado(int id) async {
    final db = await database;

    return await db.delete(
      'Estado',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

//Metodos de Taladros
  Future<List<Map<String, dynamic>>> getTaladrosBySlotId(int slotId) async {
    final db = await database;
    return await db.query(
      'Taladro',
      where: 'slot_id = ?',
      whereArgs: [slotId],
    );
  }

  Future<int> createTaladro(
      int slotId, int ntaladro, double longitud2, double angulo2) async {
    final db = await database;

    Map<String, dynamic> data = {
      'slot_id': slotId, // Conexión con el Slot
      'ntaladro': ntaladro,
      'estado2': 'EJECUTADO',
      'longitud2': longitud2,
      'angulo2': angulo2,
      'tipo': 'B', // Tipo predeterminado
    };

    return await db.insert('Taladro', data);
  }

  Future<int> updateTaladro(
      int taladroId, double longitud2, double angulo2) async {
    final db = await database;

    Map<String, dynamic> data = {
      'longitud2': longitud2,
      'angulo2': angulo2,
    };

    return await db.update(
      'Taladro',
      data,
      where: 'id = ?',
      whereArgs: [taladroId],
    );
  }

  Future<int> deleteTaladro(int taladroId) async {
    final db = await database;

    // Eliminar el taladro con el ID proporcionado
    return await db.delete(
      'Taladro', // Nombre de la tabla
      where: 'id = ?', // Condición para buscar el taladro por ID
      whereArgs: [taladroId], // Argumento del ID para la consulta
    );
  }

//Usuarioss
// **Guardar Usuario en SQLite**
  Future<void> saveUser(Map<String, dynamic> userData, String password) async {
    final db = await database;
    final hashedPassword =
        Crypt.sha256(password).toString(); // Encriptar la contraseña

    await db.insert(
      'Usuario',
      {
        'codigo_dni': userData['codigo_dni'],
        'apellidos': userData['apellidos'],
        'nombres': userData['nombres'],
        'cargo': userData['cargo'],
        'empresa': userData['empresa'],
        'guardia': userData['guardia'],
        'autorizado_equipo': userData['autorizado_equipo'],
        'area': userData['area'], // Nuevo campo
        'clasificacion': userData['clasificacion'],
        'correo': userData['correo'],
        'password': hashedPassword,
        'firma': userData['firma'] ?? '',
        'rol': userData['rol']?.toString() ?? '',
        'createdAt': userData['createdAt'] ??
            DateTime.now().toIso8601String(), // Fecha de creación
        'updatedAt': userData['updatedAt'] ??
            DateTime.now().toIso8601String(), // Fecha de actualización

        'operaciones_autorizadas':
            jsonEncode(userData['operaciones_autorizadas'] ?? {}),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //Login cuando no hay conexion
  Future<bool> loginOffline(String dni, String password) async {
    final db = await DatabaseHelper_Mina2().database;
    final List<Map<String, dynamic>> result = await db.query(
      'Usuario',
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    if (result.isNotEmpty) {
      final storedPassword = result.first['password'];
      return Crypt(storedPassword).match(password); // <- Usa `.match()`
    }

    return false;
  }

//Lamar datos de usuario:
  Future<Map<String, dynamic>?> getUserByDni(String dni) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Usuario',
      where: 'codigo_dni = ?',
      whereArgs: [dni],
    );

    if (result.isNotEmpty) {
      return result.first; // Devuelve el primer usuario encontrado
    }
    return null; // Devuelve null si no hay usuario con ese DNI
  }

//Estados api:
  // Obtener todos los estados de la tabla `EstadostBD`
  Future<List<Map<String, dynamic>>> getEstadosBD(String proceso) async {
    final db = await database; // Obtiene la instancia de la base de datos
    return await db.query(
      'EstadostBD',
      where: 'proceso = ?',
      whereArgs: [proceso], // Filtra por el valor del proceso
    );
  }

  Future<List<Map<String, dynamic>>> getEstadosBDOPERATIVO(
      String proceso) async {
    final db = await database; // Obtiene la instancia de la base de datos
    return await db.query(
      'EstadostBD',
      where: 'proceso = ? AND estado_principal = ?',
      whereArgs: [
        proceso,
        'OPERATIVO'
      ], // Filtra por proceso y tipo_estado = 'OPERATIVO'
    );
  }

//EXPLOSIVOSSSSS

// Obtener todos los registros de la tabla
  Future<List<Map<String, dynamic>>> getExploraciones() async {
    final db = await database;
    return await db.query(
      'Datos_trabajo_exploraciones',
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getExploracionesPendientes() async {
    final db = await database;
    return await db.query(
      'Datos_trabajo_exploraciones',
      where: 'envio = 0 AND cerrado = 1',
      orderBy: 'id DESC',
    );
  }

  // Insertar un nuevo registro (solamente fecha y turno)
  Future<int> insertExploracion(
      String fecha,
      String turno,
      String semanaDefault,
      Map<String, String> materialesDespacho,
      Map<String, String> materialesDevolucion) async {
    final db = await database;

    // Insertar en Datos_trabajo_exploraciones y obtener el ID generado
    int idExploracion = await db.insert(
      'Datos_trabajo_exploraciones',
      {
        'fecha': fecha,
        'turno': turno,
        'semanaDefault': semanaDefault,
        'estado': 'Creado',
      },
    );

    // Insertar un registro vacío en Despacho
    int idDespacho = await db.insert(
      'Despacho',
      {
        'datos_trabajo_id': idExploracion,
        'mili_segundo': 0.0,
        'medio_segundo': 0.0,
      },
    );

    // Insertar los detalles del despacho (materiales)
    materialesDespacho.forEach((nombreMaterial, cantidad) async {
      await db.insert(
        'DespachoDetalle',
        {
          'despacho_id': idDespacho,
          'nombre_material': nombreMaterial,
          'cantidad': cantidad,
        },
      );
    });

    // Insertar un registro vacío en Devoluciones
    int idDevolucion = await db.insert(
      'Devoluciones',
      {
        'datos_trabajo_id': idExploracion,
        'mili_segundo': 0.0,
        'medio_segundo': 0.0,
      },
    );

    // Insertar los detalles de la devolución (materiales)
    materialesDevolucion.forEach((nombreMaterial, cantidad) async {
      await db.insert(
        'DevolucionDetalle',
        {
          'devolucion_id': idDevolucion,
          'nombre_material': nombreMaterial,
          'cantidad': cantidad,
        },
      );
    });

    return idExploracion;
  }

  Future<int> updateEstadoExploracion(int id, String nuevoEstado) async {
    final db = await database;

    return await db.update(
      'Datos_trabajo_exploraciones',
      {'estado': nuevoEstado}, // Nuevo estado
      where: 'id = ?',
      whereArgs: [id], // Filtro por ID
    );
  }

  // Obtener un registro de Datos_trabajo_exploraciones por id
  Future<Map<String, dynamic>?> getExploracionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

// Actualizar un registro de Datos_trabajo_exploraciones

  Future<int> updateExploracion(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'Datos_trabajo_exploraciones',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Inserta un registro completo en Datos_trabajo_exploraciones
  Future<int> insertExploracionFull(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('Datos_trabajo_exploraciones', row);
  }

  Future<bool> eliminarEstructuraCompletaManual(int idExploracion) async {
    final db = await database;

    // Verificar si el registro está cerrado
    List<Map<String, dynamic>> resultado = await db.query(
      'Datos_trabajo_exploraciones',
      columns: ['cerrado'],
      where: 'id = ?',
      whereArgs: [idExploracion],
    );

    if (resultado.isNotEmpty && resultado.first['cerrado'] == 1) {
      print("El registro ya está cerrado y no se puede eliminar.");
      return false;
    }

    return await db.transaction((txn) async {
      // Eliminar primero los detalles de Despacho y Devoluciones
      await txn.delete(
        'DespachoDetalle',
        where:
            'despacho_id IN (SELECT id FROM Despacho WHERE datos_trabajo_id = ?)',
        whereArgs: [idExploracion],
      );

      await txn.delete(
        'DevolucionDetalle',
        where:
            'devolucion_id IN (SELECT id FROM Devoluciones WHERE datos_trabajo_id = ?)',
        whereArgs: [idExploracion],
      );

      // Eliminar los detalles de explosivos
      await txn.delete(
        'DetalleDespachoExplosivos',
        where:
            'id_despacho IN (SELECT id FROM Despacho WHERE datos_trabajo_id = ?)',
        whereArgs: [idExploracion],
      );

      await txn.delete(
        'DetalleDevolucionesExplosivos',
        where:
            'id_devolucion IN (SELECT id FROM Devoluciones WHERE datos_trabajo_id = ?)',
        whereArgs: [idExploracion],
      );

      // Eliminar los registros principales de Despacho y Devoluciones
      await txn.delete('Despacho',
          where: 'datos_trabajo_id = ?', whereArgs: [idExploracion]);
      await txn.delete('Devoluciones',
          where: 'datos_trabajo_id = ?', whereArgs: [idExploracion]);

      // Finalmente, eliminar la exploración principal
      await txn.delete('Datos_trabajo_exploraciones',
          where: 'id = ?', whereArgs: [idExploracion]);

      return true;
    });
  }

  Future<void> cerrarRegistro(int idExploracion) async {
    final db = await database;
    await db.update(
      'Datos_trabajo_exploraciones',
      {'cerrado': 1}, // Marcar como cerrado
      where: 'id = ?',
      whereArgs: [idExploracion],
    );
  }

  Future<bool> estaRegistroCerrado(int idExploracion) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Datos_trabajo_exploraciones',
      columns: ['cerrado'],
      where: 'id = ?',
      whereArgs: [idExploracion],
    );

    if (result.isNotEmpty) {
      return result.first['cerrado'] == 1;
    }
    return false; // Si no encuentra el registro, asumimos que no está cerrado
  }

//----------------------------------------------------------------
//Validacion de datos que sean menor o igual a despacho:
  Future<Map<String, double>> obtenerCantidadesDespachadas(
      int datosTrabajoId) async {
    final db = await database;

    // Obtener cantidades de materiales despachados
    final despachoDetalle = await db.query(
      'DespachoDetalle',
      where:
          'despacho_id IN (SELECT id FROM Despacho WHERE datos_trabajo_id = ?)',
      whereArgs: [datosTrabajoId],
    );

    // Obtener cantidades de explosivos despachados
    final despachoExplosivos = await db.query(
      'DetalleDespachoExplosivos',
      where:
          'id_despacho IN (SELECT id FROM Despacho WHERE datos_trabajo_id = ?)',
      whereArgs: [datosTrabajoId],
    );

    // Crear un mapa con las cantidades despachadas
    Map<String, double> cantidadesDespachadas = {};

    for (var detalle in despachoDetalle) {
      String nombreMaterial = detalle['nombre_material'] as String;
      double cantidad = double.tryParse(detalle['cantidad'] as String) ?? 0.0;
      cantidadesDespachadas[nombreMaterial] = cantidad;
    }

    for (var explosivo in despachoExplosivos) {
      String clave =
          'ms_cant1_${explosivo['numero']}'; // Clave única para ms_cant1
      double cantidad = double.tryParse(explosivo['ms_cant1'] as String) ?? 0.0;
      cantidadesDespachadas[clave] = cantidad;

      clave = 'lp_cant1_${explosivo['numero']}'; // Clave única para lp_cant1
      cantidad = double.tryParse(explosivo['lp_cant1'] as String) ?? 0.0;
      cantidadesDespachadas[clave] = cantidad;
    }

    return cantidadesDespachadas;
  }

//Despacho------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getDetalleDespachoByExploracionId(
      int exploracionId) async {
    final db = await database;
    return await db.query(
      'Despacho',
      where: 'datos_trabajo_id = ?', // Corrección aquí
      whereArgs: [exploracionId],
    );
  }

  Future<List<Map<String, dynamic>>>
      getDetalleDespachoByDesapachoExposivosyAccesorios(int despachoId) async {
    final db = await database; // Obtiene la instancia de la base de datos
    return await db.query(
      'DespachoDetalle', // Nombre de la tabla a consultar
      where:
          'despacho_id = ?', // Condición de búsqueda: despacho_id debe coincidir
      whereArgs: [
        despachoId
      ], // Se pasa el valor de despachoId para evitar inyección SQL
    );
  }

  Future<List<Map<String, dynamic>>> getDetalleDevolucionByDevolucionId(
      int devolucionId) async {
    final db = await database; // Obtiene la instancia de la base de datos
    return await db.query(
      'DevolucionDetalle', // Nombre de la tabla
      where: 'devolucion_id = ?', // Filtra por el ID de la devolución
      whereArgs: [
        devolucionId
      ], // Se pasa el ID como argumento para evitar inyección SQL
    );
  }

  Future<List<Map<String, dynamic>>> getDetalleDespachoByDespachoId(
      int despachoId) async {
    final db = await database;
    return await db.query(
      'DetalleDespachoExplosivos',
      where: 'id_despacho = ?',
      whereArgs: [despachoId],
    );
  }

  Future<void> insertDetallesDespacho(
      int idDespacho, List<Map<String, dynamic>> detalles) async {
    final db = await database;

    for (var detalle in detalles) {
      if (detalle['ms_cant1'].isNotEmpty || detalle['lp_cant1'].isNotEmpty) {
        await db.insert(
          'DetalleDespachoExplosivos',
          {
            'id_despacho':
                idDespacho, // Debe ser id_despacho en lugar de id_exploracion
            'numero': detalle['numero'],
            'ms_cant1': detalle['ms_cant1'],
            'lp_cant1': detalle['lp_cant1'],
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace, // Reemplaza si ya existe
        );
      }
    }
  }

  Future<int> updateDetalleDespacho({
    required int id,
    required int numero,
    required String msCant1,
    required String lpCant1,
  }) async {
    final db = await database;
    return await db.update(
      'DetalleDespachoExplosivos',
      {
        'numero': numero,
        'ms_cant1': msCant1,
        'lp_cant1': lpCant1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDespacho(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'Despacho',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDespachoDetalle(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'DespachoDetalle',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDevolucionDetalle(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'DevolucionDetalle',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarDetalleDespacho(int idDespacho, String detalle) async {
    final db = await database;
    return await db.update(
      'Despacho',
      {'observaciones': detalle},
      where: 'id = ?',
      whereArgs: [idDespacho],
    );
  }

  Future<int> actualizarDetalleDevolucion(
      int idDevolucion, String detalle) async {
    final db = await database;
    return await db.update(
      'Devoluciones',
      {'observaciones': detalle},
      where: 'id = ?',
      whereArgs: [idDevolucion],
    );
  }

  Future<int> actualizarTiemposDespacho(
      int idDespacho, double? milisegundo, double? medioSegundo) async {
    final db = await database;

    Map<String, dynamic> valores = {};
    if (milisegundo != null) valores['mili_segundo'] = milisegundo;
    if (medioSegundo != null) valores['medio_segundo'] = medioSegundo;

    if (valores.isEmpty) return 0; // Nada que actualizar

    return await db.update(
      'Despacho',
      valores,
      where: 'id = ?',
      whereArgs: [idDespacho],
    );
  }

  Future<int> actualizarTiemposDevoluciones(
      int _DevolucionesId, double? milisegundo, double? medioSegundo) async {
    final db = await database;

    Map<String, dynamic> valores = {};
    if (milisegundo != null) valores['mili_segundo'] = milisegundo;
    if (medioSegundo != null) valores['medio_segundo'] = medioSegundo;

    if (valores.isEmpty) return 0; // Nada que actualizar

    return await db.update(
      'Devoluciones',
      valores,
      where: 'id = ?',
      whereArgs: [_DevolucionesId],
    );
  }

//Devoluciones------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getDetalleDevolucionesByExploracionId(
      int exploracionId) async {
    final db = await database;
    return await db.query(
      'Devoluciones',
      where: 'datos_trabajo_id = ?', // Corrección aquí
      whereArgs: [exploracionId],
    );
  }

  Future<List<Map<String, dynamic>>> getDetalleDevolucionesByDevolucionesId(
      int _DevolucionesId) async {
    final db = await database;
    return await db.query(
      'DetalleDevolucionesExplosivos',
      where: 'id_devolucion = ?',
      whereArgs: [_DevolucionesId],
    );
  }

  Future<void> insertDetallesDevoluciones(
      int _DevolucionesId, List<Map<String, dynamic>> detalles) async {
    final db = await database;

    for (var detalle in detalles) {
      if (detalle['ms_cant1'].isNotEmpty || detalle['lp_cant1'].isNotEmpty) {
        await db.insert(
          'DetalleDevolucionesExplosivos',
          {
            'id_devolucion':
                _DevolucionesId, // Debe ser id_devolucion en lugar de id_exploracion
            'numero': detalle['numero'],
            'ms_cant1': detalle['ms_cant1'],
            'lp_cant1': detalle['lp_cant1'],
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace, // Reemplaza si ya existe
        );
      }
    }
  }

  Future<int> updateDetalleDevoluciones({
    required int id,
    required int numero,
    required String msCant1,
    required String lpCant1,
  }) async {
    final db = await database;
    return await db.update(
      'DetalleDevolucionesExplosivos',
      {
        'numero': numero,
        'ms_cant1': msCant1,
        'lp_cant1': lpCant1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDevoluciones(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'Devoluciones',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

//PLAN MENSUAL
  Future<int> insertPlan(PlanMensual plan) async {
    final db = await database;
    return await db.insert('PlanMensual', plan.toMap());
  }

  Future<List<PlanMensual>> getPlanes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('PlanMensual');
    return List.generate(maps.length, (i) => PlanMensual.fromJson(maps[i]));
  }

  Future<List<PlanProduccion>> getPlanesProduccion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('PlanProduccion');
    return List.generate(maps.length, (i) => PlanProduccion.fromJson(maps[i]));
  }

  Future<List<PlanMetraje>> getPlanesMetraje() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('PlanMetraje');
    return List.generate(maps.length, (i) => PlanMetraje.fromJson(maps[i]));
  }

  Future<List<TipoPerforacion>> getTiposPerforacion() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('TipoPerforacion');
    return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
  }

  Future<List<TipoPerforacion>> getTiposPerforacionhorizontal() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'TipoPerforacion',
    where: 'proceso = ?',
    whereArgs: ['PERFORACIÓN HORIZONTAL'],
  );
  return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
}

  Future<List<TipoPerforacion>> getTiposPerforacionLargo() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'TipoPerforacion',
    where: 'proceso = ?',
    whereArgs: ['PERFORACIÓN TALADROS LARGOS'],
  );
  return List.generate(maps.length, (i) => TipoPerforacion.fromJson(maps[i]));
}

  Future<List<Empresa>> getEmpresas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Empresa');
    return List.generate(maps.length, (i) => Empresa.fromJson(maps[i]));
  }

  Future<List<Equipo>> getEquipos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Equipo');
    return List.generate(maps.length, (i) => Equipo.fromJson(maps[i]));
  }

//Exportar pdf:
  Future<List<Map<String, dynamic>>> obtenerEstructuraCompleta(
      int idPadre) async {
    final Database db = await database;

    // Obtener los datos del padre
    List<Map<String, dynamic>> datosTrabajo = await db.query(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [idPadre],
    );

    if (datosTrabajo.isEmpty) return [];

    // Obtener despacho relacionado con el padre
    List<Map<String, dynamic>> despachosRaw = await db.query(
      'Despacho',
      where: 'datos_trabajo_id = ?',
      whereArgs: [idPadre],
    );

    List<Map<String, dynamic>> despachos = [];
    for (var despacho in despachosRaw) {
      int despachoId = despacho['id'];

      // Obtener los detalles del despacho (explosivos)
      List<Map<String, dynamic>> detallesExplosivos = await db.query(
        'DetalleDespachoExplosivos',
        where: 'id_despacho = ?',
        whereArgs: [despachoId],
      );

      // Obtener los detalles del despacho (materiales)
      List<Map<String, dynamic>> detallesMateriales = await db.query(
        'DespachoDetalle',
        where: 'despacho_id = ?',
        whereArgs: [despachoId],
      );

      // Crear un nuevo mapa copiando los valores
      Map<String, dynamic> despachoModificado =
          Map<String, dynamic>.from(despacho);
      despachoModificado['detalles_explosivos'] = detallesExplosivos;
      despachoModificado['detalles_materiales'] = detallesMateriales;
      despachos.add(despachoModificado);
    }

    // Obtener devoluciones relacionadas con el padre
    List<Map<String, dynamic>> devolucionesRaw = await db.query(
      'Devoluciones',
      where: 'datos_trabajo_id = ?',
      whereArgs: [idPadre],
    );

    List<Map<String, dynamic>> devoluciones = [];
    for (var devolucion in devolucionesRaw) {
      int devolucionId = devolucion['id'];

      // Obtener los detalles de la devolución (explosivos)
      List<Map<String, dynamic>> detallesExplosivos = await db.query(
        'DetalleDevolucionesExplosivos',
        where: 'id_devolucion = ?',
        whereArgs: [devolucionId],
      );

      // Obtener los detalles de la devolución (materiales)
      List<Map<String, dynamic>> detallesMateriales = await db.query(
        'DevolucionDetalle',
        where: 'devolucion_id = ?',
        whereArgs: [devolucionId],
      );

      // Crear un nuevo mapa copiando los valores
      Map<String, dynamic> devolucionModificada =
          Map<String, dynamic>.from(devolucion);
      devolucionModificada['detalles_explosivos'] = detallesExplosivos;
      devolucionModificada['detalles_materiales'] = detallesMateriales;
      devoluciones.add(devolucionModificada);
    }

    // Estructurar la respuesta
    return datosTrabajo.map((dato) {
      return {
        ...dato,
        'despachos': despachos,
        'devoluciones': devoluciones,
      };
    }).toList();
  }

  Future<List<Accesorio>> getAccesorios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accesorios');

    return List.generate(maps.length, (i) => Accesorio.fromJson(maps[i]));
  }

  Future<List<ExplosivosUni>> getExplosivosUni() async {
    final db = await database; // Obtener la instancia de la base de datos
    final List<Map<String, dynamic>> maps =
        await db.query('ExplosivosUni'); // Consultar la tabla

    return List.generate(
        maps.length,
        (i) => ExplosivosUni.fromJson(
            maps[i])); // Convertir los resultados en objetos
  }

  Future<List<DestinatarioCorreo>> getDestinatariosCorreo() async {
    final db = await database; // Obtener la instancia de la base de datos
    final List<Map<String, dynamic>> maps =
        await db.query('destinatarios_correo'); // Consultar la tabla

    return List.generate(
        maps.length,
        (i) => DestinatarioCorreo.fromJson(
            maps[i])); // Convertir los resultados en objetos
  }

  Future<List<Explosivo>> getExplosivos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('explosivos');

    return List.generate(maps.length, (i) => Explosivo.fromJson(maps[i]));
  }

  Future<List<Map<String, String>>> getAccesoriosunidad() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('accesorios', columns: ['tipo_accesorio', 'unidad_medida']);

    return maps
        .map((map) => {
              'tipo': map['tipo_accesorio'] as String,
              'unidad_medida': map['unidad_medida'] as String
            })
        .toList();
  }

  Future<List<Map<String, String>>> getExplosivosunidad() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('explosivos', columns: ['tipo_explosivo', 'unidad_medida']);

    return maps
        .map((map) => {
              'tipo': map['tipo_explosivo'] as String,
              'unidad_medida': map['unidad_medida'] as String
            })
        .toList();
  }

//TaladroLargo----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInterPerforacionesTaladroLargo(
      int perforacionTaladroLargoId) async {
    final db = await database;

    final List<Map<String, dynamic>> interPerforacionesRaw =
        await db.rawQuery('''
    SELECT id, codigo_actividad, nivel, tajo, nbroca, ntaladro, nbarras, 
           longitud_perforacion, angulo_perforacion, nfilas_de_hasta, 
           detalles_trabajo_realizado, perforaciontaladrolargo_id
    FROM InterPerforacionTaladroLargo
    WHERE perforaciontaladrolargo_id = ?
  ''', [perforacionTaladroLargoId]);

    return interPerforacionesRaw
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  Future<int> updateInterPerforacionTaladroLargo(
      int id, Map<String, dynamic> updatedData) async {
    final db = await database;

    return await db.update(
      'InterPerforacionTaladroLargo',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertInterPerforacionTaladroLargo(
    int perforacionTaladroLargoId,
    String codigoActividad,
    String nivel,
    String tajo,
    int nbroca,
    int ntaladro,
    int nbarras,
    double longitudPerforacion,
    double anguloPerforacion,
    String nfilasDeHasta,
    String detallesTrabajoRealizado,
  ) async {
    final db = await database;

    return await db.insert(
      'InterPerforacionTaladroLargo',
      {
        'codigo_actividad': codigoActividad,
        'nivel': nivel,
        'tajo': tajo,
        'nbroca': nbroca,
        'ntaladro': ntaladro,
        'nbarras': nbarras,
        'longitud_perforacion': longitudPerforacion,
        'angulo_perforacion': anguloPerforacion,
        'nfilas_de_hasta': nfilasDeHasta,
        'detalles_trabajo_realizado': detallesTrabajoRealizado,
        'perforaciontaladrolargo_id': perforacionTaladroLargoId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteInterPerforacionTaladroLargo(int id) async {
    final db = await database;
    return await db.delete(
      'InterPerforacionTaladroLargo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

//TaladroHorizontal----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInterPerforacionesHorizontal(
      int perforacionHorizontalId) async {
    final db = await database;

    final List<Map<String, dynamic>> interPerforacionesRaw =
        await db.rawQuery('''
    SELECT id, codigo_actividad, nivel, labor, seccion_la_labor, nbroca, ntaladro, 
           ntaladros_rimados, longitud_perforacion, detalles_trabajo_realizado, perforacionhorizontal_id
    FROM InterPerforacionHorizontal
    WHERE perforacionhorizontal_id = ?
  ''', [perforacionHorizontalId]);

    return interPerforacionesRaw
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  Future<int> updateInterPerforacionHorizontal(
      int id, Map<String, dynamic> updatedData) async {
    final db = await database;

    return await db.update(
      'InterPerforacionHorizontal',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInterPerforacionHorizontal(int id) async {
    final db = await database;

    return await db.delete(
      'InterPerforacionHorizontal',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertInterPerforacionHorizontal(
    int perforacionHorizontalId,
    String codigoActividad,
    String nivel,
    String labor,
    String seccionLabor,
    int nbroca,
    int ntaladro,
    int ntaladrosRimados,
    double longitudPerforacion,
    String detallesTrabajoRealizado,
  ) async {
    final db = await database;

    return await db.insert(
      'InterPerforacionHorizontal',
      {
        'codigo_actividad': codigoActividad,
        'nivel': nivel,
        'labor': labor,
        'seccion_la_labor': seccionLabor,
        'nbroca': nbroca,
        'ntaladro': ntaladro,
        'ntaladros_rimados': ntaladrosRimados,
        'longitud_perforacion': longitudPerforacion,
        'detalles_trabajo_realizado': detallesTrabajoRealizado,
        'perforacionhorizontal_id': perforacionHorizontalId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

//Sostenimiento----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getInterSostenimientos(
      int sostenimientoId) async {
    final db = await database;

    final List<Map<String, dynamic>> interSostenimientosRaw =
        await db.rawQuery('''
    SELECT id, codigo_actividad, nivel, labor, seccion_de_labor, nbroca, ntaladro, 
           longitud_perforacion, malla_instalada, sostenimiento_id
    FROM InterSostenimiento
    WHERE sostenimiento_id = ?
  ''', [sostenimientoId]);

    return interSostenimientosRaw
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  Future<int> updateInterSostenimiento(
      int id, Map<String, dynamic> updatedData) async {
    final db = await database;

    return await db.update(
      'InterSostenimiento',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertInterSostenimiento(
    int sostenimientoId,
    String codigoActividad,
    String nivel,
    String labor,
    String seccionLabor,
    int nbroca,
    int ntaladro,
    double longitudPerforacion,
    String mallaInstalada,
  ) async {
    final db = await database;

    return await db.insert(
      'InterSostenimiento',
      {
        'codigo_actividad': codigoActividad,
        'nivel': nivel,
        'labor': labor,
        'seccion_de_labor': seccionLabor,
        'nbroca': nbroca,
        'ntaladro': ntaladro,
        'longitud_perforacion': longitudPerforacion,
        'malla_instalada': mallaInstalada,
        'sostenimiento_id': sostenimientoId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteInterostenimiento(int id) async {
    final db = await database;

    return await db.delete(
      'InterSostenimiento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
//Horometros--------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getHorometrosByOperacion(
      int operacionId) async {
    final db = await database;
    return await db.query(
      'Horometros',
      where: 'operacion_id = ?',
      whereArgs: [operacionId],
    );
  }

  Future<void> updateHorometro(Map<String, dynamic> horometro) async {
    final db = await database;
    await db.update(
      'horometros',
      {
        'inicial': horometro["inicial"],
        'final': horometro["final"],
        'EstaOP': horometro["EstaOP"],
        'EstaINOP': horometro["EstaINOP"],
      },
      where: 'id = ?',
      whereArgs: [horometro["id"]],
    );
  }

  Future<void> cerrarOperacion(int operacionId) async {
    final Database db = await DatabaseHelper_Mina2().database;

    await db.update(
      'Operacion',
      {'estado': 'cerrado'}, // Nuevo estado
      where: 'id = ?',
      whereArgs: [operacionId], // Parámetro para evitar SQL Injection
    );
  }

//--------------------------------------------------------------------------------
  Future<int> actualizarEnvio(int id) async {
    final db = await database;

    // Mapa de los datos que quieres actualizar
    Map<String, dynamic> data = {
      'envio': 1, // Actualiza el campo envio a 1
    };

    // Llamada a la función update
    return await db.update(
      'Operacion', // El nombre de la tabla
      data, // Los datos a actualizar
      where: 'id = ?', // Condición para seleccionar la fila
      whereArgs: [id], // El valor de id para seleccionar la fila específica
    );
  }

  Future<int> actualizarEnvioParcial(int id) async {
    final db = await database;

    // Mapa de los datos que quieres actualizar
    Map<String, dynamic> data = {
      'envio': 0.5, // Actualiza el campo envio a 1
    };

    // Llamada a la función update
    return await db.update(
      'Operacion', // El nombre de la tabla
      data, // Los datos a actualizar
      where: 'id = ?', // Condición para seleccionar la fila
      whereArgs: [id], // El valor de id para seleccionar la fila específica
    );
  }

  Future<int> actualizarEnvioDatos_trabajo_exploraciones(int id) async {
    final db = await database;

    // Mapa de los datos que quieres actualizar
    Map<String, dynamic> data = {
      'envio': 1, // Actualiza el campo envio a 1
    };

    // Llamada a la función update
    return await db.update(
      'Datos_trabajo_exploraciones', // El nombre de la tabla
      data, // Los datos a actualizar
      where: 'id = ?', // Condición para seleccionar la fila
      whereArgs: [id], // El valor de id para seleccionar la fila específica
    );
  }

//-------------------------------------------------------------------
  Future<Map<String, dynamic>?> getPlanMensual({
    required String zona,
    required String tipoLabor,
    required String labor,
    required String estructuraVeta,
    required String nivel,
  }) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.query(
      'PlanMensual',
      columns: ['ancho_m', 'alto_m'], // Solo obtenemos estos campos
      where:
          'zona = ? AND tipo_labor = ? AND labor = ? AND estructura_veta = ? AND nivel = ?',
      whereArgs: [zona, tipoLabor, labor, estructuraVeta, nivel],
    );

    // Verificar si se encontraron resultados
    if (result.isNotEmpty) {
      return result
          .first; // Retorna solo los campos requeridos del primer registro encontrado
    } else {
      return null; // No se encontraron registros que coincidan
    }
  }

  Future<int> deleteOperacion(int id) async {
    final db = await database;
    return await db.delete(
      'Operacion',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDatosTrabajo(int id) async {
    final db = await database;
    return await db.delete(
      'Datos_trabajo_exploraciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

//---------------------------------------------------MEDICIONES------------------------------------------------------------
Future<void> actualizarMedicionEXplosivo(List<int> ids) async {
  final db = await database;

  // Construir placeholders dinámicos (?, ?, ?)
  final placeholders = List.filled(ids.length, '?').join(',');

  await db.rawUpdate(
    'UPDATE nube_Datos_trabajo_exploraciones SET medicion = 1 WHERE id IN ($placeholders)',
    ids,
  );
}

Future<void> actualizarMedicionExplosivoACero(List<int> ids) async {
  if (ids.isEmpty) return; // ✅ Evita ejecución si la lista está vacía

  final db = await database;

  // Construir placeholders dinámicos (?, ?, ?)
  final placeholders = List.filled(ids.length, '?').join(',');

  await db.rawUpdate(
    'UPDATE nube_Datos_trabajo_exploraciones SET medicion = 0 WHERE id IN ($placeholders)',
    ids,
  );
}


//horizontal
Future<int> insertarMedicionHorizontal(Map<String, dynamic> datos) async {
  final db = await database;
  return await db.insert(
    'mediciones_horizontal',
    datos,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


Future<List<Map<String, dynamic>>> obtenerTodasMedicionesHorizontal() async {
  final db = await database;
  final List<Map<String, dynamic>> result = await db.query(
    'mediciones_horizontal',
    orderBy: 'fecha DESC', // Ordenar por fecha descendente
  );
  return result;
}

Future<Map<String, dynamic>?> obtenerMedicionHorizontalPorId(int id) async {
  final Database db = await database;

  // Obtener el registro de mediciones_horizontal con el ID especificado
  List<Map<String, dynamic>> mediciones = await db.query(
    'mediciones_horizontal',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (mediciones.isEmpty) return null;

  // Retornar el primer registro como Map<String, dynamic>
  return mediciones.first;
}


Future<List<Map<String, dynamic>>> obtenerTodasMedicionesHorizontalPendientesEnvio() async {
  final db = await database;
  final List<Map<String, dynamic>> result = await db.query(
    'mediciones_horizontal',
    where: 'envio = ?',
    whereArgs: [0],
    orderBy: 'fecha DESC', // Ordenar por fecha descendente
  );
  return result;
}

Future<int> eliminarMultiplesMedicionesHorizontal(List<int> ids) async {
  if (ids.isEmpty) return 0;
  
  final db = await database;
  final placeholders = List.filled(ids.length, '?').join(',');
  
  return await db.delete(
    'mediciones_horizontal',
    where: 'id IN ($placeholders)',
    whereArgs: ids,
  );
}

Future<int> actualizarEnvioMedicionesHorizontal(List<int> ids) async {
  final db = await database;
  final idPlaceholders = List.filled(ids.length, '?').join(', ');

  return await db.update(
    'mediciones_horizontal',
    {'envio': 1},
    where: 'id IN ($idPlaceholders)',
    whereArgs: ids,
  );
}


//Largo
Future<int> insertarMedicionLargo(Map<String, dynamic> datos) async {
  final db = await database;
  return await db.insert(
    'mediciones_largo',
    datos,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
Future<List<Map<String, dynamic>>> obtenerTodasMedicionesLargo() async {
  final db = await database;
  final List<Map<String, dynamic>> result = await db.query(
    'mediciones_largo',
    orderBy: 'fecha DESC', // Ordenar por fecha descendente
  );
  return result;
}

Future<int> eliminarMultiplesMedicionesLargo(List<int> ids) async {
  if (ids.isEmpty) return 0;
  
  final db = await database;
  final placeholders = List.filled(ids.length, '?').join(',');
  
  return await db.delete(
    'mediciones_largo',
    where: 'id IN ($placeholders)',
    whereArgs: ids,
  );
}

Future<Map<String, dynamic>?> obtenerMedicionLargoPorId(int id) async {
  final Database db = await database;

  // Obtener el registro de mediciones_horizontal con el ID especificado
  List<Map<String, dynamic>> mediciones = await db.query(
    'mediciones_largo',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (mediciones.isEmpty) return null;

  // Retornar el primer registro como Map<String, dynamic>
  return mediciones.first;
}

Future<int> actualizarEnvioMedicionesLargo(List<int> ids) async {
  final db = await database;
  final idPlaceholders = List.filled(ids.length, '?').join(', ');

  return await db.update(
    'mediciones_largo',
    {'envio': 1},
    where: 'id IN ($idPlaceholders)',
    whereArgs: ids,
  );
}



//------------------------------------------------------------------------------------------------------------------------

  Future<int> actualizarEstadoAParciales(int idOperacion) async {
    final db = await database;

    return await db.update(
      'Operacion',
      {'estado': 'parciales'},
      where: 'id = ?',
      whereArgs: [idOperacion],
    );
  }

  Future<int> actualizarIdNubeOperacion(int idOperacion, int idNube) async {
    final db = await database;
    return await db.update(
      'Operacion',
      {'idNube': idNube},
      where: 'id = ?',
      whereArgs: [idOperacion],
    );
  }

  Future<void> exportDatabaseToSql(String outputPath) async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");

    final sqlFile = File(outputPath);
    final sink = sqlFile.openWrite();

    try {
      // Escribir encabezado SQL
      sink.writeln('-- Exportación SQL de Seminco');
      sink.writeln('-- Fecha: ${DateTime.now()}');
      sink.writeln('-- Usuario: $_currentUserDni');
      sink.writeln('BEGIN TRANSACTION;');
      sink.writeln();

      // Exportar estructura y datos de cada tabla
      for (final table in tables) {
        final tableName = table['name'] as String;

        // 1. Exportar estructura de la tabla
        final createTable = await db.rawQuery(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name='$tableName'");
        sink.writeln('${createTable.first['sql']};');
        sink.writeln();

        // 2. Exportar datos de la tabla
        final data = await db.query(tableName);
        if (data.isNotEmpty) {
          final columns = data.first.keys.toList();
          sink.writeln('-- Datos para la tabla $tableName');

          for (final row in data) {
            final values = columns.map((col) {
              final value = row[col];
              if (value == null) return 'NULL';
              if (value is String) return "'${value.replaceAll("'", "''")}'";
              if (value is DateTime) return "'${value.toIso8601String()}'";
              return value.toString();
            }).join(', ');

            sink.writeln(
                'INSERT INTO $tableName (${columns.join(', ')}) VALUES ($values);');
          }
          sink.writeln();
        }
      }

      sink.writeln('COMMIT;');
      await sink.flush();
      print('Base de datos exportada a: $outputPath');
    } catch (e) {
      print('Error al exportar la base de datos: $e');
      rethrow;
    } finally {
      await sink.close();
    }
  }


  //EXPLOSIVOS PARA MEDICIONES------------------------------------------

Future<List<Map<String, dynamic>>> obtenerExploracionesCompletas() async {
  try {
    final Database db = await database;
    
    // Obtener solo las exploraciones con medicion = 0
    final List<Map<String, dynamic>> exploraciones = await db.query(
      'nube_Datos_trabajo_exploraciones',
      where: 'medicion = ?',
      whereArgs: [0],
      orderBy: 'fecha DESC, turno DESC',
    );

    if (exploraciones.isEmpty) return [];

    List<Map<String, dynamic>> resultado = [];

    for (var exploracion in exploraciones) {
      // Crear un nuevo mapa mutable para la exploración
      Map<String, dynamic> exploracionCompleta = Map<String, dynamic>.from(exploracion);
      int exploracionId = exploracion['id'];
      String idnube = exploracion['idnube']?.toString() ?? '';

      // Obtener despachos relacionados
      exploracionCompleta['despachos'] = await _obtenerDespachosPorExploracion(exploracionId);
      
      // Obtener devoluciones relacionadas
      exploracionCompleta['devoluciones'] = await _obtenerDevolucionesPorExploracion(exploracionId);
      
      // Asegurar que idnube está incluido
      exploracionCompleta['idnube'] = idnube;

      resultado.add(exploracionCompleta);
    }

    return resultado;
  } catch (e) {
    print('Error al obtener exploraciones completas: $e');
    return [];
  }
}


Future<List<Map<String, dynamic>>> _obtenerDespachosPorExploracion(int exploracionId) async {
  final Database db = await database;
  final List<Map<String, dynamic>> despachos = await db.query(
    'nube_Despacho',
    where: 'datos_trabajo_id = ?',
    whereArgs: [exploracionId],
  );

  List<Map<String, dynamic>> despachosCompletos = [];

  for (var despacho in despachos) {
    // Crear un nuevo mapa mutable para el despacho
    Map<String, dynamic> despachoCompleto = Map<String, dynamic>.from(despacho);
    int despachoId = despacho['id'];
    
    // Obtener detalles normales del despacho
    despachoCompleto['detalles'] = await db.query(
      'nube_DespachoDetalle',
      where: 'despacho_id = ?',
      whereArgs: [despachoId],
    );
    
    // Obtener detalles de explosivos del despacho
    despachoCompleto['detalles_explosivos'] = await db.query(
      'nube_DetalleDespachoExplosivos',
      where: 'id_despacho = ?',
      whereArgs: [despachoId],
    );

    despachosCompletos.add(despachoCompleto);
  }

  return despachosCompletos;
}

Future<List<Map<String, dynamic>>> _obtenerDevolucionesPorExploracion(int exploracionId) async {
  final Database db = await database;
  final List<Map<String, dynamic>> devoluciones = await db.query(
    'nube_Devoluciones',
    where: 'datos_trabajo_id = ?',
    whereArgs: [exploracionId],
  );

  List<Map<String, dynamic>> devolucionesCompletas = [];

  for (var devolucion in devoluciones) {
    // Crear un nuevo mapa mutable para la devolución
    Map<String, dynamic> devolucionCompleta = Map<String, dynamic>.from(devolucion);
    int devolucionId = devolucion['id'];
    
    // Obtener detalles normales de la devolución
    devolucionCompleta['detalles'] = await db.query(
      'nube_DevolucionDetalle',
      where: 'devolucion_id = ?',
      whereArgs: [devolucionId],
    );
    
    // Obtener detalles de explosivos de la devolución
    devolucionCompleta['detalles_explosivos'] = await db.query(
      'nube_DetalleDevolucionesExplosivos',
      where: 'id_devolucion = ?',
      whereArgs: [devolucionId],
    );

    devolucionesCompletas.add(devolucionCompleta);
  }

  return devolucionesCompletas;
}
}
