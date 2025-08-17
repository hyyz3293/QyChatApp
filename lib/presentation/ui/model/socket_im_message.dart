import 'dart:convert';

class SocketIMMessage {
  final List<String> toAccid;
  final String event;
  final String msgContent;

  SocketIMMessage({
    required this.toAccid,
    required this.event,
    required this.msgContent,
  });

  factory SocketIMMessage.fromJson(Map<String, dynamic> json) {
    return SocketIMMessage(
      toAccid: List<String>.from(json['toAccid'] as List),
      event: json['event'] as String? ?? '',
      msgContent: json['msgContent'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toAccid': toAccid,
      'event': event,
      'msgContent': msgContent,
    };
  }
}

