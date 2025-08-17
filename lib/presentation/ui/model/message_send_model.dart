import 'image_bean.dart';

class ServiceMessageBean {
  final String type;
  final String from;
  final String to;
  final String channelType;
  final int time; // 毫秒时间戳
  final String messId; // 消息唯一ID
  final String flow;
  final String scene;
  final String msgSendId;
  final int msgSendType; // 0:系统;1:坐席;2:客户
  final String enumType;
  final String content;
  List<ImageData>? imgs;
  String? code;
  String? url;
  int? duration;

  ServiceMessageBean({
    required this.type,
    required this.from,
    required this.to,
    required this.channelType,
    required this.time,
    required this.messId,
    required this.flow,
    required this.scene,
    required this.msgSendId,
    required this.msgSendType,
    required this.enumType,
    required this.content,
    this.imgs,
    this.code,
    this.url,
    this.duration,
  });

  // 安全类型转换方法
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value is String) return value;
    return value?.toString() ?? '';
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    final json = {
      'type': type,
      'from': from,
      'to': to,
      'channelType': channelType,
      'time': time,
      'duration': duration,
      'messId': messId,
      'flow': flow,
      'scene': scene,
      'msgSendId': msgSendId,
      'msgSendType': msgSendType,
      'enumType': enumType,
      'content': content,
      'imgs': imgs?.map((img) => img.toJson()).toList(),
      'code': code??"",
      'url': url??""
    };
    return json;
  }

  // 从JSON创建
  factory ServiceMessageBean.fromJson(Map<String, dynamic> json) {
    // 处理imgs字段
    List<ImageData>? parsedImgs;
    if (json['imgs'] != null && json['imgs'] is List) {
      parsedImgs = (json['imgs'] as List)
          .map((item) => ImageData.fromJson(item))
          .toList();
    }
    return ServiceMessageBean(
      type: _parseString(json['type']),
      from: _parseString(json['from']),
      to: _parseString(json['to']),
      channelType: _parseString(json['channelType']),
      time: _parseInt(json['time']),
      duration: _parseInt(json['duration']),
      messId: _parseString(json['messId']),
      flow: _parseString(json['flow']),
      scene: _parseString(json['scene']),
      msgSendId: _parseString(json['msgSendId']),
      msgSendType: _parseInt(json['msgSendType']),
      enumType: _parseString(json['enumType']),
      content: _parseString(json['content']),
      imgs: parsedImgs,
      code: _parseString(json['code']),
      url:_parseString(json['url']),
    );
  }
}