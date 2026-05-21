import 'package:flutter/material.dart';

import '../models/laundry_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final LaundryStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: status.color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: status.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
