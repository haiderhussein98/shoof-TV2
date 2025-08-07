import 'package:flutter/material.dart';

class MovieTopControls extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRotate;

  const MovieTopControls({
    super.key,
    required this.onBack,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.screen_rotation, color: Colors.white),
                  onPressed: onRotate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
