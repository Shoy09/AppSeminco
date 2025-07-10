import 'package:app_seminco/components/reportes/CompactReportButton%20.dart';
import 'package:app_seminco/mina%202/screens/Mediciones/horizontal/horizontal.dart';
import 'package:app_seminco/mina%202/screens/Mediciones/largo/largo.dart';
import 'package:app_seminco/mina%202/screens/Mediciones/prueba.dart';
import 'package:flutter/material.dart';
import 'package:app_seminco/mina%202/screens/Mediciones/inicio.dart';

class Selecc_Tipo_explo extends StatelessWidget {
  const Selecc_Tipo_explo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operaciones Mineras'),
        backgroundColor: Color(0xFF21899C),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón 1
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4, // 40% del ancho
                height: MediaQuery.of(context).size.height * 0.35, // 35% del alto
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpandedReportButton(
                    title: 'PERFORACIÓN\nTALADROS LARGOS',
                    imagePath: 'assets/images/perforacion_taladros.png',
                    backgroundColor: const Color(0xFF21899C),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistroExplosivoPagelargo(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Botón 2
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4, // 40% del ancho
                height: MediaQuery.of(context).size.height * 0.35, // 35% del alto
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpandedReportButton(
                    title: 'PERFORACIÓN\nHORIZONTAL',
                    imagePath: 'assets/images/perfo_horizontal.png',
                    backgroundColor: const Color(0xFF4CAF50),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistroExplosivoPagehorizontal(),
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