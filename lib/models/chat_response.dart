class ChatResponse {
  final bool status;
  final String message;
  final Data? data;

  ChatResponse({required this.status, required this.message, this.data});

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    status: json['status'] ?? false,
    message: json['message'] ?? '',
    data: json['data'] != null ? Data.fromJson(json['data']) : null,
  );

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class Data {
  final String? message;
  final SystemAction? systemAction;

  final bool? requiresHuman;
  final List<dynamic>? toolsUsed;
  final List<dynamic>? retrievedDocuments;
  final ChatAnalysis? chatAnalysis;
  final int? conversationId;

  Data({
    this.message,
    this.systemAction,
    this.requiresHuman,
    this.toolsUsed,
    this.retrievedDocuments,
    this.chatAnalysis,
    this.conversationId,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    message: json['message'] as String?,
    systemAction:
        json['system_action'] != null
            ? SystemAction.fromJson(json['system_action'])
            : null,

    requiresHuman: json['requires_human'] as bool?,
    toolsUsed:
        json['tools_used'] != null
            ? List<dynamic>.from(json['tools_used'])
            : null,
    retrievedDocuments:
        json['retrieved_documents'] != null
            ? List<dynamic>.from(json['retrieved_documents'])
            : null,
    chatAnalysis:
        json['chat_analysis'] != null
            ? ChatAnalysis.fromJson(json['chat_analysis'])
            : null,
    conversationId:
        json['conversation_id'] is int
            ? json['conversation_id'] as int
            : int.tryParse(json['conversation_id'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'message': message,
    'system_action': systemAction,
    'requires_human': requiresHuman,
    'tools_used': toolsUsed,
    'retrieved_documents': retrievedDocuments,
    'chat_analysis': chatAnalysis?.toJson(),
    'conversation_id': conversationId,
  };
}

class SystemAction {
  final String? actionType;
  final String? email;
  final String? name;
  final String? preferredTime;

  SystemAction({this.actionType, this.email, this.name, this.preferredTime});

  factory SystemAction.fromJson(Map<String, dynamic> json) => SystemAction(
    actionType: json['action_type'] as String?,
    email: json['email'] as String?,
    name: json['name'] as String?,
    preferredTime: json['preferred_time'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'action_type': actionType,
    'email': email,
    'name': name,
    'preferred_time': preferredTime,
  };
}

class ChatAnalysis {
  final String? summary;
  final String? emotion;
  final String? urgency;
  final double? sentimentScore;
  final List<String>? keyTopics;

  ChatAnalysis({
    this.summary,
    this.emotion,
    this.urgency,
    this.sentimentScore,
    this.keyTopics,
  });

  factory ChatAnalysis.fromJson(Map<String, dynamic> json) => ChatAnalysis(
    summary: json['summary'] as String?,
    emotion: json['emotion'] as String?,
    urgency: json['urgency'] as String?,
    sentimentScore:
        json['sentiment_score'] != null
            ? (json['sentiment_score'] as num).toDouble()
            : null,
    keyTopics:
        json['key_topics'] != null
            ? List<String>.from(json['key_topics'])
            : null,
  );

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'emotion': emotion,
    'urgency': urgency,
    'sentiment_score': sentimentScore,
    'key_topics': keyTopics,
  };
}
