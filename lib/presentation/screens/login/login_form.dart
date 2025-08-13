import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/domain/usecases/login_user.dart';
import 'package:shoof_tv/presentation/screens/home/home_screen.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final serverController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    serverController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    setState(() {
      loading = true;
      error = null;
    });

    final ok = await loginUser(
      ref: ref,
      rawServer: serverController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!context.mounted) return;

    setState(() => loading = false);

    if (ok) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => error = "تعذر تسجيل الدخول. تحقق من المعلومات.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final maxFormWidth = isWide ? 420.0 : 360.0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxFormWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Image.asset('assets/images/logo.png', width: isWide ? 120 : 96),
          const SizedBox(height: 10),
          Text(
            "SHOOF.TV",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),

          _buildTextField(
            controller: serverController,
            hint: "Server",
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _usernameFocus.requestFocus(),
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: usernameController,
            hint: "Username",
            focusNode: _usernameFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: passwordController,
            hint: "Password",
            obscureText: true,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(context),
          ),
          const SizedBox(height: 18),

          loading
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("ADD PLAYLIST"),
                  ),
                ),
          const SizedBox(height: 10),

          if (error != null)
            Text(
              error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  bool obscureText = false,
  FocusNode? focusNode,
  TextInputAction? textInputAction,
  Function(String)? onSubmitted,
}) {
  return _TvTextField(
    controller: controller,
    hint: hint,
    obscureText: obscureText,
    focusNode: focusNode,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
  );
}

class _TvTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;

  const _TvTextField({
    required this.controller,
    required this.hint,
    required this.obscureText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_TvTextField> createState() => _TvTextFieldState();
}

class _TvTextFieldState extends State<_TvTextField> {
  final FocusNode _wrapperNode = FocusNode(debugLabel: 'login_field_wrapper');
  late final FocusNode _textNode = widget.focusNode ?? FocusNode();

  bool _editing = false;

  // TV-only: Android + نمط تنقّل Directional
  bool _isAndroidTvLike(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final nav = MediaQuery.of(context).navigationMode;
    return isAndroid && nav == NavigationMode.directional;
  }

  @override
  void dispose() {
    _wrapperNode.dispose();
    if (widget.focusNode == null) {
      _textNode.dispose();
    }
    super.dispose();
  }

  void _startEditing() {
    if (_editing) return;
    setState(() => _editing = true);
    _textNode.requestFocus();
    Future.microtask(() {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _stopEditing() {
    if (!_editing) return;
    setState(() => _editing = false);
    _textNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
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
      _stopEditing();
      return KeyEventResult.handled;
    }

    // التنقّل بالأسهم عندما لا نكون في وضع الكتابة
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
    final isTv = _isAndroidTvLike(context);

    // على الهاتف/الدسكتوب: حقل عادي بدون منطق الريموت
    if (!isTv) {
      return TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white12,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }

    // على Android TV: منطق الريموت والتركيز والـ Enter لبدء الكتابة
    return Focus(
      focusNode: _wrapperNode,
      onKeyEvent: _handleKey,
      canRequestFocus: true,
      child: TextField(
        controller: widget.controller,
        focusNode: _textNode,
        obscureText: widget.obscureText,
        readOnly: !_editing,
        textInputAction: widget.textInputAction,
        onTap: _startEditing,
        onSubmitted: (v) {
          widget.onSubmitted?.call(v);
          _stopEditing();
        },
        onEditingComplete: _stopEditing,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white12,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _wrapperNode.hasFocus
                  ? Colors.redAccent
                  : Colors.transparent,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
