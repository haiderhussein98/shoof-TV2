import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/providers/user_providers.dart';

final authViewModelProvider = FutureProvider<bool>((ref) async {
  final api = ref.read(userServiceProvider);
  return await api.validateLogin();
});
