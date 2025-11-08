import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/ejecutado/explo/horizontal_ejecutado.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/ejecutado/listar_mediciones.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/ejecutado/remanente/MedicionesRemanentesScreen.dart';
import 'package:flutter/material.dart';

class MedicionesCentralizadasScreen extends StatefulWidget {


  const MedicionesCentralizadasScreen({
    Key? key,
  }) : super(key: key);

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
            RegistroExplosivoPagehorizontalEjecutado(
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