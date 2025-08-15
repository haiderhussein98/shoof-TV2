import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/vod_service.dart';
import 'core_providers.dart';

final vodServiceProvider = Provider<VodService>((ref) {
  return VodService(
    ref.watch(serverProvider),
    ref.watch(usernameProvider),
    ref.watch(passwordProvider),
  );
});

