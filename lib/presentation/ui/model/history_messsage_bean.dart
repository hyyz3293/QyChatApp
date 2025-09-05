import 'dart:convert';

import 'package:qychatapp/presentation/ui/model/welcomeSpeech_bean.dart';

import 'attachment_bean.dart';
import 'complex_bean.dart';
import 'im_user_link.dart';
import 'im_user_menu.dart';
import 'image_bean.dart';

class MessagePageResponse {
  String? msg;
  int? code;
  dynamic data;
  Page? page;

  MessagePageResponse({
    this.msg,
    this.code,
    this.data,
    this.page,
  });

  factory MessagePageResponse.fromJson(Map<String, dynamic> json) {
    return MessagePageResponse(
      msg: json['msg'],
      code: json['code'],
      data: json['data'],
      page: json['page'] != null ? Page.fromJson(json['page']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
      'code': code,
      'data': data,
      'page': page?.toJson(),
    };
  }
}

class Page {
  int? total;
  int? size;
  int? current;
  List<MessageRecord>? records;

  Page({
    this.total,
    this.size,
    this.current,
    this.records,
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    var recordsList = json['records'] as List?;
    List<MessageRecord>? records = recordsList
        ?.map((record) => MessageRecord.fromJson(record))
        .toList();

    return Page(
      total: json['total'],
      size: json['size'],
      current: json['current'],
      records: records,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'size': size,
      'current': current,
      'records': records?.map((record) => record.toJson()).toList(),
    };
  }
}

class MessageRecord {
  int? id;
  int? cid;
  String? connectionid;
  int? serviceid;
  int? flag;
  int? userid;
  String? messType;
  String? messEnumType;
  MessJson? messJson;
  int? time;
  String? messId;
  String? createTime;
  String? updateTime;
  dynamic empid;
  dynamic agentname;
  dynamic codeName;
  dynamic ip;
  dynamic ipAddress;
  dynamic referrer;
  dynamic location;
  dynamic sceneName;
  dynamic acctype;
  dynamic userno;
  dynamic robotid;
  dynamic agentid;
  dynamic agentImg;
  int? msgSendId;
  int? msgSendType;
  String? sendAvatar;
  String? sendName;

  MessageRecord({
    this.id,
    this.cid,
    this.connectionid,
    this.serviceid,
    this.flag,
    this.userid,
    this.messType,
    this.messEnumType,
    this.messJson,
    this.time,
    this.messId,
    this.createTime,
    this.updateTime,
    this.empid,
    this.agentname,
    this.codeName,
    this.ip,
    this.ipAddress,
    this.referrer,
    this.location,
    this.sceneName,
    this.acctype,
    this.userno,
    this.robotid,
    this.agentid,
    this.agentImg,
    this.msgSendId,
    this.msgSendType,
    this.sendAvatar,
    this.sendName,
  });

