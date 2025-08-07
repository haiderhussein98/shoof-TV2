import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/usecases/login_user.dart';
import 'package:shoof_iptv/presentation/screens/home/home_screen.dart';

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

    final success = await loginUser(
      ref: ref,
      rawServer: serverController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (success && context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        error = "تعذر تسجيل الدخول. تحقق من المعلومات.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset('assets/images/logo.png', width: 120),
        const SizedBox(height: 16),
        Text(
          "SHOOF.TV",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 32),
        _buildTextField(
          controller: serverController,
          hint: "Server",
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _usernameFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: usernameController,
          hint: "Username",
          focusNode: _usernameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: passwordController,
          hint: "Password",
          obscureText: true,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(context),
        ),
        const SizedBox(height: 24),
        loading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submit(context),
                  child: const Text("ADD PLAYLIST"),
                ),
              ),
        const SizedBox(height: 12),
        if (error != null)
          Text(
            error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
