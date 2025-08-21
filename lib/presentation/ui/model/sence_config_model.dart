class SenceConfigModel {
  final int id;
  final int cid;
  final int sceneid;
  final String name;
  final int type;
  final int value;
  final DateTime createTime;
  final DateTime updateTime;

  SenceConfigModel({
    required this.id,
    required this.cid,
    required this.sceneid,
    required this.name,
    required this.type,
    required this.value,
    required this.createTime,
    required this.updateTime,
  });

  factory SenceConfigModel.fromJson(Map<String, dynamic> json) {
    return SenceConfigModel(
      id: json['id'] as int,
      cid: json['cid'] as int,
      sceneid: json['sceneid'] as int,
      name: json['name'] as String,
      type: json['type'] as int,
      value: json['value'] as int,
      createTime: DateTime.parse(json['createTime'].toString().replaceAll(' ', '')),
      updateTime: DateTime.parse(json['updateTime'].toString().replaceAll(' ', '')),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cid': cid,
    'sceneid': sceneid,
    'name': name,
    'type': type,
    'value': value,
    'createTime': createTime.toIso8601String(),
    'updateTime': updateTime.toIso8601String(),
  };
}