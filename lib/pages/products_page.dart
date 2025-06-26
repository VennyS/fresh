import 'package:flutter/material.dart';
import 'package:fresh/models/product.dart';
import 'package:fresh/providers/product_provider.dart';
import 'package:fresh/widgets/product_edit_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<ProductProvider>().filterProducts(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadData();
    });
  }

  void _showAddOrEditProductDialog({Product? productToEdit}) {
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(productToEdit: productToEdit),
    );
  }

  bool _isExpired(String expirationDate) {
    try {
      final now = DateTime.now();
      final format = DateFormat('dd.MM.yyyy');
      final expiry = format.parse(expirationDate);
      return now.isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои продукты')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск продуктов...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Продукты не найдены',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: provider.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = provider.filteredProducts[index];
                    final locationName = provider.getLocationName(
                      product.locationId,
                    );

                    return Dismissible(
                      key: Key('${product.id}_${product.name}'),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _showAddOrEditProductDialog(productToEdit: product);
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          provider.deleteProduct(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Удалено: ${product.name}'),
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
                      },
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("место: $locationName"),
                            if (product.expirationDate != null)
                              Text(
                                'Годен до: ${product.expirationDate}',
                                style: TextStyle(
                                  color: _isExpired(product.expirationDate!)
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            if (product.quantity != null &&
                                product.unit != null)
                              Text('${product.quantity} ${product.unit}'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAddOrEditProductDialog(productToEdit: product);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
