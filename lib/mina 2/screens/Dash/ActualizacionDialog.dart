import 'package:flutter/material.dart';

class ActualizacionDialog extends StatefulWidget {
  final Map<String, bool> opcionesIniciales;

  const ActualizacionDialog({Key? key, required this.opcionesIniciales}) : super(key: key);

  @override
  _ActualizacionDialogState createState() => _ActualizacionDialogState();
}

class _ActualizacionDialogState extends State<ActualizacionDialog> {
  late Map<String, bool> opcionesSeleccionadas;

  @override
  void initState() {
    super.initState();
    opcionesSeleccionadas = Map<String, bool>.from(widget.opcionesIniciales);
  }

  void _toggleTodos(bool seleccionar) {
    setState(() {
      for (var key in opcionesSeleccionadas.keys) {
        opcionesSeleccionadas[key] = seleccionar;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seleccionar actualizaciones'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botones para seleccionar/deseleccionar todos
            Row(
              children: [
                TextButton(
                  onPressed: () => _toggleTodos(true),
                  child: Text('Seleccionar todos'),
                ),
                TextButton(
                  onPressed: () => _toggleTodos(false),
                  child: Text('Deseleccionar todos'),
                ),
              ],
            ),
            Divider(),
            // Lista de opciones
            ...opcionesSeleccionadas.entries.map((entry) => CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      opcionesSeleccionadas[entry.key] = value ?? false;
                    });
                  },
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Verificar que al menos una opción esté seleccionada
            final haySeleccionadas = opcionesSeleccionadas.values.any((v) => v);
            if (haySeleccionadas) {
              Navigator.of(context).pop(opcionesSeleccionadas);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selecciona al menos una opción')),
              );
            }
          },
          child: Text('Actualizar'),
        ),
      ],
    );
  }
}