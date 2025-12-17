// widgets/report_category_chip.dart
import 'package:flutter/material.dart';

class ReportCategoryChip extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReportCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(category),
      selected: selected,
      onSelected: (_) => onTap(),
      onDeleted: onDelete,
      deleteIconColor: Colors.blue.shade800,
      backgroundColor: selected ? Colors.blue.shade50 : Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.blue.shade800 : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Colors.blue.shade300 : Colors.grey.shade300,
        ),
      ),
    );
  }
}
