import 'dart:convert';

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

  MessJson({
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
  });

  factory MessJson.fromJson(Map<String, dynamic> json) {
    return MessJson(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}