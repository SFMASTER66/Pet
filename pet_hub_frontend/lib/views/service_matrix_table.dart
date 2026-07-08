import 'package:flutter/material.dart';

class ServiceMatrixTable extends StatelessWidget {
  final bool isAdmin;
  final bool isLoading;
  final bool isVisible;
  final List<Map<String, dynamic>> matrices;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAddRequested;
  final Function(dynamic) onDeleteRequested;

  const ServiceMatrixTable({
    super.key,
    required this.isAdmin,
    required this.isLoading,
    required this.isVisible,
    required this.matrices,
    required this.onToggleVisibility,
    required this.onAddRequested,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: const Text('Service Matrix Configurator', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(isVisible ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right),
            onTap: onToggleVisibility,
            trailing: isAdmin && isVisible 
              ? ElevatedButton.icon(onPressed: onAddRequested, icon: const Icon(Icons.add), label: const Text('Add Entry'))
              : null,
          ),
          if (isVisible) ...[
            isLoading && matrices.isEmpty
              ? const CircularProgressIndicator()
              : Table(
                  children: [
                    const TableRow(children: [Text('Variant'), Text('Coat'), Text('Weight'), Text('Price'), Text('Actions')]),
                    ...matrices.map((matrix) => TableRow(children: [
                          Text(matrix['name'] ?? ''),
                          Text(matrix['coatType'] ?? ''),
                          Text(matrix['weightTier'] ?? ''),
                          Text('\$${((matrix['priceCentsAud'] ?? 0) / 100).toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDeleteRequested(matrix['id']),
                          )
                        ]))
                  ],
                )
          ]
        ],
      ),
    );
  }
}