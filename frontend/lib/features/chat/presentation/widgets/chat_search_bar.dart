import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasQuery;
  final VoidCallback onClear;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onArchiveTap;
  final VoidCallback onNewChatTap;
  final bool isDark;

  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hasQuery,
    required this.onClear,
    required this.sortBy,
    required this.onSortChanged,
    required this.onArchiveTap,
    required this.onNewChatTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.bgColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar conversas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: onClear,
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.lightGray,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Spacing.hSm,
              BrutalistIconButton(
                icon: Icons.archive,
                size: 48,
                onTap: onArchiveTap,
              ),
              Spacing.hSm,
              BrutalistIconButton(
                icon: Icons.edit,
                size: 48,
                iconColor: AppColors.onPrimary,
                gradient: AppColors.brutalistGradient,
                onTap: onNewChatTap,
              ),
            ],
          ),
          Spacing.vSm,
          Row(
            children: [
              _buildSortChip(context, 'Recentes', 'recent'),
              Spacing.hSm,
              _buildSortChip(context, 'Nome', 'name'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, String label, String value) {
    final isSelected = sortBy == value;
    return GestureDetector(
      onTap: () => onSortChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
