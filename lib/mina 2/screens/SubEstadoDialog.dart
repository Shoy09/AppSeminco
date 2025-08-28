import 'package:flutter/material.dart';
import '../../database/database_helper_mina_2.dart';

class SubEstadoDialog extends StatefulWidget {
  final String codigo;
  final String proceso;
  final String turno;
  final int idEstado;

  const SubEstadoDialog({
    Key? key,
    required this.codigo,
    required this.turno,
    required this.proceso,
    required this.idEstado,
  }) : super(key: key);

  @override
  _SubEstadoDialogState createState() => _SubEstadoDialogState();
}

class _SubEstadoDialogState extends State<SubEstadoDialog> {
  String? selectedSubEstadoCodigo;
  String? selectedHoraInicio;
  int? subEstadoIdExistente;
  bool isEditing = false;
  List<Map<String, dynamic>> subEstadosDisponibles = [];
  List<String> timeIntervals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    timeIntervals = generateTimeIntervals();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final dbHelper = DatabaseHelper_Mina2();
    final db = await dbHelper.database;

    try {
      // 1. Obtener el estado_id (por si acaso lo necesitamos)
      final estadoId = await _getEstadoId();
      
      if (estadoId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 2. Cargar subestados disponibles (para los selectables)
      final subEstados = await _getSubEstados(estadoId);
      
      // 3. Verificar si existe un subestado guardado para este estado
      final subEstadoExistente = await dbHelper.getPrimerSubEstadoPorEstadoIdNube(db, widget.idEstado);

      setState(() {
        subEstadosDisponibles = subEstados;
        
        if (subEstadoExistente != null) {
          isEditing = true;
          subEstadoIdExistente = subEstadoExistente['id'] as int?;
          selectedSubEstadoCodigo = subEstadoExistente['codigo'] as String?;
          selectedHoraInicio = subEstadoExistente['hora_inicio'] as String?;
          
          // Si el subestado existente no está en la lista de disponibles, lo agregamos
          if (!subEstadosDisponibles.any((e) => e['codigo'] == selectedSubEstadoCodigo)) {
            subEstadosDisponibles.add({
              'codigo': selectedSubEstadoCodigo,
              'tipo_estado': 'Existente',
            });
          }
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<int?> _getEstadoId() async {
    final dbHelper = DatabaseHelper_Mina2();
    return await dbHelper.getEstadoIdByCodigoAndProceso(widget.codigo, widget.proceso);
  }

  Future<List<Map<String, dynamic>>> _getSubEstados(int estadoId) async {
    final dbHelper = DatabaseHelper_Mina2();
    return await dbHelper.getSubEstadosByEstadoId(estadoId);
  }

  List<String> generateTimeIntervals() {
    List<String> times = [];
    if (widget.turno == "DÍA") {
      for (int hour = 7; hour <= 17; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 17 && minute > 25) break;
          times.add("${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
    } else {
      for (int hour = 19; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          times.add("${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
      for (int hour = 0; hour <= 5; hour++) {
        for (int minute = 0; minute < 60; minute += 5) {
          if (hour == 5 && minute > 25) break;
          times.add("${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
        }
      }
    }
    return times;
  }

  List<DropdownMenuItem<String>> obtenerOpcionesUnicas() {
    final seen = <String>{};
    return subEstadosDisponibles.where((e) => seen.add(e["codigo"] as String? ?? "")).map((e) {
      String codigo = e["codigo"] as String? ?? "";
      String tipoEstado = e["tipo_estado"] as String? ?? "";
      return DropdownMenuItem<String>(
        value: codigo,
        child: Text("$codigo - $tipoEstado", style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  Future<void> _handleSave() async {
    final dbHelper = DatabaseHelper_Mina2();
    final db = await dbHelper.database;
    
    try {
      int result;
      String message;
      
      if (isEditing && subEstadoIdExistente != null) {
        // Actualización
        result = await dbHelper.actualizarSubEstado(
          db,
          subEstadoIdExistente!,
          selectedSubEstadoCodigo!,
          selectedHoraInicio!,
          '', // hora_final se puede dejar vacío o manejarlo aparte
        );
        message = 'Subestado actualizado correctamente';
      } else {
        // Creación
        result = await dbHelper.insertarSubEstado(
          db,
          widget.idEstado,
          selectedSubEstadoCodigo!,
          selectedHoraInicio!,
        );
        message = 'Subestado creado correctamente';
      }
      
      if (result > 0) {
        Navigator.pop(context, {
          'success': true,
          'message': message,
          'isEditing': isEditing,
        });
      } else {
        Navigator.pop(context, {
          'success': false,
          'message': 'Error al ${isEditing ? 'actualizar' : 'crear'} el subestado',
        });
      }
    } catch (e) {
      Navigator.pop(context, {
        'success': false,
        'message': 'Error: ${e.toString()}',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (subEstadosDisponibles.isEmpty) {
      return AlertDialog(
        title: const Text("Agregar Sub Estado"),
        content: const Text("⚠️ No se encontraron subestados disponibles."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(isEditing ? "Editar Sub Estado" : "Agregar Sub Estado"),
      contentPadding: const EdgeInsets.all(20.0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Subestado:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSubEstadoCodigo,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                hint: const Text('Seleccione un subestado'),
                items: obtenerOpcionesUnicas(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubEstadoCodigo = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text("Hora de inicio:", 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedHoraInicio,
                dropdownColor: Colors.white,
                menuMaxHeight: 200,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                hint: const Text('Seleccione hora de inicio'),
                items: timeIntervals.map((time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedHoraInicio = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
        ElevatedButton(
          onPressed: (selectedSubEstadoCodigo == null || selectedHoraInicio == null)
              ? null
              : _handleSave,
          child: Text(isEditing ? "Actualizar" : "Guardar"),
        ),
      ],
    );
  }
}