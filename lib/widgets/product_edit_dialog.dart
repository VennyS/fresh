import 'package:flutter/material.dart';
import 'package:fresh/models/product.dart';
import 'package:fresh/providers/product_provider.dart';
import 'package:fresh/utils/format_date.dart';
import 'package:fresh/utils/parse_date.dart';
import 'package:provider/provider.dart';

class ProductEditDialog extends StatefulWidget {
  final Product? productToEdit;

  const ProductEditDialog({super.key, this.productToEdit});

  @override
  ProductEditDialogState createState() => ProductEditDialogState();
}

class ProductEditDialogState extends State<ProductEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _expirationController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  int? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.productToEdit?.name ?? '',
    );
    _expirationController = TextEditingController(
      text: widget.productToEdit?.expirationDate ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.productToEdit?.quantity?.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: widget.productToEdit?.unit ?? '',
    );
    _selectedLocationId = widget.productToEdit?.locationId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expirationController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _expirationController.text = formatDate(picked);
    }
  }

  void onPressedSave() async {
    if (_nameController.text.isNotEmpty && _selectedLocationId != null) {
      final newProduct = Product(
        id: widget.productToEdit?.id ?? 0,
        name: _nameController.text,
        locationId: _selectedLocationId!,
        expirationDate: _expirationController.text.isEmpty
            ? null
            : formatDate(parseDate(_expirationController.text)!),
        quantity: _quantityController.text.isEmpty
            ? null
            : int.tryParse(_quantityController.text),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
        addedDate: widget.productToEdit?.addedDate ?? DateTime.now(),
      );

      final provider = context.read<ProductProvider>();
      if (widget.productToEdit == null) {
        await provider.addProduct(
          name: newProduct.name,
          locationId: newProduct.locationId,
          expirationDate: newProduct.expirationDate,
          quantity: newProduct.quantity,
          unit: newProduct.unit,
        );
      } else {
        await provider.updateProduct(newProduct);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          widget.productToEdit == null
              ? 'Добавить продукт'
              : 'Редактировать продукт',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expirationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Срок годности (ГГГГ-ММ-ДД)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 12),
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Место хранения',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...provider.locations.map(
                        (location) => DropdownMenuItem<int>(
                          value: location.id,
                          child: Text(
                            location.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedLocationId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Количество',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Ед. измерения (шт, кг, л)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: onPressedSave,
            child: Text(
              widget.productToEdit == null ? 'Добавить' : 'Сохранить',
            ),
          ),
        ],
      ),
    );
  }
}
