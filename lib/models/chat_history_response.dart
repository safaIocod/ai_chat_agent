class ChatHistoryResponse {
  final String? conversationId;
  List<ChatMessage>? chatHistory;
  final bool? chatEnded;
  int? userRating;

  ChatHistoryResponse({
    this.conversationId,
    this.chatHistory,
    this.chatEnded,
    this.userRating,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ChatHistoryResponse(
      conversationId: json['conversation_id'] as String?,
      chatHistory:
          (json['chat_history'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e))
              .toList(),
      chatEnded: json['chat_ended'] as bool?,
      userRating: json['user_rating'] as int?,
    );
  }
}

class ChatMessage {
  final String? role;
  final String? content;
  final DateTime? timestamp;

  ChatMessage({this.role, this.content, this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String?,
      content: json['content'] as String?,
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'])
              : null,
    );
  }
}
