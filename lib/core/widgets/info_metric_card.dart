import 'package:flutter/material.dart';

import '../models/laundry_status.dart';
import 'app_card.dart';

class InfoMetricCard extends StatelessWidget {
  const InfoMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
  });

  final String title;
  final String value;
  final LaundryStatus status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: status.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            foregroundColor: status.color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            status.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: status.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
