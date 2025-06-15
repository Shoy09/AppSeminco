import 'package:app_seminco/components/reportes/ReportButton.dart';
import 'package:app_seminco/components/carga.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/models/formato_plan_mineral.dart';
import 'package:app_seminco/screens/Actualizar%20Datos/seccion_datos_api_screen.dart';
import 'package:app_seminco/screens/Largo/lista_perforacion_sreen.dart';
import 'package:app_seminco/screens/Mediciones/inicio.dart';
import 'package:app_seminco/screens/Sostenimiento/lista_perforacion_sreen.dart';
import 'package:app_seminco/screens/explosivos/prueba.dart';
import 'package:app_seminco/screens/horizontal/lista_perforacion_sreen.dart';
import 'package:app_seminco/screens/inicio/login_screen.dart';
import 'package:app_seminco/services/ApiServiceAccesorio.dart';
import 'package:app_seminco/services/ApiServiceExplosivo.dart';
import 'package:app_seminco/services/ApiServiceFor%20.dart';
import 'package:app_seminco/services/ApiServiceTipoPerforacion.dart';
import 'package:app_seminco/services/Plan%20mensual/api_service_FechasPlanMensualService.dart';
import 'package:app_seminco/services/Plan%20mensual/api_service_plan_mensual.dart';
import 'package:app_seminco/services/Plan%20mensual/api_service_plan_mensual_metraje.dart';
import 'package:app_seminco/services/Plan%20mensual/api_service_plan_mensual_produccion.dart';
import 'package:app_seminco/services/api_service_destinatarios.dart';
import 'package:app_seminco/services/api_service_estado.dart';
import 'package:app_seminco/services/api_service_explosivos.dart';
import 'package:app_seminco/services/api_services_Empresa.dart';
import 'package:app_seminco/services/api_services_Equipo.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class ReporteScreen extends StatefulWidget {
  final String token;
  final dynamic dni;

  const ReporteScreen({Key? key, required this.token, required this.dni})
      : super(key: key);

  @override
  _ReporteScreenState createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  late ApiServiceFor apiService;
  List<FormatoPlanMineral> formatos = [];
  String nombreUsuario = "Cargando...";
  String rol = "Cargando...";
  bool isLoading = false;
  late ApiServiceEstado estadoService;
  Map<String, dynamic> operacionesAutorizadas = {};
  @override
  void initState() {
    super.initState();
    apiService = ApiServiceFor();
    estadoService = ApiServiceEstado();
    _cargarNombreUsuario();
    // _inicializarBaseDeDatos();
  }

  Future<void> _actualizarDatos(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(message: 'Iniciando actualización...'),
    );

    final fechasService = FechasPlanMensualService();
    try {
      final ultimaFecha = await fechasService.getUltimaFecha();

      if (ultimaFecha == null)
        throw Exception('No se encontró una fecha válida');

      final anio = ultimaFecha.fechaIngreso!;
      final mes = ultimaFecha.mes!;

      final Map<String, Future<void> Function()> requests = {
        "Formatos Plan Mineral": fetchFormatosPlanMineral,
        "Estados": fetchEstados,
        "Tipos Perforación": fetchTiposPerforacion,
        "Empresas": fetchEmpresa,
        "Equipos": fetchEquipo,
        "Accesorios": fetchAccesorios,
        "Explosivos": fetchExplosivos,
        "Explosivos Uni": fetchExplosivosUni,
        "Destinatarios": fetchDestinatarios,
        "Plan Mensual": () => fetchPlanMensual(anio, mes),
        "Plan Metraje": () => fetchPlanMetraje(anio, mes),
        "Plan Producción": () => fetchPlanProduccion(anio, mes),
      };

      bool errorOcurrido = false;

      for (var entry in requests.entries) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              ProgressDialog(message: 'Actualizando ${entry.key}...'),
        );
        try {
          await entry.value();
        } catch (e) {
          errorOcurrido = true;
          print("❌ Error en ${entry.key}: $e");
        }
      }

      Navigator.of(context).pop(); // Cerrar el último diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorOcurrido
              ? '❗ Algunas actualizaciones fallaron, revisa los logs.'
              : '✅ Todos los datos fueron actualizados correctamente'),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al actualizar: $e')),
      );
    }
  }

  Future<void> _inicializarBaseDeDatos() async {
    try {
      final dbHelper = DatabaseHelper();

      final dni = widget.dni?.toString().trim();
      if (dni == null || dni.isEmpty) {
        throw Exception("DNI no válido para inicializar la base de datos.");
      }

      await dbHelper
          .setCurrentUserDni(dni); // Establece el nombre del archivo de BD
      await _cargarNombreUsuario(); // Luego carga el nombre del usuario
    } catch (e) {
      print('Error inicializando la base de datos: $e');
      setState(() {
        nombreUsuario = "Error al cargar usuario";
      });
    }
  }

  bool estaAutorizadoPara(String operacion) {
    return operacionesAutorizadas[operacion] == true;
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final dbHelper = DatabaseHelper();
      final usuario = await dbHelper.getUserByDni(widget.dni);
      if (usuario != null) {
        setState(() {
          nombreUsuario = usuario['nombres'];
          rol = usuario['rol'];

          final operacionesJson = usuario['operaciones_autorizadas'];
          if (operacionesJson != null && operacionesJson.isNotEmpty) {
            operacionesAutorizadas = jsonDecode(operacionesJson);
          }
        });
      } else {
        setState(() {
          nombreUsuario = "Usuario no encontrado";
          rol = "sin rol";
        });
      }
    } catch (e) {
      print('Error obteniendo usuario: $e');
      setState(() {
        nombreUsuario = "Error al cargar usuario";
        rol = "Error al cargar rol";
      });
    }
  }

  Future<void> fetchFormatosPlanMineral() async {
    setState(() {
      isLoading = true; // Mostrar pantalla de carga
    });

    try {
      final result = await apiService.fetchFormatosPlanMineral(widget.token);
      setState(() {
        formatos = result;
      });
      await apiService.saveFormatosToLocalDB(result);
    } catch (e) {
      print('Error al cargar los formatos: $e');
    } finally {
      setState(() {
        isLoading = false; // Ocultar pantalla de carga después de fetchEstados
      });
    }
  }

  Future<void> fetchEstados() async {
    try {
      final estados = await estadoService.fetchEstados(widget.token);
      print("Estados cargados correctamente: $estados");

      // Guardar los estados en la base de datos local
      await estadoService.saveEstadosToLocalDB(estados);

      // Verificar si los datos se almacenaron correctamente
      final dbHelper = DatabaseHelper();
      final estadosBD = await dbHelper.getAll('EstadostBD');
      print("Estados en la base de datos local: $estadosBD");
    } catch (e) {
      print("Error al cargar los estados: $e");
    }
  }

  Future<void> fetchTiposPerforacion() async {
    try {
      final apiService = ApiServiceTipoPerforacion(); // ✅ Crear una instancia

      final tipos = await apiService.fetchTiposPerforacion(widget.token);
      print("Tipos de Perforación cargados correctamente: $tipos");

      // Guardar los datos en la base de datos local
      await apiService.saveTiposToLocalDB(tipos);

      // Verificar si los datos se almacenaron correctamente
      final dbHelper = DatabaseHelper();
      final tiposBD = await dbHelper.getAll('TipoPerforacion');
      print("Tipos de Perforación en la base de datos local: $tiposBD");
    } catch (e) {
      print("Error al cargar los tipos de perforación: $e");
    }
  }

  Future<void> fetchEmpresa() async {
    try {
      final apiService = ApiServiceEmpresa(); // ✅ Crear una instancia correcta

      final empresas = await apiService.fetchEmpresa(widget.token);
      print("Empresas cargadas correctamente: $empresas");

      // Guardar los datos en la base de datos local
      await apiService.saveEmpresasToLocalDB(empresas);

      // Verificar si los datos se almacenaron correctamente
      final dbHelper = DatabaseHelper();
      final empresasBD = await dbHelper.getAll('Empresa');
      print("Empresas en la base de datos local: $empresasBD");
    } catch (e) {
      print("Error al cargar las empresas: $e");
    }
  }

  Future<void> fetchEquipo() async {
    try {
      final apiService = ApiServiceEquipo(); // ✅ Crear una instancia correcta

      final equipos = await apiService.fetchEquipos(widget.token);
      print("Equipos cargados correctamente: $equipos");

      // Guardar los datos en la base de datos local
      await apiService.saveEquiposToLocalDB(equipos);

      // Verificar si los datos se almacenaron correctamente
      final dbHelper = DatabaseHelper();
      final equiposBD = await dbHelper.getAll('Equipo');
      print("Equipos en la base de datos local: $equiposBD");
    } catch (e) {
      print("Error al cargar los equipos: $e");
    }
  }

  Future<void> fetchExplosivos() async {
    try {
      final apiService =
          ApiServiceExplosivo(); // Crear una instancia de ApiServiceExplosivo

      final explosivos = await apiService
          .fetchExplosivos(widget.token); // Obtener explosivos desde la API
      print("Explosivos cargados correctamente: $explosivos");

      // Verificar si los datos se almacenaron correctamente en la base de datos local
      final dbHelper = DatabaseHelper();
      final explosivosBD = await dbHelper
          .getAll('explosivos'); // Obtener explosivos de la base de datos local
      print("Explosivos en la base de datos local: $explosivosBD");
    } catch (e) {
      print("Error al cargar los explosivos: $e");
    }
  }

  Future<void> fetchAccesorios() async {
    try {
      final apiService =
          ApiServiceAccesorio(); // Crear una instancia de ApiServiceAccesorio

      final accesorios = await apiService
          .fetchAccesorios(widget.token); // Obtener accesorios desde la API
      print("Accesorios cargados correctamente: $accesorios");

      // Verificar si los datos se almacenaron correctamente en la base de datos local
      final dbHelper = DatabaseHelper();
      final accesoriosBD = await dbHelper
          .getAll('accesorios'); // Obtener accesorios de la base de datos local
      print("Accesorios en la base de datos local: $accesoriosBD");
    } catch (e) {
      print("Error al cargar los accesorios: $e");
    }
  }

  Future<void> fetchDestinatarios() async {
    try {
      final apiService =
          ApiServiceDestinatarios(); // Crear una instancia de ApiServiceDestinatarios

      final destinatarios = await apiService.fetchDestinatarios(
          widget.token); // Obtener destinatarios desde la API
      print("Destinatarios cargados correctamente: $destinatarios");

      // Verificar si los datos se almacenaron correctamente en la base de datos local
      final dbHelper = DatabaseHelper();
      final destinatariosBD = await dbHelper.getAll(
          'destinatarios_correo'); // Obtener destinatarios de la base de datos local
      print("Destinatarios en la base de datos local: $destinatariosBD");
    } catch (e) {
      print("Error al cargar los destinatarios: $e");
    }
  }

  Future<void> fetchExplosivosUni() async {
    try {
      final apiService =
          ApiServiceExplosivosUni(); // Crear una instancia de ApiServiceExplosivos

      final explosivos = await apiService
          .fetchExplosivos(widget.token); // Obtener explosivos desde la API
      print("Explosivos cargados correctamente: $explosivos");

      // Verificar si los datos se almacenaron correctamente en la base de datos local
      final dbHelper = DatabaseHelper();
      final explosivosBD = await dbHelper.getAll(
          'explosivos_uni'); // Obtener explosivos de la base de datos local
      print("Explosivos en la base de datos local: $explosivosBD");
    } catch (e) {
      print("Error al cargar los explosivos: $e");
    }
  }



  Future<void> fetchPlanMensual(int anio, String mes) async {
    try {
      final apiService = ApiServicePlanMensual();

      final planes =
          await apiService.fetchPlanesMensuales(widget.token, anio, mes);
      print("Planes Mensuales cargados correctamente: $planes");

      if (planes != null) {
        // Verificar si la respuesta no es nula
        await apiService.savePlanesToLocalDB(planes);

        final dbHelper = DatabaseHelper();
        final planesBD = await dbHelper.getAll('PlanMensual');
        print("Planes Mensuales en la base de datos local: $planesBD");
      } else {
        print("La respuesta de planes mensuales es nula");
      }
    } catch (e) {
      print("Error al cargar los planes mensuales: $e");
      // Puedes agregar más detalles del error aquí
      if (e is TypeError) {
        print("Detalle del error de tipo: ${e.toString()}");
      }
    }
  }

  Future<void> fetchPlanMetraje(int anio, String mes) async {
    try {
      final apiService = ApiServicePlanMetraje();

      final planes =
          await apiService.fetchPlanesMetraje(widget.token, anio, mes);
      print("Planes de Metraje cargados correctamente: $planes");

      await apiService.savePlanesToLocalDB(planes);

      final dbHelper = DatabaseHelper();
      final planesBD = await dbHelper.getAll('PlanMetraje');
      print("Planes de Metraje en la base de datos local: $planesBD");
    } catch (e) {
      print("Error al cargar los planes de metraje: $e");
    }
  }

  Future<void> fetchPlanProduccion(int anio, String mes) async {
    try {
      final apiService = ApiServicePlanProduccion();

      final planes =
          await apiService.fetchPlanesProduccion(widget.token, anio, mes);
      print("Planes de Producción cargados correctamente: $planes");

      await apiService.savePlanesToLocalDB(planes);

      final dbHelper = DatabaseHelper();
      final planesBD = await dbHelper.getAll('PlanProduccion');
      print("Planes de Producción en la base de datos local: $planesBD");
    } catch (e) {
      print("Error al cargar los planes de producción: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Registro de Reporte'),
            SizedBox(width: 10),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF21899C),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SeccionesScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'actualizar') {
                await _actualizarDatos(context);
              } else if (value == 'cerrar_sesion') {
                // Navegar a la pantalla de login y limpiar el stack de navegación
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => SignInFive()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'actualizar',
                child: Row(
                  children: const [
                    Icon(Icons.refresh, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Actualizar datos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cerrar_sesion',
                child: Row(
                  children: const [
                    Icon(Icons.exit_to_app, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      double width = constraints.maxWidth;
      int columns;

      if (width > 1000) {
        columns = 6;
      } else if (width > 800) {
        columns = 5;
      } else if (width > 600) {
        columns = 4;
      } else if (width > 400) {
        columns = 3;
      } else {
        columns = 2;
      }

      List<Widget> buttons = [];

      if (estaAutorizadoPara('PERFORACIÓN TALADROS LARGOS')) {
        buttons.add(
          ReportButton(
            title: 'PERFORACIÓN \nTALADROS LARGOS',
            imagePath: 'assets/images/perforacion_taladros.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaPerforacionScreen(
                    tipoOperacion: 'PERFORACIÓN TALADROS LARGOS',
                    rolUsuario: rol,
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('PERFORACIÓN HORIZONTAL')) {
        buttons.add(
          ReportButton(
            title: 'PERFORACIÓN \nHORIZONTAL',
            imagePath: 'assets/images/perfo_horizontal.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaPerforacionHorizontalScreen(
                    tipoOperacion: 'PERFORACIÓN HORIZONTAL',
                    rolUsuario: rol,
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('SOSTENIMIENTO')) {
        buttons.add(
          ReportButton(
            title: 'SOSTENIMIENTO',
            imagePath: 'assets/images/sostenimiento.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaSostenimientoScreen(
                    tipoOperacion: 'SOSTENIMIENTO',
                    rolUsuario: rol,
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('SERVICIOS AUXILIARES')) {
        buttons.add(
          ReportButton(
            title: 'SERVICIOS \nAUXILIARES',
            imagePath: 'assets/images/servicio_auxiliares.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaPerforacionScreen(
                    tipoOperacion: 'SERVICIOS AUXILIARES',
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('EXPLOSIVOS')) {
        buttons.add(
          ReportButton(
            title: 'EXPLOSIVOS',
            imagePath: 'assets/images/explosivos.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Pruebacreen(dni: widget.dni),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('ACEROS DE PERFORACIÓN')) {
        buttons.add(
          ReportButton(
            title: 'ACEROS DE \nPERFORACIÓN',
            imagePath: 'assets/images/aceros_de_perforacion.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              // Descomenta y reemplaza con pantalla correcta cuando esté lista
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => AccesoriosExplosivosScreen(),
              //   ),
              // );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('CARGUÍO')) {
        buttons.add(
          ReportButton(
            title: 'CARGUÍO',
            imagePath: 'assets/images/carguio.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaPerforacionScreen(
                    tipoOperacion: 'CARGUÍO',
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('ACARREO')) {
        buttons.add(
          ReportButton(
            title: 'ACARREO',
            imagePath: 'assets/images/acarreo.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaPerforacionScreen(
                    tipoOperacion: 'ACARREO',
                  ),
                ),
              );
            },
          ),
        );
      }
      
      if (estaAutorizadoPara('MEDICIONES')) {
        buttons.add(
          ReportButton(
            title: 'MEDICIONES',
            imagePath: 'assets/images/medicion.png',
            backgroundColor: const Color(0xFF21899C),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistroExplosivoPage(),
                ),
              );
            },
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: buttons,
        ),
      );
    },
  ),
),
            const SizedBox(height: 20),
            Text(
              'Bienvenido, $nombreUsuario', // Mostramos el nombre aquí
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1.5,
                fontFamily: 'Roboto',
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.grey,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Espacio entre nombre y rol

            Text(
              'Rol: ${rol == null || rol.trim().isEmpty ? 'Sin rol' : rol}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
