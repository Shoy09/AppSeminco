import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_seminco/database/database_helper.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final dbHelper = DatabaseHelper_Mina1();
  late Future<List<Map<String, dynamic>>> _stockFuture;
  
  // Variables para el filtro de fechas
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stockFuture = _calcularStock();
  }

  Future<List<Map<String, dynamic>>> _calcularStock() async {
    final ingresos = await dbHelper.getIngresosAceros();
    final salidas = await dbHelper.getSalidasAceros();

    Map<String, Map<String, dynamic>> agrupados = {};

    // Filtrar ingresos por fecha si hay filtros aplicados
    for (var ingreso in ingresos) {
      if (_fechaInicio != null || _fechaFin != null) {
        final fechaIngreso = _parseFecha(ingreso['fecha']);
        if (fechaIngreso == null) continue;
        
        if (_fechaInicio != null && fechaIngreso.isBefore(_fechaInicio!)) {
          continue;
        }
        if (_fechaFin != null && fechaIngreso.isAfter(_fechaFin!)) {
          continue;
        }
      }

      final key =
          "${ingreso['proceso']}_${ingreso['tipo_acero']}_${ingreso['descripcion']}";
      agrupados.putIfAbsent(key, () {
        return {
          "proceso": ingreso['proceso'],
          "tipo_acero": ingreso['tipo_acero'],
          "descripcion": ingreso['descripcion'],
          "ingreso": 0.0,
          "salida": 0.0,
          "stock": 0.0,
          "ingresos": <Map<String, dynamic>>[],
          "salidas": <Map<String, dynamic>>[],
          "ultimoIngreso": null,
          "ultimaSalida": null,
        };
      });

      agrupados[key]!["ingreso"] += ingreso['cantidad'] ?? 0.0;
      agrupados[key]!["stock"] += ingreso['cantidad'] ?? 0.0;
      agrupados[key]!["ingresos"].add(ingreso);
      
      // Actualizar último ingreso
      final ultimoIngreso = agrupados[key]!["ultimoIngreso"];
      if (ultimoIngreso == null || 
          _compararFechas(ingreso['fecha'], ultimoIngreso['fecha']) > 0) {
        agrupados[key]!["ultimoIngreso"] = ingreso;
      }
    }

    // Filtrar salidas por fecha si hay filtros aplicados
    for (var salida in salidas) {
      if (_fechaInicio != null || _fechaFin != null) {
        final fechaSalida = _parseFecha(salida['fecha']);
        if (fechaSalida == null) continue;
        
        if (_fechaInicio != null && fechaSalida.isBefore(_fechaInicio!)) {
          continue;
        }
        if (_fechaFin != null && fechaSalida.isAfter(_fechaFin!)) {
          continue;
        }
      }

      final key =
          "${salida['proceso']}_${salida['tipo_acero']}_${salida['descripcion']}";
      agrupados.putIfAbsent(key, () {
        return {
          "proceso": salida['proceso'],
          "tipo_acero": salida['tipo_acero'],
          "descripcion": salida['descripcion'],
          "ingreso": 0.0,
          "salida": 0.0,
          "stock": 0.0,
          "ingresos": <Map<String, dynamic>>[],
          "salidas": <Map<String, dynamic>>[],
          "ultimoIngreso": null,
          "ultimaSalida": null,
        };
      });

      agrupados[key]!["salida"] += salida['cantidad'] ?? 0.0;
      agrupados[key]!["stock"] -= salida['cantidad'] ?? 0.0;
      agrupados[key]!["salidas"].add(salida);
      
      // Actualizar última salida
      final ultimaSalida = agrupados[key]!["ultimaSalida"];
      if (ultimaSalida == null || 
          _compararFechas(salida['fecha'], ultimaSalida['fecha']) > 0) {
        agrupados[key]!["ultimaSalida"] = salida;
      }
    }

    return agrupados.values.toList();
  }

  // Función para parsear fechas desde string
  DateTime? _parseFecha(String? fechaString) {
    if (fechaString == null) return null;
    try {
      return DateFormat('yyyy-MM-dd').parse(fechaString);
    } catch (e) {
      return null;
    }
  }

  // Función para comparar fechas
  int _compararFechas(String fecha1, String fecha2) {
    final date1 = _parseFecha(fecha1);
    final date2 = _parseFecha(fecha2);
    
    if (date1 == null || date2 == null) return 0;
    
    if (date1.isAfter(date2)) return 1;
    if (date1.isBefore(date2)) return -1;
    return 0;
  }

  // Función para seleccionar fecha
  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          _fechaInicioController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _fechaFin = picked;
          _fechaFinController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  // Función para aplicar filtros
  void _aplicarFiltros() {
    setState(() {
      _stockFuture = _calcularStock();
    });
  }

  // Función para limpiar filtros
  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _fechaInicioController.clear();
      _fechaFinController.clear();
      _stockFuture = _calcularStock();
    });
  }

  void _mostrarDetalles(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Detalles - ${item['descripcion']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Ingresos
                const Text("📥 Ingresos",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16)),
                const SizedBox(height: 8),
                
                if (item['ingresos'].isEmpty)
                  const Text("No hay ingresos registrados",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  ...item['ingresos']
                      .map<Widget>((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Text("•", style: TextStyle(color: Colors.green)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Fecha: ${i['fecha']} | Turno: ${i['turno']} | Cantidad: ${i['cantidad']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                const SizedBox(height: 16),

                // Sección de Salidas
                const Text("📤 Salidas",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16)),
                const SizedBox(height: 8),
                
                if (item['salidas'].isEmpty)
                  const Text("No hay salidas registradas",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else
                  ...item['salidas']
                      .map<Widget>((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Text("•", style: TextStyle(color: Colors.red)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Fecha: ${s['fecha']} | Turno: ${s['turno']} | Equipo: ${s['equipo']} | Cantidad: ${s['cantidad']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cerrar", style: TextStyle(color: Color(0xFF21899C))),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  // Widget para mostrar última transacción
  Widget _buildUltimaTransaccion(Map<String, dynamic>? transaccion, bool esIngreso) {
    if (transaccion == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Sin ${esIngreso ? 'ingresos' : 'salidas'}",
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fecha y turno
        Text(
          "${transaccion['fecha']} - ${transaccion['turno']}",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Cantidad
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: esIngreso ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: esIngreso ? Colors.green[100]! : Colors.red[100]!,
              width: 1,
            ),
          ),
          child: Text(
            "${esIngreso ? '+' : '-'}${transaccion['cantidad']}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: esIngreso ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock de Aceros"),
        backgroundColor: const Color(0xFF21899C),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sección de Filtros
            _buildFiltrosSection(),
            const SizedBox(height: 16),
            
            // Sección de Datos
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _stockFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const Center(child: Text("No hay datos de stock para el rango de fechas seleccionado"));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return _buildMobileView(data);
                      } else {
                        return _buildDesktopView(data);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para la sección de filtros - OPTIMIZADO EN UNA SOLA LÍNEA
  Widget _buildFiltrosSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Filtrar por Rango de Fechas",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF21899C),
              ),
            ),
            const SizedBox(height: 12),
            // Fila única con campos de fecha y botones
            Row(
              children: [
                // Campo Fecha Inicio
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _fechaInicioController,
                    decoration: const InputDecoration(
                      labelText: "Fecha Inicio",
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                // Campo Fecha Fin
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _fechaFinController,
                    decoration: const InputDecoration(
                      labelText: "Fecha Fin",
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Aplicar Filtros
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt, size: 18),
                    label: const Text("Filtrar", style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21899C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _aplicarFiltros,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Limpiar Filtros
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text("Limpiar", style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _limpiarFiltros,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Vista para dispositivos móviles
  Widget _buildMobileView(List<Map<String, dynamic>> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final stock = item['stock'];
        final colorStock = stock <= 0 ? Colors.red : Colors.green[700];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['descripcion'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                      onPressed: () => _mostrarDetalles(context, item),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow("Proceso:", item['proceso'] ?? ""),
                _buildInfoRow("Tipo Acero:", item['tipo_acero'] ?? ""),
                
                // Último Ingreso y Última Salida en móvil
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildUltimaTransaccionMobile(
                        item['ultimoIngreso'], 
                        true, 
                        "Último Ingreso"
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildUltimaTransaccionMobile(
                        item['ultimaSalida'], 
                        false, 
                        "Última Salida"
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCard("Ingreso", "${item['ingreso']}", Colors.blue),
                    _buildMetricCard("Salida", "${item['salida']}", Colors.orange),
                    _buildMetricCard("Stock", "${item['stock']}", colorStock!),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para última transacción en vista móvil
  Widget _buildUltimaTransaccionMobile(Map<String, dynamic>? transaccion, bool esIngreso, String titulo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (transaccion == null)
            Text(
              "No hay datos",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: [
                Text(
                  "${transaccion['fecha']}",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Turno: ${transaccion['turno']}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: esIngreso ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${esIngreso ? '+' : '-'}${transaccion['cantidad']}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: esIngreso ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Vista para desktop/tablets - ACTUALIZADA CON NUEVAS COLUMNAS
  Widget _buildDesktopView(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: DataTable(
              border: TableBorder.all(
                color: Colors.grey[400]!,
                width: 1,
              ),
              headingRowColor: WidgetStateProperty.all(const Color(0xFF21899C)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              headingRowHeight: 52,
              dataRowHeight: 60, // Aumentado para acomodar las nuevas columnas
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Proceso", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Tipo de Acero", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Descripción", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Expanded(
                    child: Center(
                      child: Text("Ingreso", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Expanded(
                    child: Center(
                      child: Text("Salida", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Expanded(
                    child: Center(
                      child: Text("Stock", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Último Ingreso", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Última Salida", textAlign: TextAlign.center),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Center(
                      child: Text("Ver", textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
              rows: data.map((item) {
                final stock = item['stock'];
                final colorStock = stock <= 0 ? Colors.red : Colors.green[700];

                return DataRow(
                  cells: [
                    DataCell(Center(
                        child: Text(item['proceso'] ?? "",
                            style: const TextStyle(fontSize: 13)))),
                    DataCell(Center(
                        child: Text(item['tipo_acero'] ?? "",
                            style: const TextStyle(fontSize: 13)))),
                    DataCell(Center(
                      child: SizedBox(
                        width: 180,
                        child: Text(
                          item['descripcion'] ?? "",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )),
                    DataCell(Center(
                        child: Text("${item['ingreso']}",
                            style: const TextStyle(fontSize: 13)))),
                    DataCell(Center(
                        child: Text("${item['salida']}",
                            style: const TextStyle(fontSize: 13)))),
                    DataCell(Center(
                        child: Text("${item['stock']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorStock,
                                fontSize: 13)))),
                    DataCell(
                      Center(child: _buildUltimaTransaccion(item['ultimoIngreso'], true)),
                    ),
                    DataCell(
                      Center(child: _buildUltimaTransaccion(item['ultimaSalida'], false)),
                    ),
                    DataCell(Center(
                      child: IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.blue, size: 20),
                        onPressed: () => _mostrarDetalles(context, item),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}