import 'package:flutter/material.dart';

class TopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;

  const TopSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: StatefulBuilder(
        builder: (context, setLocal) {
          controller.addListener(() => setLocal(() {}));

          return TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              isDense: true,
            ),
          );
        },
      ),
    );
  }
}
