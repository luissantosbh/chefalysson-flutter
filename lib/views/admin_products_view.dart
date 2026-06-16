// views/admin_products_view.dart
// Tela de gerenciamento de produtos — exclusiva para admins.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chef_alysson/models/food_category.dart';
import 'package:chef_alysson/models/menu_item.dart';
import 'package:chef_alysson/services/menu_service.dart';

class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Produtos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
        backgroundColor: const Color(0xFFBF1921),
        foregroundColor: Colors.white,
      ),
      body: menu.isLoading
          ? const Center(child: CircularProgressIndicator())
          : menu.items.isEmpty
              ? const Center(child: Text('Nenhum produto cadastrado'))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: menu.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) =>
                      _ProductTile(item: menu.items[i]),
                ),
    );
  }

  static void _openForm(BuildContext context, MenuItem? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ProductFormView(existing: existing),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile do produto na lista
// ---------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  final MenuItem item;
  const _ProductTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text('Excluir',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context, item.name),
      onDismissed: (_) => context.read<MenuService>().deleteItem(item.id),
      child: ListTile(
        onTap: () => AdminProductsView._openForm(context, item),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(item.category.label,
            style: const TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.priceFormatted,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir produto'),
            content: Text('Tem certeza que deseja excluir "$name"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }
}

// ---------------------------------------------------------------------------
// Formulário de produto (adicionar / editar)
// ---------------------------------------------------------------------------

class _ProductFormView extends StatefulWidget {
  final MenuItem? existing;
  const _ProductFormView({this.existing});

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _details;
  late final TextEditingController _price;
  late final TextEditingController _emoji;
  late FoodCategory _category;
  bool _isSaving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = TextEditingController(text: e?.id ?? '');
    _name = TextEditingController(text: e?.name ?? '');
    _details = TextEditingController(text: e?.details ?? '');
    _price = TextEditingController(
        text: e != null ? e.price.toStringAsFixed(2) : '');
    _emoji = TextEditingController(text: e?.emoji ?? '🍣');
    _category = e?.category ?? FoodCategory.combos;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _details.dispose();
    _price.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Gera ID a partir do nome se for novo produto
    final rawId = isEditing
        ? widget.existing!.id
        : (_id.text.trim().isNotEmpty
            ? _id.text.trim()
            : _name.text
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '_'));

    final item = MenuItem(
      id: rawId,
      name: _name.text.trim(),
      details: _details.text.trim(),
      price: double.parse(_price.text.replaceAll(',', '.')),
      category: _category,
      emoji: _emoji.text.trim(),
    );

    try {
      final menu = context.read<MenuService>();
      if (isEditing) {
        await menu.updateItem(item);
      } else {
        await menu.addItem(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Emoji + nome lado a lado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: InputDecoration(
                      labelText: 'Emoji',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 14),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nome *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _details,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Preço (R\$) *',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obrigatório';
                      final d = double.tryParse(v.replaceAll(',', '.'));
                      if (d == null || d <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<FoodCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    items: FoodCategory.values
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
