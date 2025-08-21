import 'dart:convert';

// 主数据模型
class ChatMenuItem {
  final String menuNumber;
  final String menuTitle;
  final int menuId;
  final String menuType;
  //ChatMenuItemResponse? response;

  ChatMenuItem({
    required this.menuNumber,
    required this.menuTitle,
    required this.menuId,
    required this.menuType,
    //required this.response,
  });

  // 从JSON反序列化
  factory ChatMenuItem.fromJson(Map<String, dynamic> json) {
    return ChatMenuItem(
      menuNumber: json['menuNumber'],
      menuTitle: json['menuTitle'],
      menuId: json['menuId'],
      menuType: json['menuType'],
      //response: json['response'] != "" ? ChatMenuItemResponse.fromJson(json['response']) : null,
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'menuNumber': menuNumber,
      'menuTitle': menuTitle,
      'menuId': menuId,
      'menuType': menuType,
      //'response': response!.toJson(),
    };
  }
}

// 响应数据模型
class ChatMenuItemResponse {
  final String weight;
  final String portability;
  final String fitnessUse;
  final String notes;

  ChatMenuItemResponse({
    required this.weight,
    required this.portability,
    required this.fitnessUse,
    required this.notes,
  });

  // 从JSON反序列化
  factory ChatMenuItemResponse.fromJson(Map<String, dynamic> json) {
    return ChatMenuItemResponse(
      weight: json['weight'],
      portability: json['portability'],
      fitnessUse: json['fitnessUse'],
      notes: json['notes'],
    );
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'portability': portability,
      'fitnessUse': fitnessUse,
      'notes': notes,
    };
  }
}

// 使用示例
void main11() {
  // JSON字符串
  String jsonString = '''
  {
    "menuNumber": "1",
    "menuTitle": "多重，倒了后能不能搬得动？平时可以举起来健身吗?",
    "menuId": 18,
    "menuType": "1",
    "response": {
      "weight": "约25公斤",
      "portability": "可搬运，建议两人协作",
      "fitnessUse": "不适合常规健身，存在安全风险",
      "notes": "重心设计非健身用途，强行举握可能导致受伤或产品损坏"
    }
  }
  ''';

  // 从JSON解码
  Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  ChatMenuItem menuItem = ChatMenuItem.fromJson(jsonMap);

  print('反序列化后的对象:');
  print('菜单标题: ${menuItem.menuTitle}');
  ///print('重量: ${menuItem.response!.weight}');

  // 序列化回JSON
  Map<String, dynamic> serialized = menuItem.toJson();
  String jsonOutput = jsonEncode(serialized);

  print('\n序列化后的JSON:');
  print(jsonOutput);
}