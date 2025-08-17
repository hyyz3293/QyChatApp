// 图片数据模型
class AttachmentData {
  final String code;
  final String file;
  final String fileName;
  final String desc;

  AttachmentData({
    required this.code,
    required this.fileName,
    required this.file,
    required this.desc,
  });

  // 从JSON创建对象
  factory AttachmentData.fromJson(Map<String, dynamic> json) {
    return AttachmentData(
      code: json['code'] as String,
      fileName: json['fileName'] as String,
      file: json['file'] as String,
      desc: json['desc'] as String,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'file': file,
      'fileName': fileName,
      'desc': desc,
    };
  }

  @override
  String toString() {
    return 'ImageData{code: $code, file: $file, fileName: $fileName, desc: $desc}';
  }
}