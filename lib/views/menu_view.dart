// views/menu_view.dart
// Equivalente a MenuView.swift

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chef_alysson/models/food_category.dart';
import 'package:chef_alysson/models/menu_item.dart';
import 'package:chef_alysson/services/auth_service.dart';
import 'package:chef_alysson/services/cart_store.dart';
import 'package:chef_alysson/services/manutencao_service.dart';
import 'package:chef_alysson/services/menu_service.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  FoodCategory _selectedCategory = FoodCategory.combos;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> _filteredItems(MenuService menu) {
    if (_searchText.isNotEmpty) {
      return menu.search(_searchText);
    }
    return menu.byCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuService>();
    final auth = context.watch<AuthService>();
    final emManutencao =
        !auth.isAdmin && context.watch<ManutencaoService>().emManutencao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍣 Cardápio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchText = v),
              decoration: InputDecoration(
                hintText: 'Buscar prato...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner de manutenção
          if (emManutencao)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orange.shade50,
              child: const Row(
                children: [
                  Text('🍣', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pedidos temporariamente indisponíveis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chips de categoria (visíveis somente fora da busca)
          if (_searchText.isEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: FoodCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final cat = FoodCategory.values[index];
                  final selected = cat == _selectedCategory;
                  return _CategoryChip(
                    category: cat,
                    isSelected: selected,
                    onTap: () => setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),

          // Lista de itens
          Expanded(
            child: menu.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _filteredItems(menu).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        _MenuItemRow(item: _filteredItems(menu)[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip de categoria
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final FoodCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linha do cardápio
// ---------------------------------------------------------------------------

class _MenuItemRow extends StatelessWidget {
  final MenuItem item;

  const _MenuItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final qty = cart.quantity(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji do prato
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 14),

          // Descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.details,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item.priceFormatted,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.red)),
              ],
            ),
          ),

          // Controle de quantidade
          if (qty == 0)
            IconButton(
              icon: const Icon(Icons.add_circle,
                  color: Colors.red, size: 32),
              onPressed: () => context.read<CartStore>().add(item),
              padding: EdgeInsets.zero,
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle,
                      color: Colors.red, size: 26),
                  onPressed: () => context.read<CartStore>().remove(item),
                  padding: EdgeInsets.zero,
                ),
                SizedBox(
                  width: 22,
                  child: Text('$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.red, size: 26),
                  onPressed: () => context.read<CartStore>().add(item),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
