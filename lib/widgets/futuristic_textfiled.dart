import 'package:flutter/material.dart';

final buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.cyanAccent,
  foregroundColor: Colors.black,
  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
);

class FuturisticScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FuturisticScaffold({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FuturisticTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const FuturisticTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color.fromARGB(66, 77, 76, 76),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
    );
  }
}

void navigateWithoutAnimation(BuildContext context, Widget page) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation1, animation2) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}
