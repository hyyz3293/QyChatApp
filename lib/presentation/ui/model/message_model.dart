class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.metadata,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}