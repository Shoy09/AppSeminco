// Función para mostrar diálogo de nueva labor
import 'package:app_seminco/mina%201/models/PlanTrabajo.dart';
import 'package:flutter/material.dart';

Future<Map<String, String>?> mostrarDialogoNuevaLabor(
  BuildContext context,
  List<PlanTrabajo> planesCompletos,
  List<String> zonas,
  List<String> tiposLabor,
  List<String> labores,
  List<String> alas,
  List<String> vetas,
) async {
  String? selectedZona;
  String? selectedTipoLabor;
  String? selectedLabor;
  String? selectedAla;
  String? selectedVeta;

  return showDialog<Map<String, String>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Función para actualizar las listas filtradas
          void updateFilteredLists() {
            // Filter Tipos Labor based on selected Zona
            List<String> filteredTiposLabor = selectedZona != null
                ? planesCompletos
                    .where((plan) => plan.zona == selectedZona)
                    .map((plan) => plan.tipoLabor)
                    .where((tipoLabor) => tipoLabor.isNotEmpty)
                    .toSet()
                    .toList()
                : List.from(tiposLabor);

            // Filter Labores based on selected Zona and TipoLabor
            List<String> filteredLabores = (selectedZona != null || selectedTipoLabor != null)
                ? planesCompletos
                    .where((plan) =>
                        (selectedZona == null || plan.zona == selectedZona) &&
                        (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor))
                    .map((plan) => plan.labor)
                    .where((labor) => labor.isNotEmpty)
                    .toSet()
                    .toList()
                : List.from(labores);

            // Filter Alas based on selected Zona, TipoLabor and Labor
            List<String> filteredAlas = (selectedZona != null || selectedTipoLabor != null || selectedLabor != null)
                ? planesCompletos
                    .where((plan) =>
                        (selectedZona == null || plan.zona == selectedZona) &&
                        (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor) &&
                        (selectedLabor == null || plan.labor == selectedLabor))
                    .map((plan) => plan.ala)
                    .where((ala) => ala.isNotEmpty)
                    .toSet()
                    .toList()
                : List.from(alas);

            // Filter Vetas based on previous selections (including Ala)
            List<String> filteredVetas = (selectedZona != null || selectedTipoLabor != null || selectedLabor != null || selectedAla != null)
                ? planesCompletos
                    .where((plan) =>
                        (selectedZona == null || plan.zona == selectedZona) &&
                        (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor) &&
                        (selectedLabor == null || plan.labor == selectedLabor) &&
                        (selectedAla == null || plan.ala == selectedAla))
                    .map((plan) => plan.estructuraVeta)
                    .where((veta) => veta.isNotEmpty)
                    .toSet()
                    .toList()
                : List.from(vetas);

            // Actualizar el estado con las listas filtradas
            setState(() {
              // No necesitamos almacenar las listas filtradas en variables separadas,
              // las usamos directamente en los DropdownButtonFormField
            });
          }

          // Llamar a updateFilteredLists inicialmente
          updateFilteredLists();

          return AlertDialog(
            title: Text("Nueva Información de Labor"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector de Zona
                  DropdownButtonFormField<String>(
                    value: selectedZona,
                    decoration: InputDecoration(labelText: "Zona"),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Seleccionar Zona")),
                      ...zonas.map((zona) {
                        return DropdownMenuItem<String>(
                          value: zona,
                          child: Text(zona),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedZona = value;
                        selectedTipoLabor = null;
                        selectedLabor = null;
                        selectedAla = null;
                        selectedVeta = null;
                        updateFilteredLists();
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Selector de Tipo Labor
                  DropdownButtonFormField<String>(
                    value: selectedTipoLabor,
                    decoration: InputDecoration(labelText: "Tipo Labor"),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Seleccionar Tipo Labor")),
                      ...planesCompletos
                          .where((plan) => selectedZona == null || plan.zona == selectedZona)
                          .map((plan) => plan.tipoLabor)
                          .where((tipoLabor) => tipoLabor.isNotEmpty)
                          .toSet()
                          .map((tipoLabor) {
                        return DropdownMenuItem<String>(
                          value: tipoLabor,
                          child: Text(tipoLabor),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedTipoLabor = value;
                        selectedLabor = null;
                        selectedAla = null;
                        selectedVeta = null;
                        updateFilteredLists();
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Selector de Labor
                  DropdownButtonFormField<String>(
                    value: selectedLabor,
                    decoration: InputDecoration(labelText: "Labor"),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Seleccionar Labor")),
                      ...planesCompletos
                          .where((plan) =>
                              (selectedZona == null || plan.zona == selectedZona) &&
                              (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor))
                          .map((plan) => plan.labor)
                          .where((labor) => labor.isNotEmpty)
                          .toSet()
                          .map((labor) {
                        return DropdownMenuItem<String>(
                          value: labor,
                          child: Text(labor),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedLabor = value;
                        selectedAla = null;
                        selectedVeta = null;
                        updateFilteredLists();
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Selector de Ala
                  DropdownButtonFormField<String>(
                    value: selectedAla,
                    decoration: InputDecoration(labelText: "Ala"),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Seleccionar Ala")),
                      ...planesCompletos
                          .where((plan) =>
                              (selectedZona == null || plan.zona == selectedZona) &&
                              (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor) &&
                              (selectedLabor == null || plan.labor == selectedLabor))
                          .map((plan) => plan.ala)
                          .where((ala) => ala.isNotEmpty)
                          .toSet()
                          .map((ala) {
                        return DropdownMenuItem<String>(
                          value: ala,
                          child: Text(ala),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedAla = value;
                        selectedVeta = null;
                        updateFilteredLists();
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Selector de Veta
                  DropdownButtonFormField<String>(
                    value: selectedVeta,
                    decoration: InputDecoration(labelText: "Veta"),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Seleccionar Veta")),
                      ...planesCompletos
                          .where((plan) =>
                              (selectedZona == null || plan.zona == selectedZona) &&
                              (selectedTipoLabor == null || plan.tipoLabor == selectedTipoLabor) &&
                              (selectedLabor == null || plan.labor == selectedLabor) &&
                              (selectedAla == null || plan.ala == selectedAla))
                          .map((plan) => plan.estructuraVeta)
                          .where((veta) => veta.isNotEmpty)
                          .toSet()
                          .map((veta) {
                        return DropdownMenuItem<String>(
                          value: veta,
                          child: Text(veta),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedVeta = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancelar"),
              ),
              TextButton(
  onPressed: () {
    if (selectedZona != null &&
        selectedTipoLabor != null &&
        selectedLabor != null &&
        selectedVeta != null) { // Ala puede ir vacío
      final nuevaInfo = <String, String>{
        'zona': selectedZona!,
        'tipo_labor': selectedTipoLabor!,
        'labor': selectedLabor!,
        'ala': selectedAla ?? '', // Si es null, enviar vacío
        'veta': selectedVeta!,
      };
      Navigator.of(context).pop(nuevaInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, complete todos los campos obligatorios")),
      );
    }
  },
  child: Text("Guardar"),
),

            ],
          );
        },
      );
    },
  );
}