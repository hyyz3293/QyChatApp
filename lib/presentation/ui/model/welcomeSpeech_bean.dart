// 图片数据模型
class WelcomeSpeechData {
  final String welcomeSpeech;

  WelcomeSpeechData({
    required this.welcomeSpeech,
  });

  // 从JSON创建对象
  factory WelcomeSpeechData.fromJson(Map<String, dynamic> json) {
    return WelcomeSpeechData(
      welcomeSpeech: json['welcomeSpeech'] as String,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'welcomeSpeech': welcomeSpeech,
    };
  }

  @override
  String toString() {
    return 'WelcomeSpeechData{code: $welcomeSpeech}';
  }
}