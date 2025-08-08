import 'package:flutter/material.dart';
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
