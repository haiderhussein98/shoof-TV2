import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/providers/core_providers.dart';

class UserInfoCard extends ConsumerWidget {
  final String username;
  final bool isActive;
  final bool isTablet;

  const UserInfoCard({
    super.key,
    required this.username,
    required this.isActive,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionType = ref.watch(subscriptionTypeProvider);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isActive ? Colors.green : Colors.red,
            radius: isTablet ? 32 : 28,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'الاشتراك نشط' : 'الاشتراك منتهي',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'نوع الاشتراك: $subscriptionType',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 15 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
