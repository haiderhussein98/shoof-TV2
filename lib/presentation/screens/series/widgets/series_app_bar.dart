import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/presentation/widgets/app_search_field.dart';

class SeriesAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final VoidCallback onClear;
  final ValueChanged<String> onSearch;

  const SeriesAppBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.onClear,
    required this.onSearch,
  });

  @override
  State<SeriesAppBar> createState() => _SeriesAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

class _SeriesAppBarState extends State<SeriesAppBar> {
  late FocusNode _searchFocus;
  late FocusNode _wrapperFocus;
  bool _searchEnabled = false;
  bool _wrapperHasFocus = false;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode();
    _wrapperFocus = FocusNode(debugLabel: 'search_wrapper');
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _wrapperFocus.dispose();
    super.dispose();
  }

  bool _isRTL(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
        Directionality.of(context) == TextDirection.rtl;
  }

  bool _isAndroidTvLike(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final nav = MediaQuery.of(context).navigationMode;
    return isAndroid && nav == NavigationMode.directional;
  }

  Widget _searchBox(BuildContext context) {
    final isRtl = _isRTL(context);
    final isTv = _isAndroidTvLike(context);

    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Focus(
            focusNode: _wrapperFocus,
            onFocusChange: (f) => setState(() => _wrapperHasFocus = f),
            onKeyEvent: (node, event) {
              if (!isTv) return KeyEventResult.ignored;
              if (event is KeyDownEvent) {
                final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                    event.logicalKey == LogicalKeyboardKey.space;
                if (isEnter && !_searchEnabled) {
                  setState(() => _searchEnabled = true);
                  _searchFocus.requestFocus();
                  return KeyEventResult.handled;
                }
                if ((event.logicalKey == LogicalKeyboardKey.escape ||
                        event.logicalKey == LogicalKeyboardKey.goBack) &&
                    _searchEnabled) {
                  setState(() => _searchEnabled = false);
                  _wrapperFocus.requestFocus();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isTv && !_searchEnabled && _wrapperHasFocus
                    ? Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        width: 2,
                      )
                    : null,
              ),
              child: ExcludeFocus(
                excluding: isTv ? !_searchEnabled : false,
                child: AppSearchField(
                  controller: widget.searchController,
                  hintAr: 'ابحث عن مسلسل...',
                  hintEn: 'Search series...',
                  padding: EdgeInsets.zero,
                  onChanged: widget.onSearch,
                  onSubmitted: widget.onSearch,
                  focusNode: _searchFocus,
                  readOnly: isTv ? !_searchEnabled : false,
                ),
              ),
            ),
          ),
          if (widget.isSearching)
            Positioned(
              right: isRtl ? null : 6,
              left: isRtl ? 6 : null,
              child: PlatformIconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: widget.onClear,
                material: (_, __) => MaterialIconButtonData(
                  splashRadius: 20,
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                cupertino: (_, __) => CupertinoIconButtonData(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, __) => AppBar(
        backgroundColor: Colors.black,
        title: const Text("Series", style: TextStyle(fontSize: 15)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15.0),
            child: Image(image: AssetImage('assets/images/logo.png')),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: _searchBox(context),
          ),
        ),
      ),
      cupertino: (_, __) => Container(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformAppBar(
              title: const Text("Series", style: TextStyle(fontSize: 15)),
              cupertino: (_, __) =>
                  CupertinoNavigationBarData(backgroundColor: Colors.black),
              material: (_, __) =>
                  MaterialAppBarData(backgroundColor: Colors.black),
              trailingActions: const [
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Image(image: AssetImage('assets/images/logo.png')),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: _searchBox(context),
            ),
          ],
        ),
      ),
    );
  }
}
