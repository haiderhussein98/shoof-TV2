﻿import 'package:flutter_riverpod/flutter_riverpod.dart';

final serverProvider = StateProvider<String>((ref) => "");
final usernameProvider = StateProvider<String>((ref) => "");
final passwordProvider = StateProvider<String>((ref) => "");

final subscriptionStartProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);
final subscriptionEndProvider = StateProvider<DateTime>(
  (ref) => DateTime.now().add(const Duration(days: 90)),
);
final subscriptionTypeProvider = StateProvider<String>((ref) => "ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ");

