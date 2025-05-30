class ConversationsResponse {
  final List<Conversation>? conversations;

  ConversationsResponse({this.conversations});

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      conversations:
          (json['data'] as List<dynamic>?)
              ?.map((e) => Conversation.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': conversations?.map((e) => e.toJson()).toList()};
  }
}

class Conversation {
  final String? conversationId;
  final String? context;
  final int? messageCount;
  final DateTime? lastUpdated;
  final Message? lastMessage;

  Conversation({
    this.conversationId,
    this.context,
    this.messageCount,
    this.lastUpdated,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversation_id'] as String?,
      context: json['context'] as String?,
      messageCount: json['message_count'] as int?,
      lastUpdated:
          json['last_updated'] != null
              ? DateTime.tryParse(json['last_updated'])
              : null,
      lastMessage:
          json['last_message'] != null
              ? Message.fromJson(json['last_message'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'context': context,
      'message_count': messageCount,
      'last_updated': lastUpdated?.toIso8601String(),
      'last_message': lastMessage?.toJson(),
    };
  }

  Conversation copyWith({
    String? conversationId,
    String? context,
    int? messageCount,
    DateTime? lastUpdated,
    Message? lastMessage,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      context: context ?? this.context,
      messageCount: messageCount ?? this.messageCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class Message {
  final String? role;
  final String? content;
  final DateTime? timestamp;

  Message({this.role, this.content, this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String?,
      content: json['content'] as String?,
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
