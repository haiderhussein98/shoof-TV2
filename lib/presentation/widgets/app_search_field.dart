import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintAr;
  final String hintEn;
  final EdgeInsets padding;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool showClearButton;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintAr = 'ابحث...',
    this.hintEn = 'Search...',
    this.padding = const EdgeInsets.all(12),
    this.focusNode,
    this.readOnly = false,
    this.showClearButton = false,
    this.onClear,
  });

  bool _isRTL(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
        Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRTL(context);
    final hint = isRtl ? hintAr : hintEn;

    return Padding(
      padding: padding,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;

            return PlatformWidget(
              material: (_, __) => TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1F25),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: showClearButton && hasText
                      ? IconButton(
                          splashRadius: 18,
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            controller.clear();
                            focusNode?.requestFocus();
                            onClear?.call();
                            onChanged?.call('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0x22FFFFFF),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0x44FFFFFF),
                      width: 1,
                    ),
                  ),
                ),
              ),
              cupertino: (_, __) => CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                placeholder: hint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                textInputAction: TextInputAction.search,
                cursorColor: CupertinoColors.systemGrey,
                style: const TextStyle(color: Colors.white),
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey2,
                ),
                prefix: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 8),
                  child: Icon(
                    CupertinoIcons.search,
                    color: CupertinoColors.systemGrey2,
                  ),
                ),
                suffix: showClearButton && hasText
                    ? GestureDetector(
                        onTap: () {
                          controller.clear();
                          focusNode?.requestFocus();
                          onClear?.call();
                          onChanged?.call('');
                        },
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(end: 8),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: CupertinoColors.systemGrey2,
                          ),
                        ),
                      )
                    : null,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x22FFFFFF), width: 1),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
