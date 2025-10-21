import 'package:app_seminco/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_seminco/mina%201/models/Equipo.dart';

class FormularioDialogSalida extends StatefulWidget {
  final VoidCallback? onSalidaGuardada; // Callback para recargar datos
  
  const FormularioDialogSalida({super.key, this.onSalidaGuardada});

  @override
  State<FormularioDialogSalida> createState() => _FormularioDialogSalidaState();
}

class _FormularioDialogSalidaState extends State<FormularioDialogSalida> {
  final TextEditingController _cantidadController = TextEditingController();

  DateTime _fecha = DateTime.now();
  String _turno = 'DIA';
  String _proceso = 'PERFORACIÓN TALADROS LARGOS';
  String _tipoAcero = '';
  String _equipo = '';
  String _codigoEquipo = '';
  String _operador = '';
  String _jefeGuardia = '';

  final List<String> _turnos = ['DIA', 'NOCHE'];
  final List<String> _procesos = [
    'PERFORACIÓN TALADROS LARGOS',
    'PERFORACIÓN HORIZONTAL',
    'SOSTENIMIENTO'
  ];

  // Listas para datos de BD
  List<Map<String, dynamic>> _todosProcesosAcero = [];
  List<Map<String, dynamic>> _procesosAceroFiltrados = [];
  List<Equipo> _todosEquipos = [];
  List<Equipo> _equiposFiltrados = [];
  List<Map<String, dynamic>> _operadores = [];
  List<Map<String, dynamic>> _jefesGuardia = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _turno = _determinarTurnoAutomatico(DateTime.now());
    _cargarTodosLosDatos();
  }

  // Función para determinar el turno automáticamente según la hora
  String _determinarTurnoAutomatico(DateTime fechaHora) {
    final hora = fechaHora.hour;
    if (hora >= 7 && hora < 19) {
      return 'DIA';
    } else {
      return 'NOCHE';
    }
  }

  // Función que carga TODOS los datos desde la BD
  Future<void> _cargarTodosLosDatos() async {
    final dbHelper = DatabaseHelper_Mina1();
    
    try {
      final procesosList = await dbHelper.getProcesosAcero();
      final equiposList = await dbHelper.getEquipos();
      final operadoresList = await dbHelper.getOperadoresAcero();
      final jefesList = await dbHelper.getJefesDeGuardiaAcero();

      setState(() {
        _todosProcesosAcero = procesosList;
        _todosEquipos = equiposList;
        _operadores = operadoresList;
        _jefesGuardia = jefesList;
        
        _filtrarProcesosAcero();
        _filtrarEquipos();
      });
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    }
  }

  // Función para filtrar los procesos_acero según el proceso seleccionado
  void _filtrarProcesosAcero() {
    setState(() {
      _procesosAceroFiltrados = _todosProcesosAcero
          .where((procesoAcero) => procesoAcero['proceso'] == _proceso)
          .toList();
      
      if (_procesosAceroFiltrados.isNotEmpty) {
        final tiposAceroDisponibles = _procesosAceroFiltrados
            .map((pa) => pa['tipo_acero'] as String)
            .toList();
        
        if (!tiposAceroDisponibles.contains(_tipoAcero)) {
          _tipoAcero = tiposAceroDisponibles.first;
        }
      } else {
        _tipoAcero = '';
      }
    });
  }

  // Función para filtrar equipos según el proceso seleccionado
// Función para filtrar equipos según el proceso seleccionado
void _filtrarEquipos() {
  setState(() {
    _equiposFiltrados = _todosEquipos
        .where((equipo) => equipo.proceso == _proceso)
        .toList();
    
    if (_equiposFiltrados.isNotEmpty) {
      final equiposDisponibles = _equiposFiltrados
          .map((e) => e.nombre)
          .toList();
      
      if (!equiposDisponibles.contains(_equipo)) {
        _equipo = equiposDisponibles.first;
        _actualizarCodigoEquipo();
      } else {
        // Si ya hay un equipo seleccionado, actualizar los códigos disponibles
        _actualizarCodigoEquipo();
      }
    } else {
      _equipo = '';
      _codigoEquipo = '';
    }
  });
}

  // Función para actualizar el código de equipo cuando se selecciona un equipo
void _actualizarCodigoEquipo() {
  if (_equipo.isNotEmpty && _equiposFiltrados.isNotEmpty) {
    final equipoSeleccionado = _equiposFiltrados
        .firstWhere((e) => e.nombre == _equipo);
    setState(() {
      _codigoEquipo = equipoSeleccionado.codigo;
    });
  } else {
    setState(() {
      _codigoEquipo = '';
    });
  }
}

  // Función para obtener la descripción del tipo de acero seleccionado
  String _getDescripcionAcero() {
    if (_tipoAcero.isEmpty || _procesosAceroFiltrados.isEmpty) {
      return '';
    }
    
    final procesoAcero = _procesosAceroFiltrados.firstWhere(
      (pa) => pa['tipo_acero'] == _tipoAcero,
      orElse: () => {},
    );
    
    return procesoAcero['descripcion'] as String? ?? '';
  }
  
