import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormularioDialogEntrada extends StatefulWidget {
  final VoidCallback? onEntradaGuardada;
  
  const FormularioDialogEntrada({super.key, this.onEntradaGuardada});

  @override
  State<FormularioDialogEntrada> createState() => _FormularioDialogState();
}

class _FormularioDialogState extends State<FormularioDialogEntrada> {
  final TextEditingController _cantidadController = TextEditingController();

  DateTime _fecha = DateTime.now();
  String _turno = 'DIA';
  String _proceso = 'PERFORACIÓN TALADROS LARGOS';
  String _tipoAcero = '';

  final List<String> _turnos = ['DIA', 'NOCHE'];
  final List<String> _procesos = [
    'PERFORACIÓN TALADROS LARGOS',
    'PERFORACIÓN HORIZONTAL',
    'SOSTENIMIENTO'
  ];

  // Lista completa de procesos_acero desde la BD
  List<Map<String, dynamic>> _todosProcesosAcero = [];
  // Lista filtrada según el proceso seleccionado
  List<Map<String, dynamic>> _procesosAceroFiltrados = [];

  @override
  void initState() {
    super.initState();
    _turno = _determinarTurnoAutomatico(DateTime.now());
    _cargarTodosLosProcesosAcero();
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

  // Función que carga TODOS los procesos_acero desde la BD
  Future<void> _cargarTodosLosProcesosAcero() async {
    final dbHelper = DatabaseHelper_Mina2();
    final procesosList = await dbHelper.getProcesosAcero();

    setState(() {
      _todosProcesosAcero = procesosList;
      _filtrarProcesosAcero(); // Filtrar según el proceso actual
    });
  }

  // Función para filtrar los procesos_acero según el proceso seleccionado
  void _filtrarProcesosAcero() {
    setState(() {
      _procesosAceroFiltrados = _todosProcesosAcero
          .where((procesoAcero) => procesoAcero['proceso'] == _proceso)
          .toList();
      
      // Resetear el tipo de acero seleccionado si no está en la lista filtrada
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

  // Función para guardar en la base de datos
  Future<void> _guardarEntrada() async {
    // Validar que todos los campos estén llenos
    if (_tipoAcero.isEmpty || _cantidadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que la cantidad sea un número válido
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese una cantidad válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper_Mina2();
      
      // Guardar en la base de datos
      final resultado = await dbHelper.createIngresoAceros(
        DateFormat('yyyy-MM-dd').format(_fecha),
        _turno,
        _getMes(),
        _proceso,
        _tipoAcero,
        _getDescripcionAcero(),
        cantidad,
      );

      print('Registro guardado con ID: $resultado');
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Cerrar el diálogo
      Navigator.of(context).pop();
      
      // Llamar al callback para recargar los datos en la pantalla principal
      if (widget.onEntradaGuardada != null) {
        widget.onEntradaGuardada!();
      }

    } catch (e) {
      print('Error al guardar entrada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nuevo Registro"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    _filtrarProcesosAcero(); // Filtrar tipos de acero cuando cambia el proceso
                  });
                },
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _guardarEntrada,
          child: const Text("Guardar"),
        ),
      ],
    );
  }

  // Widget especial para el campo de tipo de acero
  Widget _buildTipoAceroField() {
    final tiposAceroDisponibles = _procesosAceroFiltrados
        .map((pa) => pa['tipo_acero'] as String)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: 'Tipo de Acero',
          value: _tipoAcero.isEmpty ? null : _tipoAcero,
          items: tiposAceroDisponibles,
          onChanged: tiposAceroDisponibles.isEmpty 
              ? null // Deshabilitar si no hay opciones
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
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((String item) {
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