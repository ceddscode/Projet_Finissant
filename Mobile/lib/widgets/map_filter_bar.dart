import 'package:flutter/material.dart';
import 'chip_button.dart';
import 'filter_dialogs.dart';
import '../generated/l10n.dart';

/// Barre de filtres horizontale pour la carte
class MapFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final int? selectedCategory;
  final String? selectedNeighborhood;
  final String selectedDistance;
  final bool resetActive;
  final VoidCallback onReset;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
  final ValueChanged<String> onDistanceChanged;

  const MapFilterBar({
    super.key,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.selectedNeighborhood,
    required this.selectedDistance,
    required this.resetActive,
    required this.onReset,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onNeighborhoodChanged,
    required this.onDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChipButton(
            label: s.reset,
            icon: Icons.close,
            active: resetActive,
            onTap: onReset,
          ),
          const SizedBox(width: 8),
          ChipButton(
            label: s.status,
            icon: Icons.tune,
            active: selectedStatus != '' && selectedStatus != null,
            onTap: () async {
              final result = await FilterDialogs.pickStatus(context, s);
              onStatusChanged(result);
            },
          ),
          const SizedBox(width: 8),
          ChipButton(
            label: selectedCategory == null
                ? s.category
                : FilterDialogs.getCategoryLabel(selectedCategory!, s),
            icon: Icons.category,
            active: selectedCategory != null,
            onTap: () async {
              final result = await FilterDialogs.pickCategory(context, s);
              onCategoryChanged(result);
            },
          ),

          const SizedBox(width: 8),
          ChipButton(
            label: selectedNeighborhood ?? s.quartier,
            icon: Icons.location_pin,
            active: selectedNeighborhood != null,
            onTap: () async {
              final picked = await FilterDialogs.pickQuartier(context, s);
              onNeighborhoodChanged(picked);
            },
          ),
          const SizedBox(width: 8),
          ChipButton(
            label: selectedDistance == 'Closest' ? s.closest : s.farthest,
            icon: Icons.near_me,
            active: true,
            onTap: () async {
              final result = await FilterDialogs.pickDistance(context, s);
              if (result != null) {
                onDistanceChanged(result);
              }
            },
          ),
        ],
      ),
    );
  }
}
