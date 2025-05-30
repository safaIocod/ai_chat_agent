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
  final String? systemAction;
  final bool? requiresHuman;
  final List<dynamic>? toolsUsed;
  final List<dynamic>? retrievedDocuments;
  final ChatAnalysis? chatAnalysis;

  Data({
    this.message,
    this.systemAction,
    this.requiresHuman,
    this.toolsUsed,
    this.retrievedDocuments,
    this.chatAnalysis,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    message: json['message'] as String?,
    systemAction: json['system_action'] as String?,
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
  );

  Map<String, dynamic> toJson() => {
    'message': message,
    'system_action': systemAction,
    'requires_human': requiresHuman,
    'tools_used': toolsUsed,
    'retrieved_documents': retrievedDocuments,
    'chat_analysis': chatAnalysis?.toJson(),
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
