import 'package:ai_chat_agent/screens/chat_screen.dart';
import 'package:ai_chat_agent/screens/sign_up_screen.dart';
import 'package:ai_chat_agent/widgets/futuristic_textfiled.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: "Login",
      children: [
        FuturisticTextField(controller: emailCtrl, hint: "Email"),
        const SizedBox(height: 16),
        FuturisticTextField(
          controller: passCtrl,
          hint: "Password",
          obscure: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            navigateWithoutAnimation(context, ChatScreen());
          },
          child: const Text(
            "Login",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
              fontFamily: 'RobotoMono', // or any futuristic font you add
              shadows: [
                Shadow(
                  color: Colors.white,
                  blurRadius: 6,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          style: buttonStyle,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => navigateWithoutAnimation(context, SignUpPage()),
          child: const Text(
            "Don't have an account? Sign Up",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 16,
              fontFamily: 'RobotoMono',
              shadows: [
                Shadow(
                  color: Colors.cyanAccent,
                  blurRadius: 6,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
