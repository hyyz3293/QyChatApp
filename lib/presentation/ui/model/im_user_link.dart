import 'dart:convert';

// 主数据模型
class ChatLinkItem {
  final String href;
  final String text;

  ChatLinkItem({
    required this.href,
    required this.text,
    //required this.response,
  });

  // 从JSON反序列化
  factory ChatLinkItem.fromJson(Map<String, dynamic> json) {
    return ChatLinkItem(
      href: json['href'],
      text: json['text'],
      //response: json['response'] != "" ? ChatMenuItemResponse.fromJson(json['response']) : null,
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'text': text,
      //'response': response!.toJson(),
    };
  }
}
