import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/series_service.dart';
import 'core_providers.dart';

final seriesServiceProvider = Provider<SeriesService>((ref) {
  return SeriesService(
    ref.watch(serverProvider),
    ref.watch(usernameProvider),
    ref.watch(passwordProvider),
  );
});
