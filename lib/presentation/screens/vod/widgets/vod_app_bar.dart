import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class VodAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const VodAppBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
  });

  bool _isRTL(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
        Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRTL(context);

    return AppBar(
      backgroundColor: Colors.black,
      title: const Text("Movies", style: TextStyle(fontSize: 15)),
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
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: _VodSearchField(
              controller: controller,
              isSearching: isSearching,
              isRtl: isRtl,
              onSearch: onSearch,
              onClear: onClear,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

class _VodSearchField extends StatefulWidget {
  final TextEditingController controller;
  final bool isSearching;
  final bool isRtl;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const _VodSearchField({
    required this.controller,
    required this.isSearching,
    required this.isRtl,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_VodSearchField> createState() => _VodSearchFieldState();
}

class _VodSearchFieldState extends State<_VodSearchField> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'vod_search_field');
  bool _editing = false;

  bool _isAndroidTv(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return isAndroid &&
        MediaQuery.of(context).navigationMode == NavigationMode.directional;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (_editing) return;
    setState(() => _editing = true);
    _focusNode.requestFocus();
    Future.microtask(() {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _stopEditing() {
    if (!_editing) return;
    setState(() => _editing = false);
    _focusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    // منطق الريموت يعمل فقط على Android TV
    final isTv = _isAndroidTv(context);
    if (!isTv) return KeyEventResult.ignored;

    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _startEditing();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (_editing) {
        _stopEditing();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (!_editing) {
      final scope = FocusScope.of(context);
      if (key == LogicalKeyboardKey.arrowDown) {
        scope.focusInDirection(TraversalDirection.down);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        scope.focusInDirection(TraversalDirection.up);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        scope.focusInDirection(TraversalDirection.left);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        scope.focusInDirection(TraversalDirection.right);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isTv = _isAndroidTv(context);

    return Focus(
      onKeyEvent: _handleKey,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        // على Android TV فقط يكون readOnly إلى أن يضغط المستخدم Enter/OK
        readOnly: isTv ? !_editing : false,
        showCursor: isTv ? _editing : true,
        enableInteractiveSelection: isTv ? _editing : true,
        onTap: _startEditing,
        onSubmitted: (value) {
          widget.onSearch(value);
          _stopEditing();
        },
        onEditingComplete: _stopEditing,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white70,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.isRtl ? 'ابحث عن فيلم...' : 'Search movies...',
          hintStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: const Color(0xFF1E1F25),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: widget.isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    widget.onClear();
                    if (isTv && _editing) {
                      _focusNode.requestFocus();
                    }
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x44FFFFFF), width: 1),
          ),
        ),
      ),
    );
  }
}