void _mostrarErrorDialog(String mensaje) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) {
      final dialogContext = context;
      bool isDialogOpen = true;
      
      // Cerrar automáticamente después de 2 segundos
      Future.delayed(const Duration(seconds: 5), () {
        if (isDialogOpen && Navigator.of(dialogContext, rootNavigator: true).canPop()) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
      });

      return PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  isDialogOpen = false;
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  "Entendido",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        ),
      );
    },
  );
}

  // Función para guardar la salida en la base de datos
Future<void> _guardarSalida() async {
  if (_tipoAcero.isEmpty || _cantidadController.text.isEmpty || 
      _equipo.isEmpty || _operador.isEmpty || _jefeGuardia.isEmpty || _codigoEquipo.isEmpty) {
    _mostrarError('Por favor, complete todos los campos');
    return;
  }

  final cantidad = double.tryParse(_cantidadController.text);
  if (cantidad == null || cantidad <= 0) {
    _mostrarError('Por favor, ingrese una cantidad válida');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final dbHelper = DatabaseHelper_Mina1();

    // 🔹 1. Obtener ingresos y salidas acumulados para este proceso/tipo/desc
    final ingresos = await dbHelper.getIngresosAceros();
    final salidas = await dbHelper.getSalidasAceros();

    final key = "${_proceso}_${_tipoAcero}_${_getDescripcionAcero()}";

    double totalIngresos = 0;
    double totalSalidas = 0;

    for (var ing in ingresos) {
      final k = "${ing['proceso']}_${ing['tipo_acero']}_${ing['descripcion']}";
      if (k == key) {
        totalIngresos += ing['cantidad'] ?? 0.0;
      }
    }

    for (var sal in salidas) {
      final k = "${sal['proceso']}_${sal['tipo_acero']}_${sal['descripcion']}";
      if (k == key) {
        totalSalidas += sal['cantidad'] ?? 0.0;
      }
    }

    final disponible = totalIngresos - totalSalidas;

    // 🔹 2. Validar contra stock disponible
    if (cantidad > disponible) {
      _mostrarErrorDialog("La salida solicitada ($cantidad) excede el stock disponible ($disponible)");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 🔹 3. Guardar en la base de datos si es válido
    final resultado = await dbHelper.createSalidaAceros(
      DateFormat('yyyy-MM-dd').format(_fecha),
      _turno,
      _getMes(),
      _proceso,
      _equipo,
      _codigoEquipo,
      _operador,
      _jefeGuardia,
      _tipoAcero,
      _getDescripcionAcero(),
      cantidad,
    );

    if (resultado > 0) {
      if (widget.onSalidaGuardada != null) {
        widget.onSalidaGuardada!();
      }
      Navigator.pop(context);
      _mostrarExito('Salida guardada exitosamente');
    } else {
      _mostrarError('Error al guardar la salida');
    }
  } catch (e) {
    _mostrarError('Error al guardar: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _fecha) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  String _getMes() {
    final meses = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];
    return meses[_fecha.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nueva Salida"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
              ],
              
              // FECHA
              _buildDateField(),
              const SizedBox(height: 15),
              
              // TURNO
              _buildDropdownField(
                label: 'Turno',
                value: _turno,
                items: _turnos,
                onChanged: (value) {
                  setState(() {
                    _turno = value!;
                  });
                },
              ),
              const SizedBox(height: 15),
              
              // MES (solo lectura)
              _buildReadOnlyField(
                label: 'Mes',
                value: _getMes(),
              ),
              const SizedBox(height: 15),
              
              // PROCESO
              _buildDropdownField(
                label: 'Proceso',
                value: _proceso,
                items: _procesos,
                onChanged: (value) {
                  setState(() {
                    _proceso = value!;
                    _filtrarProcesosAcero();
                    _filtrarEquipos();
                  });
                },
              ),
              const SizedBox(height: 15),
              
              // EQUIPO
              _buildEquipoField(),
              const SizedBox(height: 15),
              
              // CÓDIGO DE EQUIPO (AHORA ES SELECCIONABLE)
              _buildCodigoEquipoField(),
              const SizedBox(height: 15),
              
              // OPERADOR
              _buildDropdownField(
                label: 'Operador',
                value: _operador.isEmpty ? null : _operador,
                items: _operadores.map((o) => o['operador'] as String).toList(),
                onChanged: (value) {
                  setState(() {
                    _operador = value!;
                  });
                },
                hint: 'Seleccione un operador',
              ),
              const SizedBox(height: 15),
              
              // JEFE DE GUARDIA
              _buildDropdownField(
                label: 'Jefe de Guardia',
                value: _jefeGuardia.isEmpty ? null : _jefeGuardia,
                items: _jefesGuardia.map((j) => j['jefe_de_guardia'] as String).toList(),
                onChanged: (value) {
                  setState(() {
                    _jefeGuardia = value!;
                  });
                },
                hint: 'Seleccione un jefe de guardia',
              ),
              const SizedBox(height: 15),
              
              // TIPO DE ACERO (filtrado por proceso)
              _buildTipoAceroField(),
              const SizedBox(height: 15),
              
              // DESCRIPCIÓN (automática)
              _buildReadOnlyField(
                label: 'Descripción',
                value: _getDescripcionAcero(),
                hint: _procesosAceroFiltrados.isEmpty 
                    ? 'No hay tipos de acero para este proceso'
                    : 'Seleccione un tipo de acero primero',
              ),
              const SizedBox(height: 15),
              
              // CANTIDAD
              TextField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: "Cantidad",
                  border: OutlineInputBorder(),
                  hintText: "Ingrese la cantidad",
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context), 
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarSalida,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Guardar"),
        ),
      ],
    );
  }

  // Widget para el campo de código de equipo (AHORA ES SELECCIONABLE)
