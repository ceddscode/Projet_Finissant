import 'package:flutter/material.dart';

class OverlayWidget extends StatelessWidget {
  final double extent;
  const OverlayWidget({required this.extent, super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: extent >= 0.6 ? 0.35 : 0.0,
        child: Container(color: Colors.black),
      ),
    );
  }
}
