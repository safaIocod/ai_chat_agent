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

class JumpingDots extends StatefulWidget {
  final int numberOfDots;
  final Color color;
  final double size;
  final Duration animationDuration;

  const JumpingDots({
    Key? key,
    this.numberOfDots = 3,
    this.color = Colors.black,
    this.size = 8.0,
    this.animationDuration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  _JumpingDotsState createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.numberOfDots,
      (index) =>
          AnimationController(vsync: this, duration: widget.animationDuration)
            ..repeat(reverse: true),
    );

    _animations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.numberOfDots, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animations[index].value * 5),
              child: Container(
                width: widget.size,
                height: widget.size,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
