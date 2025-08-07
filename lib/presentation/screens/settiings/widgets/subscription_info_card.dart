import 'package:flutter/material.dart';

class SubscriptionInfoCard extends StatelessWidget {
  final String startDate;
  final String endDate;
  final bool isTablet;

  const SubscriptionInfoCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBox(Icons.calendar_today, 'تاريخ البداية', startDate),
          _buildBox(Icons.event, 'تاريخ الانتهاء', endDate),
        ],
      ),
    );
  }

  Widget _buildBox(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: isTablet ? 28 : 22),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(color: Colors.white60, fontSize: isTablet ? 14 : 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
