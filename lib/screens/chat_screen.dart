import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ai_chat_agent/models/chat_history_response.dart';
import 'package:ai_chat_agent/models/chat_response.dart';
import 'package:ai_chat_agent/models/conversation_response.dart';
import 'package:ai_chat_agent/screens/login_screen.dart';
import 'package:ai_chat_agent/services/api_services.dart';
import 'package:ai_chat_agent/utils/utils.dart';
import 'package:ai_chat_agent/widgets/futuristic_textfiled.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSendingMessage = false;
  List<Conversation> _conversations = [];
  ChatHistoryResponse? _activeChatHistory;
  ChatResponse? _activeChatResponse;
  String? _activeConversationId;
  Timer? _chatRefreshTimer;
  String? _lastLoadedConversationId;
  bool _hasLoadedAtLeastOnce = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatRefreshTimer?.cancel(); // Don't forget to cancel
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await ApiServices.fetchConversations();
      setState(() {
        _conversations = conversations.conversations ?? [];
        if (_conversations.isEmpty) {
          // Start a new chat if no conversations exist
          _createNewChat();
        } else {
          _activeConversationId = _conversations.first.conversationId;
          _loadChatHistory(_activeConversationId!);
        }
      });
    } catch (e) {
      showError('Failed to load chat history', context);
    }
  }

  Future<void> _submitSatisfactionRating(int rating) async {
    final conversationId = _activeChatHistory?.conversationId;
    if (conversationId == null) return;

    try {
      final success = await ApiServices.updateConversationSatisfaction(
        conversationId: conversationId,
        satisfactionRate: rating,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Thanks for your feedback!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit rating. Please try again."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadChatHistory(String? conversationId) async {
    // Show loader only the first time
    if (!_hasLoadedAtLeastOnce) {
      setState(() => _isLoading = true);
    }

    try {
      final chatHistory = await ApiServices.fetchChatHistory(
        conversationId ?? '',
      );

      if (!mounted) return;

      setState(() {
        _activeChatHistory = chatHistory;
        _lastLoadedConversationId = conversationId;
        _hasLoadedAtLeastOnce = true;
      });
      _scrollToBottom();
      _startChatRefreshTimer(); // <-- Start periodic reload
    } catch (e) {
      if (!mounted) return;
      // Handle error
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _startChatRefreshTimer() {
    _chatRefreshTimer?.cancel(); // Cancel previous if any

    _chatRefreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      // Reload only if still on the same conversation
      if (_lastLoadedConversationId == _activeConversationId) {
        _loadChatHistory(_activeConversationId);
      } else {
        timer.cancel(); // Stop refreshing if user navigates away
      }
    });
  }

  Future<void> _createNewChat() async {
    // Check if a new chat with conversationId as null already exists
    final existingNewChatIndex = _conversations.indexWhere(
      (conversation) => conversation.conversationId == null,
    );

    if (existingNewChatIndex != -1) {
      // Do not create a new chat if one already exists
      setState(() {
        _activeConversationId = null;
        _activeChatHistory = ChatHistoryResponse(
          conversationId: null,
          chatHistory: [],
        );
      });
      return;
    }

    final newConversation = Conversation(
      conversationId: null,
      context: 'New Chat',
      lastMessage: null,
    );

    setState(() {
      _conversations.insert(0, newConversation);
      _activeConversationId = null;
      _activeChatHistory = ChatHistoryResponse(
        conversationId: null,
        chatHistory: [],
      );
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true; // Disable the send button
    });
    ;
    final userMessage = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      // Show user message immediately
      _activeChatHistory?.chatHistory?.add(userMessage);
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Send to backend
      ChatResponse response = await ApiServices.sendMessage(
        _activeChatHistory?.conversationId ?? '',
        text,
      );

      // Update conversation ID if received from response
      if (response.data?.conversationId != null) {
        final newConversationId = response.data!.conversationId.toString();

        setState(() {
          // Update conversation ID in activeChatHistory
          _activeChatHistory?.conversationId = newConversationId;
          _activeConversationId = newConversationId;

          // Also update it in the conversations list
          final index = _conversations.indexWhere(
            (c) => c.conversationId == null,
          );
          if (index != -1) {
            _conversations[index] = _conversations[index].copyWith(
              conversationId: newConversationId,
            );
          }
        });
      }

      final adminMessageContent = response.data?.message?.trim();
      if (adminMessageContent != null && adminMessageContent.isNotEmpty) {
        final adminMessage = ChatMessage(
          role: 'admin',
          content: adminMessageContent,
          timestamp: DateTime.now().toUtc(),
        );

        setState(() {
          _activeChatHistory?.chatHistory?.add(adminMessage);
        });

        _scrollToBottom();
      } else {
        print('Received empty or null admin message content');
      }
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() {
        _isSendingMessage = false; // Re-enable the send button
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomWithRetry();
    });
  }

  Future<void> _scrollToBottomWithRetry({int attempts = 0}) async {
    if (!_scrollController.hasClients || attempts > 5) return;

    final currentMax = _scrollController.position.maxScrollExtent;

    await _scrollController.animateTo(
      currentMax,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    // Wait a bit and check if we need to scroll more
    await Future.delayed(Duration(milliseconds: 100));

    if (_scrollController.hasClients) {
      final newMax = _scrollController.position.maxScrollExtent;
      if (newMax > currentMax) {
        // Content height changed, try again
        await _scrollToBottomWithRetry(attempts: attempts + 1);
      }
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final localTime = time.toLocal(); // Convert from UTC to local
    final hour = localTime.hour > 12 ? localTime.hour - 12 : localTime.hour;
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F3EF),
      body: Row(
        children: [
          /// ✅ Sidebar with Chat History
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color.fromARGB(255, 238, 104, 104),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.support_agent,
                                  color: Color(0xFFDB1F26),
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "💬 Chats",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: _createNewChat,
                      ),
                    ],
                  ),
                ),
                // Chat Sessions List
                // Chat Sessions List from API
                Expanded(
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final chat = _conversations[index];
                      final isSelected =
                          _activeConversationId == chat.conversationId;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.grey.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            chat.context?.isNotEmpty == true
                                ? chat.context!
                                : '',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize:
                                  chat.context?.isNotEmpty == true ? 14 : 16,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle:
                              chat.lastMessage?.content != null
                                  ? Text(
                                    chat.lastMessage!.content!,
                                    style: TextStyle(
                                      color:
                                          chat.context?.isNotEmpty == true
                                              ? Colors.black38
                                              : Colors.black,
                                      fontSize:
                                          chat.context?.isNotEmpty == true
                                              ? 12
                                              : 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                  : null,
                          onTap: () {
                            setState(() {
                              _isLoading = true; // Show loading indicator
                              _activeConversationId = chat.conversationId;
                            });

                            if (chat.conversationId != null) {
                              _hasLoadedAtLeastOnce = false;
                              _loadChatHistory(chat.conversationId!).then((_) {
                                // setState(() {
                                //   _isLoading = false; // Hide loading indicator
                                // });
                                _scrollToBottom();
                              });
                            } else {
                              setState(() {
                                _activeConversationId = null;
                                _activeChatHistory?.chatHistory = [];
                                _isLoading = false; // Hide loading indicator
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Logout Button
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black26)),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      await ApiServices.logout();
                      navigateWithoutAnimation(context, LoginPage());
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.black54,
                      size: 18,
                    ),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ✅ Main Chat Area
          Expanded(
            child: Column(
              children: [
                // Chat Header with Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDB1F26), Colors.black],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Logo/Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFFDB1F26),
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.support_agent,
                                color: Color(0xFFDB1F26),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Support', //change
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child:
                      !_hasLoadedAtLeastOnce && _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFDB1F26),
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                (_activeChatHistory?.chatHistory?.length ?? 0) +
                                (_isSendingMessage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isSendingMessage &&
                                  index ==
                                      (_activeChatHistory
                                              ?.chatHistory
                                              ?.length ??
                                          0)) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Bot Avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFFDB1F26),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.support_agent,
                                              color: Color(0xFFDB1F26),
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  JumpingDots(
                                                    color: Color(0xFFDB1F26),
                                                    size: 6,
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
                              final msg =
                                  _activeChatHistory!.chatHistory?[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (msg?.role != 'user') ...[
                                      // Bot Avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFFDB1F26),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.support_agent,
                                              color: Color(0xFFDB1F26),
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            msg?.role == 'user'
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  msg?.role == 'user'
                                                      ? Color(0xFFDB1F26)
                                                      : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color:
                                                      msg?.role == 'user'
                                                          ? Colors.white
                                                          : Colors.black87,
                                                  fontSize: 16,
                                                  height: 1.4,
                                                ),
                                                children: _parseTextWithLinks(
                                                  msg?.content ?? "",
                                                  msg?.role == 'user',
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (msg?.role == 'user') ...[
                                            SizedBox(height: 4),
                                            Text(
                                              _formatTime(msg?.timestamp),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),

                // Message Input Area
                _activeChatHistory?.chatEnded == true
                    ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Thank you for chatting with us!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Please rate your experience:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  Icons.star,
                                  color:
                                      (_activeChatHistory?.userRating ?? 0) >
                                              index
                                          ? Colors.orange
                                          : Colors.grey[300],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _activeChatHistory?.userRating = index + 1;
                                  });
                                  _submitSatisfactionRating(index + 1);
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: _controller,
                                onSubmitted: _sendMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Write a message",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFDB1F26), Colors.black],
                              ),
                            ),
                            child: IconButton(
                              onPressed:
                                  _isSendingMessage
                                      ? null
                                      : () => _sendMessage(_controller.text),
                              icon: Icon(
                                Icons.send,
                                color:
                                    _isSendingMessage
                                        ? Colors.grey
                                        : Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.all(12),
                            ),
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

  List<TextSpan> _parseTextWithLinks(String text, bool isUserMessage) {
    // Improved URL regex that won't match abbreviations like "e.g"
    final urlRegex = RegExp(
      r'(?:(?:https?|ftp):\/\/)(?:[\w-]+\.)+[a-z]{2,}(?:\/[\w\-\.?=%@&/+]*)*|' // Full URLs
      r'\bwww\.[\w-]+\.(?:[a-z]{2,})(?:\/[\w\-\.?=%@&/+]*)*\b', // www URLs
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: TextStyle(
              color: isUserMessage ? Colors.white : Colors.black87,
            ),
          ),
        );
      }

      // Add the URL
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer:
              TapGestureRecognizer()
                ..onTap =
                    () => _launchUrl(
                      url.startsWith(RegExp(r'https?:\/\/|ftp:\/\/'))
                          ? url
                          : 'https://$url',
                    ),
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text after last URL
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black87,
          ),
        ),
      );
    }

    return spans.isEmpty
        ? [
          TextSpan(
            text: text,
            style: TextStyle(
              color: isUserMessage ? Colors.white : Colors.black87,
            ),
          ),
        ]
        : spans;
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
      } else {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }
}
