import 'package:flutter/material.dart';

class AtmosBadge extends StatelessWidget {
  final bool isAtmosSource;
  final VoidCallback? onTap;

  const AtmosBadge({
    super.key,
    required this.isAtmosSource,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAtmosSource) {
      return const SizedBox.shrink();
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: const Text(
        'DOLBY ATMOS SOURCE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }
}
