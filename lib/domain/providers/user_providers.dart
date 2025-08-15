import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/viewmodels/auth_provider.dart';
import '../../data/services/user_service.dart';
import 'core_providers.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(
    ref.watch(serverProvider),
    ref.watch(usernameProvider),
    ref.watch(passwordProvider),
  );
});

final userInfoInitializerProvider = FutureProvider<void>((ref) async {
  final userService = ref.read(userServiceProvider);

  try {
    final userInfo = await userService.getUserInfo();

    final expDateString = userInfo['exp_date'] as String?;
    final createdAtString = userInfo['created_at'] as String?;

    if (expDateString != null && createdAtString != null) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        int.parse(createdAtString) * 1000,
      );
      final expDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expDateString) * 1000,
      );

      ref.read(subscriptionStartProvider.notifier).state = createdAt;
      ref.read(subscriptionEndProvider.notifier).state = expDate;

      final diffDays = expDate.difference(createdAt).inDays;

      if (diffDays <= 31) {
        ref.read(subscriptionTypeProvider.notifier).state = 'ØªØ¬Ø±ÙŠØ¨ÙŠ';
      } else if (diffDays <= 93) {
        ref.read(subscriptionTypeProvider.notifier).state = '3 Ø£Ø´Ù‡Ø±';
      } else if (diffDays <= 186) {
        ref.read(subscriptionTypeProvider.notifier).state = '6 Ø£Ø´Ù‡Ø±';
      } else {
        ref.read(subscriptionTypeProvider.notifier).state = 'Ø³Ù†Ø©';
      }
    } else {}
  } catch (e) {
    await ref.read(authProvider.notifier).logout();
    rethrow;
  }
});

