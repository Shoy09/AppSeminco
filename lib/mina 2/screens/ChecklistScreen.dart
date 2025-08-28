import 'package:flutter/material.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';

class ChecklistScreen extends StatefulWidget {
  final int operacionId;

  const ChecklistScreen({
    Key? key,
    required this.operacionId,
  }) : super(key: key);

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<ChecklistItem> checklistItems = [];

  @override
  void initState() {
    super.initState();
    fetchAllCheckListItems();
  }

  Future<void> fetchAllCheckListItems() async {
    final dbHelper = DatabaseHelper_Mina2();
    final allItems = await dbHelper.getCheckListOperacionByOperacionId(widget.operacionId);

    setState(() {
      checklistItems = allItems
          .map((item) => ChecklistItem(
                item['id'],
                item['descripcion'],
                value: item['decision'] == null ? null : item['decision'] == 1,
                observaciones: item['observacion'],
              ))
          .toList();
    });
  }

  @override
  void dispose() {
    _disposeControllers(checklistItems);
    super.dispose();
  }

  void _disposeControllers(List<ChecklistItem> items) {
    for (var item in items) {
      item.dispose();
    }
  }

  Future<void> guardarChecklist() async {
    final dbHelper = DatabaseHelper_Mina2();
    bool hasChanges = false;

    for (var item in checklistItems) {
      if (item.value != null || item.observaciones.isNotEmpty) {
        int decision = item.value == true ? 1 : 0;
        
        int updated = await dbHelper.updateCheckListOperacion(
          id: item.id,
          decision: decision,
          observacion: item.observaciones,
        );
        
        if (updated > 0) {
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist guardado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        backgroundColor: const Color(0xFF21899C),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Espacio para el botón flotante
        child: ChecklistTab(items: checklistItems),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await guardarChecklist();
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}

class ChecklistItem {
  final int id;
  final String title;
  bool? value;
  String observaciones;
  bool showObservaciones;
  late final TextEditingController observacionesController;

  ChecklistItem(
    this.id,
    this.title, {
    this.value,
    String? observaciones,
    this.showObservaciones = false,
  }) : observaciones = observaciones ?? '' {
    observacionesController = TextEditingController(text: observaciones ?? '');
  }

  void dispose() {
    observacionesController.dispose();
  }
}

class ChecklistTab extends StatefulWidget {
  final List<ChecklistItem> items;

  const ChecklistTab({Key? key, required this.items}) : super(key: key);

  @override
  _ChecklistTabState createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botones de acción global
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (var item in widget.items) {
                      item.value = true;
                    }
                  });
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Todos Sí"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (var item in widget.items) {
                      item.value = false;
                      item.showObservaciones = false;
                    }
                  });
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text("Todos No"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (var item in widget.items) {
                      item.value = null;
                    }
                  });
                },
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text("Limpiar"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
            ],
          ),
        ),

        // Lista de checklist
        Expanded(
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildChecklistItem(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    if (item.observacionesController.text != item.observaciones) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (item.observacionesController.text != item.observaciones) {
          item.observacionesController.text = item.observaciones;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRadioOption(item, true, 'Sí'),
                        const SizedBox(width: 4),
                        _buildRadioOption(item, false, 'No'),
                      ],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      item.showObservaciones = !item.showObservaciones;
                    });
                  },
                ),
                if (item.showObservaciones)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: item.observacionesController,
                      decoration: InputDecoration(
                        hintText: 'Escriba sus observaciones aquí...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (text) {
                        item.observaciones = text;
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(ChecklistItem item, bool value, String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          item.value = value;
          if (value == false) {
            item.showObservaciones = true;
          }
        });
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 65),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: item.value == value ? const Color(0xFF21899C) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<bool>(
              value: value,
              groupValue: item.value,
              onChanged: (bool? newValue) {
                setState(() {
                  item.value = newValue;
                  if (newValue == false) {
                    item.showObservaciones = true;
                  }
                });
              },
              activeColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              text,
              style: TextStyle(
                color: item.value == value ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}