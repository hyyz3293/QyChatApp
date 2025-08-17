class UserAccountModel {
  final int id;
  final int cid;
  final String accid;
  final String token;
  final String cpmpanyAccid; // 注意字段名拼写
  final int type;
  final String userid;
  //final int userno;
  final String appkey;
  final dynamic imConversation; // 类型不明确用 dynamic

  UserAccountModel({
    required this.id,
    required this.cid,
    required this.accid,
    required this.token,
    required this.cpmpanyAccid,
    required this.type,
    required this.userid,
    //required this.userno,
    required this.appkey,
    this.imConversation,
  });

  // 手动实现 toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cid': cid,
      'accid': accid,
      'token': token,
      'cpmpanyAccid': cpmpanyAccid,
      'type': type,
      'userid': userid,
      //'userno': userno,
      'appkey': appkey,
      'imConversation': imConversation,
    };
  }

  // 手动实现 fromJson()
  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      id: json['id'] as int,
      cid: json['cid'] as int,
      accid: json['accid'] as String,
      token: json['token'] as String,
      cpmpanyAccid: json['cpmpanyAccid'] as String,
      type: json['type'] as int,
      userid: json['userid'] as String,
      //userno: json['userno'] as int,
      appkey: json['appkey'] as String,
      imConversation: json['imConversation'],
    );
  }

}