import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeIndexProvider = StateProvider<int>((ref) => 0);
final showSubscriptionAlertProvider = StateProvider<bool>((ref) => false);
final timeLeftMessageProvider = StateProvider<String>((ref) => '');

