import 'dart:convert';

import 'package:boilerplate/presentation/ui/model/socket_im_message.dart';


class SocketRootMessage {
  final String eventName;
  final SocketIMMessage data;

  SocketRootMessage({
    required this.eventName,
    required this.data,
  });

  factory SocketRootMessage.fromJson(List<dynamic> jsonArray) {
    if (jsonArray.length != 2) {
      throw FormatException('Invalid event format, expected array with 2 elements');
    }

    return SocketRootMessage(
      eventName: jsonArray[0] as String,
      data: SocketIMMessage.fromJson(jsonArray[1] as Map<String, dynamic>),
    );
  }

  List<dynamic> toJson() {
    return [
      eventName,
      data.toJson(),
    ];
  }
}

