// 图片数据模型
class ComplexData {
  final String title;
  final String content;


  ComplexData({
    required this.title,
    required this.content,

  });

  // 从JSON创建对象
  factory ComplexData.fromJson(Map<String, dynamic> json) {
    return ComplexData(
      title: json['title'] as String,
      content: json['content'] as String,

    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }

  @override
  String toString() {
    return 'WelcomeSpeechData{code: $content}';
  }
}