class ChannelAccountModel {
  final int id;
  final int type;
  final String name;

  ChannelAccountModel({
    required this.id,
    required this.type,
    required this.name,
  });

  // 手动实现 toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
    };
  }

  // 手动实现 fromJson()
  factory ChannelAccountModel.fromJson(Map<String, dynamic> json) {
    return ChannelAccountModel(
      id: json['id'] as int,
      type: json['type'] as int,
      name: json['name'] as String,
    );
  }

}