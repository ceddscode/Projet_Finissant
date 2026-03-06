import 'package:flutter/material.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:municipalgo/widgets/map_filter_bar.dart';
import 'package:municipalgo/widgets/search_bar.dart';

class SearchFiltersWidget extends StatelessWidget {
  final TextEditingController controller;
  final S s;
  final bool resetActive;
  final String? selectedStatus;
  final int? selectedCategory;
  final String? selectedNeighborhood;
  final String selectedDistance;
  final VoidCallback onReset;
  final VoidCallback onClear;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
  final ValueChanged<String> onDistanceChanged;

  const SearchFiltersWidget({
    required this.controller,
    required this.s,
    required this.resetActive,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.selectedNeighborhood,
    required this.selectedDistance,
    required this.onReset,
    required this.onClear,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onNeighborhoodChanged,
    required this.onDistanceChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TopSearchBar(
              controller: controller,
              hint: s.search,
              onClear: () {
                controller.clear();
                onClear();
              },
            ),
            const SizedBox(height: 10),
            MapFilterBar(
              selectedStatus: selectedStatus,
              selectedCategory: selectedCategory,
              selectedNeighborhood: selectedNeighborhood,
              selectedDistance: selectedDistance,
              resetActive: resetActive,
              onReset: onReset,
              onStatusChanged: onStatusChanged,
              onCategoryChanged: onCategoryChanged,
              onNeighborhoodChanged: onNeighborhoodChanged,
              onDistanceChanged: onDistanceChanged,
            ),
          ],
        ),
      ),
    );
  }
}
