import 'package:flutter/material.dart';

const double kXSMax = 360;
const double kSMMax = 600;
const double kMDMax = 1024;
const double kLGMax = 1440;
const double kXLMax = 1920;

enum DeviceSize { xs, sm, md, lg, xl, xxl }

extension ContextSizeX on BuildContext {
  Size get sz => MediaQuery.sizeOf(this);
  double get w => sz.width;
  double get h => sz.height;
  double get shortest => sz.shortestSide;
  double get longest => sz.longestSide;

  DeviceSize get deviceSize {
    if (w <= kXSMax) return DeviceSize.xs;
    if (w <= kSMMax) return DeviceSize.sm;
    if (w <= kMDMax) return DeviceSize.md;
    if (w <= kLGMax) return DeviceSize.lg;
    if (w <= kXLMax) return DeviceSize.xl;
    return DeviceSize.xxl;
  }

  bool get isPhoneSmall => deviceSize == DeviceSize.xs;
  bool get isPhone =>
      deviceSize == DeviceSize.xs || deviceSize == DeviceSize.sm;
  bool get isTablet => deviceSize == DeviceSize.md;
  bool get isDesktop =>
      deviceSize == DeviceSize.lg ||
      deviceSize == DeviceSize.xl ||
      deviceSize == DeviceSize.xxl;

  bool get isTvLike {
    final ar = w / h;
    final wide = w >= 1280 && h >= 720;
    return wide && ar >= 1.6 && !isDesktop;
  }

  EdgeInsets get pagePadding {
    switch (deviceSize) {
      case DeviceSize.xs:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
      case DeviceSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
      case DeviceSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case DeviceSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case DeviceSize.xl:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case DeviceSize.xxl:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 18);
    }
  }

  double get gap {
    switch (deviceSize) {
      case DeviceSize.xs:
        return 6;
      case DeviceSize.sm:
        return 8;
      case DeviceSize.md:
        return 12;
      case DeviceSize.lg:
        return 16;
      case DeviceSize.xl:
        return 20;
      case DeviceSize.xxl:
        return 24;
    }
  }

  double get maxContentWidth {
    switch (deviceSize) {
      case DeviceSize.xs:
      case DeviceSize.sm:
        return w;
      case DeviceSize.md:
        return 900;
      case DeviceSize.lg:
        return 1200;
      case DeviceSize.xl:
        return 1400;
      case DeviceSize.xxl:
        return 1600;
    }
  }
}

int gridCols(
  BuildContext context, {
  int xs = 2,
  int sm = 2,
  int md = 4,
  int lg = 6,
  int xl = 8,
  int xxl = 10,
  int tv = 7,
}) {
  if (context.isTvLike) return tv;
  switch (context.deviceSize) {
    case DeviceSize.xs:
      return xs;
    case DeviceSize.sm:
      return sm;
    case DeviceSize.md:
      return md;
    case DeviceSize.lg:
      return lg;
    case DeviceSize.xl:
      return xl;
    case DeviceSize.xxl:
      return xxl;
  }
}

class CenteredMaxWidth extends StatelessWidget {
  final double? maxWidth;
  final Widget child;
  const CenteredMaxWidth({super.key, this.maxWidth, required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
