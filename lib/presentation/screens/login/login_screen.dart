import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/presentation/screens/login/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return PlatformScaffold(
      backgroundColor: Colors.black,
      material: (_, __) => MaterialScaffoldData(resizeToAvoidBottomInset: true),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                physics: physics,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - bottomInset).clamp(
                      0,
                      constraints.maxHeight,
                    ),
                  ),
                  child: const Center(child: LoginForm()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

