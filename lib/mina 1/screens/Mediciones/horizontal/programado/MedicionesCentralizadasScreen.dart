import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/programado/explo/horizontal.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/programado/listar_mediciones.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/programado/remanente/MedicionesRemanentesScreen.dart';
import 'package:flutter/material.dart';

class MedicionesCentralizadasScreen extends StatefulWidget {
final String zona;

  const MedicionesCentralizadasScreen({Key? key, required this.zona}) : super(key: key);

  @override
  _MedicionesCentralizadasScreenState createState() => _MedicionesCentralizadasScreenState();
}

class _MedicionesCentralizadasScreenState extends State<MedicionesCentralizadasScreen> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sistema de Mediciones"),
          backgroundColor: Color(0xFF21899C),
          actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListaPantalla()),
              );
            },
          ),
        ],
          bottom: TabBar(
            tabs: [
              Tab(text: "Mediciones Normales"),
              Tab(text: "Mediciones Remanentes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pantalla de mediciones normales (ya existente)
            RegistroExplosivoPagehorizontal(zona: widget.zona,
            ),
            // Pantalla de mediciones remanentes (nueva)
            MedicionesRemanentesScreen(
            ),
          ],
        ),
      ),
    );
  }
}