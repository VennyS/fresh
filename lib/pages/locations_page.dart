import 'package:flutter/material.dart';
import 'package:fresh/models/location.dart';
import 'package:fresh/models/product.dart';
import 'package:fresh/providers/product_provider.dart';
import 'package:fresh/widgets/edit_location_dialog.dart';
import 'package:provider/provider.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final Map<int, bool> _expandedLocations = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои места хранения')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.locations.isEmpty) {
            return const Center(
              child: Text(
                'Добавьте места хранения',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.locations.length,
            itemBuilder: (context, index) {
              final location = provider.locations[index];
              final products = provider.getProductsByLocation(location.id);

              return GestureDetector(
                onLongPress: () => _showEditLocationDialog(location),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    key: ValueKey(location.id),
                    initiallyExpanded: _expandedLocations[location.id] ?? false,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedLocations[location.id] = expanded;
                      });
                    },
                    title: Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '${products.length}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    children: [
                      if (products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Нет продуктов в этом месте',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...products.map(
                          (product) => _buildProductItem(product),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.expirationDate != null)
            Text(
              'Годен до: ${product.expirationDate}',
              style: const TextStyle(fontSize: 14),
            ),
          if (product.quantity != null && product.unit != null)
            Text(
              '${product.quantity} ${product.unit}',
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteProduct(product),
      ),
    );
  }

  void _deleteProduct(Product product) {
    final provider = context.read<ProductProvider>();
    provider.deleteProduct(product.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удален: ${product.name}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            provider.addProduct(
              name: product.name,
              locationId: product.locationId,
              expirationDate: product.expirationDate,
              quantity: product.quantity,
              unit: product.unit,
            );
          },
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => const EditLocationDialog(),
    );
  }

  void _showEditLocationDialog(Location location) {
    showDialog(
      context: context,
      builder: (context) => EditLocationDialog(location: location),
    );
  }
}
