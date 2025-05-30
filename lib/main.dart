import 'package:ai_chat_agent/screens/chat_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(ChatWebApp());

class ChatWebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Agent',
      theme: ThemeData.dark(),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
