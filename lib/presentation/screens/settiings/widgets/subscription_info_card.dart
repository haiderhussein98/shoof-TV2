import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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
          _buildBox(
            context,
            materialIcon: Icons.calendar_today,
            cupertinoIcon: CupertinoIcons.calendar,
            title: 'تاريخ البداية',
            value: startDate,
          ),
          _buildBox(
            context,
            materialIcon: Icons.event,
            cupertinoIcon: CupertinoIcons.calendar,
            title: 'تاريخ الانتهاء',
            value: endDate,
          ),
        ],
      ),
    );
  }

  Widget _buildBox(
    BuildContext context, {
    required IconData materialIcon,
    required IconData cupertinoIcon,
    required String title,
    required String value,
  }) {
    final iconData = isCupertino(context) ? cupertinoIcon : materialIcon;

    return Column(
      children: [
        Icon(iconData, color: Colors.white70, size: isTablet ? 28 : 22),
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
