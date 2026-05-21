import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../data/home_dummy_data.dart';

class HourlyRecommendationCard extends StatelessWidget {
  const HourlyRecommendationCard({
    super.key,
    required this.slot,
  });

  final HourlyLaundrySlot slot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.timeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StatusChip(status: slot.status),
            const SizedBox(height: 12),
            Text(
              slot.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
