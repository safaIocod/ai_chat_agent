import 'package:ai_chat_agent/screens/login_screen.dart';
import 'package:ai_chat_agent/widgets/futuristic_textfiled.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class ChatSession {
  final String id;
  final String title;
  final List<_Message> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatSession> _chatSessions = [];
  ChatSession? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadDummySessions();
  }

  void _loadDummySessions() {
    // Simulated "API" response
    _chatSessions = [
      ChatSession(
        id: '1',
        title: 'Chat with AI',
        messages: [
          _Message(text: 'Hello!', isUser: true),
          _Message(text: 'Hi! How can I help you?', isUser: false),
        ],
      ),
      ChatSession(
        id: '2',
        title: 'Support Inquiry',
        messages: [
          _Message(text: 'I need help', isUser: true),
          _Message(text: 'Sure, I am here to assist.', isUser: false),
        ],
      ),
    ];

    setState(() {
      _activeSession = _chatSessions.first;
    });
  }

  void _createNewChat() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat ${_chatSessions.length + 1}',
      messages: [],
    );
    setState(() {
      _chatSessions.insert(0, newSession);
      _activeSession = newSession;
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _activeSession == null) return;

    setState(() {
      _activeSession!.messages.add(_Message(text: text, isUser: true));
    });

    _controller.clear();
    _scrollToBottom();
    _simulateApiResponse(text);
  }

  void _simulateApiResponse(String userMessage) async {
    await Future.delayed(Duration(seconds: 1));
    String botResponse = _getBotResponse(userMessage);
    setState(() {
      _activeSession!.messages.add(_Message(text: botResponse, isUser: false));
    });
    _scrollToBottom();
  }

  String _getBotResponse(String message) {
    if (message.toLowerCase().contains('hello'))
      return "👋 Hi there! How can I help you?";
    if (message.toLowerCase().contains('help'))
      return "🛠️ Sure, what do you need help with?";
    return "🤖 I'm a demo AI, but I'm here to chat!";
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("💬 AI Chat Agent"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              navigateWithoutAnimation(context, LoginPage());
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Row(
        children: [
          /// ✅ Sidebar (Like ChatGPT)
          Container(
            width: 250,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "💬 Chats",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _createNewChat,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatSessions.length,
                    itemBuilder: (context, index) {
                      final chat = _chatSessions[index];
                      return ListTile(
                        title: Text(
                          chat.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        selected: _activeSession?.id == chat.id,
                        selectedTileColor: Colors.white10,
                        onTap: () {
                          setState(() {
                            _activeSession = chat;
                          });
                          _scrollToBottom();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          /// ✅ Main Chat Area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _activeSession?.messages.length ?? 0,
                    itemBuilder: (context, index) {
                      final msg = _activeSession!.messages[index];
                      return Align(
                        alignment:
                            msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                msg.isUser ? Colors.white10 : Colors.grey[900],
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: _sendMessage,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(
                              255,
                              70,
                              69,
                              69,
                            ).withOpacity(0.3),
                            hintText: "Type something...",
                            hintStyle: const TextStyle(color: Colors.white60),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _sendMessage(_controller.text),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadowColor: Colors.cyanAccent,
                          elevation: 10,
                        ),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}