  factory MessageRecord.fromJson(Map<String, dynamic> json) {
    // 处理 messJson 字段 - 它可能是字符串或 Map
    dynamic messJsonValue = json['messJson'];
    MessJson? parsedMessJson;

    if (messJsonValue != null) {
      if (messJsonValue is String) {
        // 如果是字符串，尝试解析为 JSON
        try {
          parsedMessJson = MessJson.fromJson(jsonDecode(messJsonValue));
        } catch (e) {
          print('Failed to parse messJson string: $e');
          parsedMessJson = null;
        }
      } else if (messJsonValue is Map<String, dynamic>) {
        // 如果是 Map，直接使用
        parsedMessJson = MessJson.fromJson(messJsonValue);
      }
    }

    return MessageRecord(
      id: json['id'],
      cid: json['cid'],
      connectionid: json['connectionid'],
      serviceid: json['serviceid'],
      flag: json['flag'],
      userid: json['userid'],
      messType: json['messType'],
      messEnumType: json['messEnumType'],
      messJson: parsedMessJson,
      time: json['time'],
      messId: json['messId'],
      createTime: json['createTime'],
      updateTime: json['updateTime'],
      empid: json['empid'],
      agentname: json['agentname'],
      codeName: json['codeName'],
      ip: json['ip'],
      ipAddress: json['ipAddress'],
      referrer: json['referrer'],
      location: json['location'],
      sceneName: json['sceneName'],
      acctype: json['acctype'],
      userno: json['userno'],
      robotid: json['robotid'],
      agentid: json['agentid'],
      agentImg: json['agentImg'],
      msgSendId: json['msgSendId'],
      msgSendType: json['msgSendType'],
      sendAvatar: json['sendAvatar'],
      sendName: json['sendName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cid': cid,
      'connectionid': connectionid,
      'serviceid': serviceid,
      'flag': flag,
      'userid': userid,
      'messType': messType,
      'messEnumType': messEnumType,
      'messJson': messJson?.toJson(),
      'time': time,
      'messId': messId,
      'createTime': createTime,
      'updateTime': updateTime,
      'empid': empid,
      'agentname': agentname,
      'codeName': codeName,
      'ip': ip,
      'ipAddress': ipAddress,
      'referrer': referrer,
      'location': location,
      'sceneName': sceneName,
      'acctype': acctype,
      'userno': userno,
      'robotid': robotid,
      'agentid': agentid,
      'agentImg': agentImg,
      'msgSendId': msgSendId,
      'msgSendType': msgSendType,
      'sendAvatar': sendAvatar,
      'sendName': sendName,
    };
  }
}

class MessJson {
  String? content;
  String? conversationCode;
  String? enumType;
  String? from;
  int? fromType;
  String? messId;
  int? msgSendId;
  int? msgSendType;
  String? sendAvatar;
  String? sendName;
  int? time;
  String? to;
  String? type;

  String? link;

  String? event;
  //String? enumType;
  //String? type;
  String? ip;
  String? webUrl;
  String? browserTitle;
  int? channelType;
  int? channelId;
  String? referrer;
  String? key;
  String? landing;
  String? channelName;
  String? browser;
  String? engine;
  String? terminal;
  String? msgId;
  String? msg;
  //int? msgSendId;
  //int? msgSendType;
  int? source;
  int? target;
  String? id;
  String? value;
  //String? content;
  //String? messId;
  List<ImageData>? imgs;
  List<AttachmentData>? attachment;
  String? url;
  //String? sendAvatar;
  //String? sendName;
  String? location;
  String? scene;
  //String? conversationCode;
  int? cid;
  int? channel;
  WelcomeSpeechData? welcomeSpeech;
  List<ChatMenuItem>? navigationList;
  List<ChatLinkItem>? links;
  ComplexData? complex;
  String? title;
  String? digest;

  int? serviceId;

  MessJson({
    this.link,
    this.content,
    this.conversationCode,
    this.enumType,
    this.from,
    this.fromType,
    this.messId,
    this.msgSendId,
    this.msgSendType,
    this.sendAvatar,
    this.sendName,
    this.time,
    this.to,
    this.type,
    this.key,
    this.serviceId,
    this.title,
    this.event,
    //this.enumType,
    //this.type,
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
    //this.msgSendId,
    //this.msgSendType,
    this.msgId,
    //this.content,
    this.digest,
    //this.messId,
    this.imgs,
    this.attachment,
    this.url,
    //t/his.sendAvatar,
    //this.sendName,
    this.location,
    this.scene,
    this.cid,
    this.channel,
    this.welcomeSpeech,
    this.navigationList,
    this.links,
    this.id,
    this.source,
    this.value,
    this.target,
    //this.conversationCode,
    this.complex,
  });

