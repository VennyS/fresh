import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh/models/location.dart';
import 'package:fresh/providers/product_provider.dart';

class EditLocationDialog extends StatefulWidget {
  final Location? location;

  const EditLocationDialog({super.key, this.location});

  @override
  EditLocationDialogState createState() => EditLocationDialogState();
}

class EditLocationDialogState extends State<EditLocationDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<ProductProvider>();

      if (widget.location == null) {
        // Добавление новой локации
        await provider.addLocation(_nameController.text);
      } else {
        // Редактирование существующей
        await provider.updateLocation(
          widget.location!.id,
          _nameController.text,
        );
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _deleteLocation() async {
    if (widget.location == null) return;

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить место хранения?'),
            content: Text(
              'Вы уверены, что хотите удалить "${widget.location!.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Удалить',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete && mounted) {
      await context.read<ProductProvider>().deleteLocation(widget.location!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.location == null
                    ? 'Добавить место хранения'
                    : 'Редактировать место',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название места',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите название';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.location != null)
                    TextButton(
                      onPressed: _deleteLocation,
                      child: const Text(
                        'Удалить',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      widget.location == null ? 'Добавить' : 'Сохранить',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
