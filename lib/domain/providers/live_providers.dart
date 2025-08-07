import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/live_service.dart';
import 'core_providers.dart';

final liveServiceProvider = Provider<LiveService>((ref) {
  return LiveService(
    ref.watch(serverProvider),
    ref.watch(usernameProvider),
    ref.watch(passwordProvider),
  );
});
