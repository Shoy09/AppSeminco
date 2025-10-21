import 'package:app_seminco/components/reportes/CompactReportButton%20.dart';
import 'package:app_seminco/mina%202/screens/Aceros/StockPage.dart';
import 'package:app_seminco/mina%202/screens/Aceros/entrada_page.dart';
import 'package:app_seminco/mina%202/screens/Aceros/salida_page.dart';
import 'package:flutter/material.dart';

class SeleccEntradaSalida extends StatelessWidget {
  const SeleccEntradaSalida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada / Salida'),
        backgroundColor: const Color(0xFF21899C),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Aquí navegas a tu pantalla de stock
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StockPage()));
            },
            icon: const Icon(Icons.inventory, color: Colors.white),
            label: const Text(
              "Stock",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón Entrada
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.35,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpandedReportButton(
                    title: 'ENTRADA',
                    backgroundColor: const Color(0xFF21899C),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EntradaPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Botón Salida
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.35,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpandedReportButton(
                    title: 'SALIDA',
                    backgroundColor: const Color(0xFF4CAF50),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalidaPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
