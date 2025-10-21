import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final dbHelper = DatabaseHelper_Mina2(); // tu helper de SQLite
  late Future<List<Map<String, dynamic>>> _stockFuture;

  @override
  void initState() {
    super.initState();
    _stockFuture = _calcularStock();
  }

  Future<List<Map<String, dynamic>>> _calcularStock() async {
  final ingresos = await dbHelper.getIngresosAceros();
  final salidas = await dbHelper.getSalidasAceros();

  Map<String, Map<String, dynamic>> agrupados = {};

  print("============== INICIO CÁLCULO STOCK ==============");

  // Agrupar ingresos
  for (var ingreso in ingresos) {
    final key =
        "${ingreso['proceso']}_${ingreso['tipo_acero']}_${ingreso['descripcion']}";

    agrupados.putIfAbsent(key, () {
      return {
        "proceso": ingreso['proceso'],
        "tipo_acero": ingreso['tipo_acero'],
        "descripcion": ingreso['descripcion'],
        "ingresos": <Map<String, dynamic>>[],
        "salidas": <Map<String, dynamic>>[],
        "cantidad": 0.0,
      };
    });

    agrupados[key]!["ingresos"].add(ingreso);
    agrupados[key]!["cantidad"] += ingreso['cantidad'] ?? 0.0;

    print("➕ INGRESO -> Proceso: ${ingreso['proceso']}, "
        "Tipo: ${ingreso['tipo_acero']}, Desc: ${ingreso['descripcion']}, "
        "Cant: ${ingreso['cantidad']}, "
        "Acumulado: ${agrupados[key]!['cantidad']}");
  }

  // Restar salidas
  for (var salida in salidas) {
    final key =
        "${salida['proceso']}_${salida['tipo_acero']}_${salida['descripcion']}";

    if (!agrupados.containsKey(key)) {
      agrupados[key] = {
        "proceso": salida['proceso'],
        "tipo_acero": salida['tipo_acero'],
        "descripcion": salida['descripcion'],
        "ingresos": <Map<String, dynamic>>[],
        "salidas": <Map<String, dynamic>>[],
        "cantidad": 0.0,
      };
    }

    agrupados[key]!["salidas"].add(salida);
    agrupados[key]!["cantidad"] -= salida['cantidad'] ?? 0.0;

    print("➖ SALIDA -> Proceso: ${salida['proceso']}, "
        "Tipo: ${salida['tipo_acero']}, Desc: ${salida['descripcion']}, "
        "Cant: ${salida['cantidad']}, "
        "Acumulado: ${agrupados[key]!['cantidad']}");
  }

  print("============== RESULTADOS FINALES ==============");
  agrupados.forEach((key, value) {
    print("✅ STOCK FINAL -> "
        "Proceso: ${value['proceso']}, "
        "Tipo: ${value['tipo_acero']}, "
        "Desc: ${value['descripcion']}, "
        "Stock: ${value['cantidad']}");
  });

  print("===============================================");

  return agrupados.values.toList();
}

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fecha = DateFormat('yyyy-MM-dd').format(now);
    final mes = DateFormat('MMMM').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock de Aceros"),
        backgroundColor: const Color(0xFF21899C),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _stockFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text("No hay datos de stock"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                    "${item['proceso']} - ${item['tipo_acero']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      "Fecha: $fecha | Mes: $mes\nDescripción: ${item['descripcion']}"),
                  trailing: Text(
                    "Stock: ${item['cantidad']}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold),
                  ),
                  children: [
  const Padding(
    padding: EdgeInsets.all(8.0),
    child: Text("📥 Ingresos",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green)),
  ),

  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(item['ingresos'].length, (i) {
        final ing = item['ingresos'][i];
        return Container(
          width: MediaQuery.of(context).size.width / 5 - 16,  // 4 por fila
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.add, color: Colors.green, size: 18),
              Text("T: ${ing['turno']}", style: const TextStyle(fontSize: 12)),
              Text("C: ${ing['cantidad']}",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    ),
  ),

  const Padding(
    padding: EdgeInsets.all(8.0),
    child: Text("📤 Salidas",
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red)),
  ),

  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(item['salidas'].length, (i) {
        final sal = item['salidas'][i];
        return Container(
          width: MediaQuery.of(context).size.width / 5 - 16,  // 4 por fila
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.remove, color: Colors.red, size: 18),
              Text("Eq: ${sal['equipo']}", style: const TextStyle(fontSize: 12)),
              Text("C: ${sal['cantidad']}",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    ),
  ),
],

                ),
              );
            },
          );
        },
      ),
    );
  }
}
