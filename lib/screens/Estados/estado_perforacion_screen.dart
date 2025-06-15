import 'package:flutter/material.dart';

import '../../database/database_helper.dart';

class EstadoRegistroPerforacionScreen extends StatefulWidget {
  final String turno;
  final int operacionId;
  final String tipoOperacion;
  final String estado;

  EstadoRegistroPerforacionScreen({
    required this.turno,
    required this.operacionId,
    required this.tipoOperacion,
    required this.estado,
  });

  @override
  _EstadoRegistroPerforacionScreenState createState() =>
      _EstadoRegistroPerforacionScreenState();
}

class _EstadoRegistroPerforacionScreenState
    extends State<EstadoRegistroPerforacionScreen> {
  List<Map<String, String>> currentData = [];
  List<Map<String, String>> currentDataDialog = [];
  List<Map<String, dynamic>> estadosBD = [];

  final Map<String, List<Map<String, String>>> datadialog = {
    'OPERATIVO': [],
    'DEMORA': [],
    'MANTENIMIENTO': [],
    'RESERVA': [],
    'FUERA DE PLAN': [],
  };

  @override
  void initState() {
    obtenerEstadosBD();
    super.initState();
    print("Operacion ID recibido: ${widget.operacionId}");
    fetchEstados();
  }

  void obtenerEstadosBD() async {
    estadosBD = await DatabaseHelper().getEstadosBD(
        widget.tipoOperacion); // 🔹 Pasamos tipoOperacion como proceso
    print(
        "Estados obtenidos de la BDEstados para proceso '${widget.tipoOperacion}': $estadosBD");

    // Limpiamos la lista antes de actualizar
    datadialog.forEach((key, value) => value.clear());

    // Agregar los estados filtrados a la lista correcta
    for (var estado in estadosBD) {
      String estadoPrincipal = estado['estado_principal'];
      if (datadialog.containsKey(estadoPrincipal)) {
        datadialog[estadoPrincipal]?.add({
          "Nombre": estado['tipo_estado'],
          "Código": estado['codigo'].toString(),
        });
      }
    }

    setState(() {}); // 🔹 Actualiza la UI con los nuevos datos
  }

  void fetchEstados() async {
    try {
      print("Operación ID enviado: ${widget.operacionId}");

      final dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> estados =
          await dbHelper.getEstadosByOperacionId(widget.operacionId);

      print("Datos obtenidos de la base de datos: $estados");

      List<Map<String, String>> allEstados = estados.map((estado) {
        return {
          'id': estado['id'].toString(),
          'numero': estado['numero']?.toString() ?? '',
          'estado': estado['estado']?.toString() ?? '',
          'codigo': estado['codigo']?.toString() ?? '',
          'hora_inicio': estado['hora_inicio']?.toString() ?? '',
          'hora_final': estado['hora_final']?.toString() ?? '',
        };
      }).toList();

      print("Estados convertidos: $allEstados");

      setState(() {
        currentData = allEstados;
      });
    } catch (e) {
      print("Error al obtener estados: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var codigoOperativos = currentData;
    return Scaffold(
      appBar: AppBar(
        title: Text('Información de ${widget.tipoOperacion}'),
        backgroundColor: Color(0xFF21899C),
      ),
      body: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'REGISTRO EN ${widget.tipoOperacion}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                _buildStateButton('OPERATIVO', Colors.green, codigoOperativos,
                    widget.estado == 'cerrado'),
                SizedBox(width: 10),
                _buildStateButton('DEMORA', Colors.yellow, codigoOperativos,
                    widget.estado == 'cerrado'),
                SizedBox(width: 10),
                _buildStateButton('MANTENIMIENTO', Colors.red, codigoOperativos,
                    widget.estado == 'cerrado'),
                SizedBox(width: 10),
                _buildStateButton('RESERVA', Colors.orange, codigoOperativos,
                    widget.estado == 'cerrado'),
                SizedBox(width: 10),
                _buildStateButton('FUERA DE PLAN', Colors.blue,
                    codigoOperativos, widget.estado == 'cerrado'),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCodigoTable()),
                          SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateButton(String label, Color color,
      List<Map<String, String>> codigoOperativos, bool isDisabled) {
    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? null // Deshabilita el tap si el estado es "cerrado"
            : () {
                showRegisterOperationDialog(
                  context,
                  codigoOperativos,
                  widget.turno,
                  widget.operacionId,
                  label,
                );
              },
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey
                : color, // Cambia color si está deshabilitado
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodigoTable() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: {
        0: FixedColumnWidth(40),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(120),
        3: FixedColumnWidth(120),
        4: FixedColumnWidth(100),
        5: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue.shade200),
          children: [
            headerCell("N°"),
            headerCell("Estado"),
            headerCell("Código"),
            headerCell("Hora Inicio"),
            headerCell("Hora Fin"),
            headerCell("Acciones"),
          ],
        ),
        for (var item in currentData)
          TableRow(
            children: [
              cellText(item["numero"] ?? ""),
              cellText(item["estado"] ?? ""),
              cellText(item["codigo"] ?? ""),
              cellText(item["hora_inicio"] ?? ""),
              cellText(item["hora_final"] ?? ""),
              _buildDeleteIcon(context, item["id"], widget.estado == 'cerrado'),
            ],
          ),
      ],
    );
  }

  Widget _buildDeleteIcon(BuildContext context, String? id, bool isDisabled) {
    return IconButton(
      icon: Icon(Icons.delete, color: isDisabled ? Colors.grey : Colors.red),
      onPressed: isDisabled
          ? null // Si el estado es "cerrado", deshabilita la acción
          : () {
              if (id != null) {
                int estadoId = int.tryParse(id) ?? 0;
                if (estadoId > 0) {
                  List<int> idsAEliminar = [];
                  for (var item in currentData) {
                    int currentId = int.tryParse(item["id"] ?? "0") ?? 0;
                    if (currentId >= estadoId) {
                      idsAEliminar.add(currentId);
                    }
                  }
                  _confirmDelete(context, idsAEliminar);
                }
              }
            },
    );
  }

  void _confirmDelete(BuildContext context, List<int> idsAEliminar) {
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text(
              "¿Estás seguro de que quieres eliminar estos estados? Se eliminarán todos los registros posteriores al seleccionado."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final dbHelper = DatabaseHelper();
                bool success = true;

                try {
                  // ✅ Buscar el estado anterior al que se va a eliminar
                  int estadoAEliminar = idsAEliminar.first;
                  int? estadoAnteriorId;

                  for (var item in currentData) {
                    int currentId = int.tryParse(item["id"] ?? "0") ?? 0;
                    if (currentId < estadoAEliminar) {
                      estadoAnteriorId = currentId;
                    }
                  }

                  // ✅ Si hay un estado anterior, actualizar su `hora_final` a vacío
                  if (estadoAnteriorId != null) {
                    await dbHelper.updateHoraFinal(estadoAnteriorId, "");
                    print(
                        "Se limpió la hora_final del estado con ID: $estadoAnteriorId");
                  }

                  // ✅ Eliminar los estados desde el seleccionado en adelante
                  for (int id in idsAEliminar) {
                    int result = await dbHelper.deleteEstado(id);
                    if (result == 0) {
                      success = false;
                    }
                  }

                  // ✅ Mostrar mensaje de éxito o error
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? "Estados eliminados correctamente"
                          : "Error al eliminar algunos estados"),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  fetchEstados(); // ✅ Actualizar la lista en la UI
                } catch (e) {
                  print("Error al eliminar estados: $e");

                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text("Error al eliminar los estados"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget headerCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget cellText(String text) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  void showRegisterOperationDialog(
    BuildContext context,
    List<Map<String, String>> codigoOperativos,
    String turno,
    int operacionId,
    String selectedState,
  ) {
    print('Turno: $turno');
    print('operacionId: $operacionId');
    print('SelectedState: $selectedState');

    List<String> generateTimeIntervals(String turno) {
      List<String> times = [];

      if (turno == "DÍA") {
        // Turno día: 07:00 - 18:50
        for (int hour = 7; hour < 19; hour++) {
          for (int minute = 0; minute < 60; minute += 10) {
            times.add(
                "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
          }
        }
      } else {
        // Turno noche: 19:00 - 06:50
        List<String> nightTimes = [];

        // Primera parte: 19:00 - 23:50
        for (int hour = 19; hour < 24; hour++) {
          for (int minute = 0; minute < 60; minute += 10) {
            nightTimes.add(
                "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
          }
        }

        // Segunda parte: 00:00 - 06:50
        for (int hour = 0; hour < 7; hour++) {
          for (int minute = 0; minute < 60; minute += 10) {
            nightTimes.add(
                "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
          }
        }

        times.addAll(nightTimes);
      }

      return times;
    }

    List<DropdownMenuItem<String>> obtenerOpcionesUnicas(
        List<Map<String, dynamic>> data) {
      final seen = <String>{};

      return data.where((e) => seen.add(e["Código"] as String? ?? "")).map((e) {
        String codigo = e["Código"] as String? ?? "";
        String tipoEstado = e["Nombre"] as String? ?? "";

        return DropdownMenuItem<String>(
          value: codigo, // Almacena solo el código como valor
          child: Text(
            "$codigo - $tipoEstado",
            style: TextStyle(fontSize: 14), // Tamaño de fuente más pequeño
          ), // Muestra ambos en el dropdown
        );
      }).toList();
    }

    List<String> timeOptions = generateTimeIntervals(turno);
    String? selectedCodigo;
    String? selectedTime;
    List<Map<String, String>> currentDataDialog =
        datadialog[selectedState] ?? [];

    List<String> registeredHours = codigoOperativos
        .map((item) => item["hora_inicio"] ?? '')
        .where((hora) => hora.isNotEmpty)
        .toList();

    List<String> availableTimeOptions = timeOptions.where((hora) {
      if (registeredHours.isEmpty) return true;

      // Obtener todas las horas registradas ordenadas correctamente
      List<String> sortedRegisteredHours = [...registeredHours];

      // Si es turno de noche, necesitamos ordenar considerando que 00:00 es después de 23:50
      if (turno != "DÍA") {
        sortedRegisteredHours.sort((a, b) {
          int aHour = int.parse(a.split(":")[0]);
          int bHour = int.parse(b.split(":")[0]);

          // Si ambas horas son >=19 o ambas <7, orden normal
          if ((aHour >= 19 && bHour >= 19) || (aHour < 7 && bHour < 7)) {
            return a.compareTo(b);
          }
          // Si a es >=19 y b es <7, a va primero
          else if (aHour >= 19 && bHour < 7) {
            return -1;
          }
          // Si b es >=19 y a es <7, b va primero
          else {
            return 1;
          }
        });
      } else {
        sortedRegisteredHours.sort();
      }

      String ultimaHoraInicio = sortedRegisteredHours.last;
      int ultimaHora = int.parse(ultimaHoraInicio.split(":")[0]);
      int ultimoMinuto = int.parse(ultimaHoraInicio.split(":")[1]);
      int horaActual = int.parse(hora.split(":")[0]);
      int minutoActual = int.parse(hora.split(":")[1]);

      // Para turno de noche
      if (turno != "DÍA") {
        // Si la última hora registrada es >=19 y la hora actual es <7, permitir
        if (ultimaHora >= 19 && horaActual < 7) {
          return true;
        }
        // Si ambas horas están en el rango de noche (19-23) o ambas en madrugada (0-6)
        if ((ultimaHora >= 19 && horaActual >= 19) ||
            (ultimaHora < 7 && horaActual < 7)) {
          return horaActual > ultimaHora ||
              (horaActual == ultimaHora && minutoActual > ultimoMinuto);
        }
        // No permitir horas de madrugada si la última fue de noche (excepto 00:00 caso anterior)
        return false;
      }
      // Para turno de día
      else {
        return horaActual > ultimaHora ||
            (horaActual == ultimaHora && minutoActual > ultimoMinuto);
      }
    }).toList();

    String horaFinalTurno = turno == "DÍA" ? "19:00" : "07:00";
    bool esCambioTurno = DateTime.now().hour == (turno == "DÍA" ? 19 : 7) &&
        DateTime.now().minute == 0;

    if (esCambioTurno && codigoOperativos.isNotEmpty) {
      int lastId = int.parse(codigoOperativos.last["id"]!);
      DatabaseHelper().updateHoraFinal(lastId, horaFinalTurno);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Center(
            child: Text("REGISTRA OPERACIÓN",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded:
                        true, // Esto hace que el dropdown ocupe todo el ancho disponible
                    decoration: InputDecoration(
                      labelText: "Código (*)",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    ),
                    items: obtenerOpcionesUnicas(currentDataDialog),
                    onChanged: (value) {
                      setState(() {
                        selectedCodigo = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Hora Inicio (*)",
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    ),
                    value: selectedTime,
                    items: availableTimeOptions
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Text(time, style: TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      selectedTime = value;
                    },
                    menuMaxHeight: 200,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                        child: Text("Limpiar"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedCodigo != null && selectedTime != null) {
                            bool horaExiste = codigoOperativos.any(
                                (item) => item["hora_inicio"] == selectedTime);
                            if (horaExiste) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Error: La Hora Inicio ya está registrada."),
                                    backgroundColor: Colors.red),
                              );
                              return;
                            }
                            int newNumber = codigoOperativos.isNotEmpty
                                ? int.parse(codigoOperativos.last["numero"]!) +
                                    1
                                : 1;
                            String horaInicio = codigoOperativos.isNotEmpty &&
                                    codigoOperativos
                                        .last["hora_final"]!.isNotEmpty
                                ? codigoOperativos.last["hora_final"]!
                                : selectedTime!;
                            if (codigoOperativos.isNotEmpty) {
                              int lastId =
                                  int.parse(codigoOperativos.last["id"]!);
                              await DatabaseHelper()
                                  .updateHoraFinal(lastId, selectedTime!);
                            }
                            int result = await DatabaseHelper().createEstado(
                              operacionId,
                              newNumber,
                              selectedState,
                              selectedCodigo!,
                              horaInicio,
                              "",
                            );
                            if (result > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Registro guardado correctamente."),
                                    backgroundColor: Colors.green),
                              );
                              fetchEstados();
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Error al guardar el registro."),
                                    backgroundColor: Colors.red),
                              );
                            }
                          } else {
                            print("Faltan datos por seleccionar.");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: Text("Crear"),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("(*) Los campos con asterisco son obligatorios.",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