Widget _buildCodigoEquipoField() {
  // Obtener códigos de equipo únicos para el EQUIPO seleccionado
  final codigosEquiposDisponibles = _equiposFiltrados
      .where((equipo) => equipo.nombre == _equipo) // FILTRAR POR EQUIPO SELECCIONADO
      .map((e) => e.codigo)
      .toSet()
      .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDropdownField(
        label: 'Código de Equipo',
        value: _codigoEquipo.isEmpty ? null : _codigoEquipo,
        items: codigosEquiposDisponibles,
        onChanged: codigosEquiposDisponibles.isEmpty 
    ? null
    : (value) {
        setState(() {
          _codigoEquipo = value!;
          _actualizarEquipoDesdeCodigo(); // Mantener esta línea si quieres bidireccionalidad
        });
      },
        hint: codigosEquiposDisponibles.isEmpty 
            ? 'No hay códigos para este equipo'
            : 'Seleccione un código de equipo',
      ),
      if (_equiposFiltrados.isEmpty) ...[
        const SizedBox(height: 4),
        Text(
          "No se encontraron códigos de equipo para el proceso seleccionado",
          style: TextStyle(
            fontSize: 10,
            color: Colors.orange[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      ] else if (_equipo.isEmpty) ...[
        const SizedBox(height: 4),
        Text(
          "Seleccione un equipo primero para ver los códigos disponibles",
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );
}

 // Función para actualizar el nombre del equipo cuando se selecciona un código
void _actualizarEquipoDesdeCodigo() {
  if (_codigoEquipo.isNotEmpty && _equiposFiltrados.isNotEmpty) {
    final equipoSeleccionado = _equiposFiltrados
        .firstWhere((e) => e.codigo == _codigoEquipo);
    setState(() {
      _equipo = equipoSeleccionado.nombre;
    });
  } else {
    setState(() {
      _equipo = '';
    });
  }
}

  // Widget especial para el campo de equipo
  Widget _buildEquipoField() {
  final equiposDisponibles = _equiposFiltrados
      .map((e) => e.nombre)
      .toSet()
      .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildDropdownField(
        label: 'Equipo',
        value: _equipo.isEmpty ? null : _equipo,
        items: equiposDisponibles,
        onChanged: equiposDisponibles.isEmpty 
            ? null
            : (value) {
                setState(() {
                  _equipo = value!;
                  _actualizarCodigoEquipo(); // Actualizar códigos cuando cambia el equipo
                });
              },
        hint: equiposDisponibles.isEmpty 
            ? 'No hay equipos para este proceso'
            : 'Seleccione un equipo',
      ),
      if (_equiposFiltrados.isEmpty) ...[
        const SizedBox(height: 4),
        Text(
          "No se encontraron equipos para el proceso seleccionado",
          style: TextStyle(
            fontSize: 10,
            color: Colors.orange[700],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );
}

  Widget _buildTipoAceroField() {
    final tiposAceroDisponibles = _procesosAceroFiltrados
        .map((pa) => pa['tipo_acero'] as String)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: 'Tipo de Acero',
          value: _tipoAcero.isEmpty ? null : _tipoAcero,
          items: tiposAceroDisponibles,
          onChanged: tiposAceroDisponibles.isEmpty 
              ? null
              : (value) {
                  setState(() {
                    _tipoAcero = value!;
                  });
                },
          hint: tiposAceroDisponibles.isEmpty 
              ? 'No hay tipos de acero para este proceso'
              : 'Seleccione un tipo de acero',
        ),
        if (_procesosAceroFiltrados.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            "No se encontraron tipos de acero para el proceso seleccionado",
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // Widget para campo de fecha seleccionable
  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Fecha",
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, size: 20),
        ),
        child: Row(
          children: [
            Text(DateFormat('yyyy-MM-dd').format(_fecha)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  // Widget para campos de solo lectura
  Widget _buildReadOnlyField({required String label, required String value, String? hint}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: hint,
      ),
      child: Text(
        value.isNotEmpty ? value : (hint ?? ''),
        style: value.isNotEmpty 
            ? null 
            : TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  // Widget para dropdowns
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?)? onChanged,
    String? hint,
  }) {
    final uniqueItems = items.toSet().toList();
    
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: uniqueItems.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          hint: hint != null ? Text(hint) : null,
          disabledHint: hint != null ? Text(hint) : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }
}