  factory MessJson.fromJson(Map<String, dynamic> json) {
    return MessJson(
      link: json['link'],
      content: json['content'],
      conversationCode: json['conversationCode'],
      enumType: json['enumType'],
      from: json['from'],
      fromType: json['fromType'],
      messId: json['messId'],
      msgSendId: json['msgSendId'],
      msgSendType: json['msgSendType'],
      sendAvatar: json['sendAvatar'],
      sendName: json['sendName'],
      time: json['time'],
      to: json['to'],
      type: json['type'],

      digest: json['digest'],

      key: json['key'],
      serviceId: json['serviceId'],
      event: json['event'],
      title: json['title'],
      //enumType: json['enumType'],
      //type: json['type'],
      ip: json['ip'],
      webUrl: json['webUrl'],
      browserTitle: json['browserTitle'],
      ///conversationCode: json['conversationCode'],
      channelType: json['channelType'],
      channelId: json['channelId'],
      referrer: json['referrer'],
      landing: json['landing'],
      channelName: json['channelName'],
      browser: json['browser'],
      engine: json['engine'],
      terminal: json['terminal'],
      msg: json['msg'],
      //msgSendId: json['msgSendId'],
      //msgSendType: json['msgSendType'],
      msgId: json['msgId'],
      source: json['source'],
      id: json['id'],
      value: json['value'],
      target: json['target'],
      //sendAvatar: json['sendAvatar'],
      //sendName: json['sendName'],
      //content: json['content'],
      //messId: json['messId'],
      imgs: json['imgs'] != null ? (json['imgs'] as List)
          .map((e) => ImageData.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      navigationList: json['navigationList'] != null ? (json['navigationList'] as List)
          .map((e) => ChatMenuItem.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      links: json['links'] != null ? (json['links'] as List)
          .map((e) => ChatLinkItem.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      attachment: json['attachment'] != null ? (json['attachment'] as List)
          .map((e) => AttachmentData.fromJson(e as Map<String, dynamic>))
          .toList() : [],
      url: json['url'],
      location: json['location'],
      scene: json['scene'],
      cid: int.tryParse("${json['cid']}"),
      channel: json['channel'],
      welcomeSpeech: json['welcomeSpeech'] != null ?
      WelcomeSpeechData.fromJson(json['welcomeSpeech']) : null,
      complex: json['complex'] != null ? ComplexData.fromJson(json['complex']) : null,
    );
  }

  // 补全后的 toJson() 方法
  Map<String, dynamic> toJson() {
    return {
      // ---------------------- 基础消息字段 ----------------------
      'content': content,
      'conversationCode': conversationCode,
      'enumType': enumType,
      'from': from,
      'fromType': fromType,
      'messId': messId,
      'msgSendId': msgSendId,
      'msgSendType': msgSendType,
      'sendAvatar': sendAvatar,
      'sendName': sendName,
      'time': time,
      'to': to,
      'type': type,
      'digest': digest,
      'key': key,
      'serviceId': serviceId,
      'event': event,
      'title': title,
      'link': link,
      // ---------------------- 场景/设备相关字段 ----------------------
      'ip': ip,
      'webUrl': webUrl,
      'browserTitle': browserTitle,
      'channelType': channelType,
      'channelId': channelId,
      'referrer': referrer,
      'landing': landing,
      'channelName': channelName,
      'browser': browser,
      'engine': engine,
      'terminal': terminal,

      // ---------------------- 消息内容扩展字段 ----------------------
      'msg': msg,
      'msgId': msgId,
      'source': source,
      'id': id,
      'value': value,
      'target': target,
      'url': url,
      'location': location,
      'scene': scene,
      'cid': cid,
      'channel': channel,

      // ---------------------- 复杂集合字段（需手动序列化） ----------------------
      // 图片列表：判断非空后，将每个 ImageData 转为 Map
      'imgs': imgs?.map((img) => img.toJson()).toList(),
      // 附件列表：判断非空后，将每个 AttachmentData 转为 Map
      'attachment': attachment?.map((attach) => attach.toJson()).toList(),
      // 导航菜单列表：判断非空后，将每个 ChatMenuItem 转为 Map
      'navigationList': navigationList?.map((menu) => menu.toJson()).toList(),
      // 链接列表：判断非空后，将每个 ChatLinkItem 转为 Map
      'links': links?.map((link) => link.toJson()).toList(),
      // 复杂数据：直接调用 ComplexData 的 toJson()（需确保 ComplexData 已实现该方法）
      'complex': complex?.toJson(),
      // 欢迎语数据：直接调用 WelcomeSpeechData 的 toJson()（需确保该类已实现）
      'welcomeSpeech': welcomeSpeech?.toJson(),
    };
  }
}