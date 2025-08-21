import 'package:qychatapp/presentation/ui/model/attachment_bean.dart';

import 'image_bean.dart';

class ImUserSenseEvent {
  String? event;
  String? enumType;
  String? type;
  String? ip;
  String? webUrl;
  String? browserTitle;
  int? channelType;
  int? channelId;
  String? referrer;
  String? landing;
  String? channelName;
  String? browser;
  String? engine;
  String? terminal;
  String? msgId;
  String? msg;
  int? msgSendId;
  String? content;
  String? messId;
  List<ImageData>? imgs;
  List<AttachmentData>? attachment;
  String? url;
  String? sendAvatar;
  String? sendName;
  String? location;
  String? scene;
  String? cid;
  int? channel;


  ImUserSenseEvent({
    this.event,
    this.enumType,
    this.type,
    this.ip,
    this.webUrl,
    this.browserTitle,
    this.channelType,
    this.channelId,
    this.referrer,
    this.landing,
    this.channelName,
    this.browser,
    this.engine,
    this.terminal,
    this.msg,
    this.msgSendId,
    this.msgId,
    this.content,
    this.messId,
    this.imgs,
    this.attachment,
    this.url,
    this.sendAvatar,
    this.sendName,
    this.location,
    this.scene,
    this.cid,
    this.channel,
  });

  // 从 JSON 创建对象 - 无强制转换
  factory ImUserSenseEvent.fromJson(Map<dynamic, dynamic> json) {
    return ImUserSenseEvent(
      event: json['event'],
      enumType: json['enumType'],
      type: json['type'],
      ip: json['ip'],
      webUrl: json['webUrl'],
      browserTitle: json['browserTitle'],
      channelType: json['channelType'],
      channelId: json['channelId'],
      referrer: json['referrer'],
      landing: json['landing'],
      channelName: json['channelName'],
      browser: json['browser'],
      engine: json['engine'],
      terminal: json['terminal'],
      msg: json['msg'],
      msgSendId: json['msgSendId'],
      msgId: json['msgId'],

      sendAvatar: json['sendAvatar'],
      sendName: json['sendName'],

      content: json['content'],
      messId: json['messId'],
      imgs: json['imgs'] != null ? (json['imgs'] as List)
          .map((e) => ImageData.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      attachment: json['attachment'] != null ? (json['attachment'] as List)
          .map((e) => AttachmentData.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      url: json['url'],
      location: json['location'],

      scene: json['scene'],

      cid: "${json['cid']}",

      channel: json['channel'],
    );
  }

  // 将对象转为 JSON - 无默认值填充
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // 仅包含实际存在的值
    if (event != null) data['event'] = event;
    if (enumType != null) data['enumType'] = enumType;
    if (type != null) data['type'] = type;
    if (ip != null) data['ip'] = ip;
    if (webUrl != null) data['webUrl'] = webUrl;
    if (browserTitle != null) data['browserTitle'] = browserTitle;
    if (channelType != null) data['channelType'] = channelType;
    if (channelId != null) data['channelId'] = channelId;
    if (referrer != null) data['referrer'] = referrer;
    if (landing != null) data['landing'] = landing;
    if (channelName != null) data['channelName'] = channelName;
    if (browser != null) data['browser'] = browser;
    if (engine != null) data['engine'] = engine;
    if (terminal != null) data['terminal'] = terminal;
    if (msg != null) data['msg'] = msg;
    if (msgSendId != null) data['msgSendId'] = msgSendId;
    if (msgId != null) data['msgId'] = msgId;
    if (content != null) data['content'] = content;
    if (messId != null) data['messId'] = messId;
    if (imgs != null) data['imgs'].map((e) => e.toJson()).toList();
    if (attachment != null) data['attachment'].map((e) => e.toJson()).toList();
    if (url != null) data['url'] = url;

    if (sendAvatar != null) data['sendAvatar'] = sendAvatar;
    if (sendName != null) data['sendName'] = sendName;
    if (location != null) data['location'] = location;

    if (scene != null) data['scene'] = scene;

    if (cid != null) data['cid'] = cid;
    if (channel != null) data['channel'] = channel;

    return data;
  }
}