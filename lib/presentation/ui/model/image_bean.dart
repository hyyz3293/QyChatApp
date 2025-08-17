// 图片数据模型
class ImageData {
  final String code;
  final String src;
  final String href;
  final String desc;

  ImageData({
    required this.code,
    required this.src,
    required this.href,
    required this.desc,
  });

  // 从JSON创建对象
  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      code: json['code'] as String,
      src: json['src'] as String,
      href: json['href'] as String,
      desc: json['desc'] as String,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'src': src,
      'href': href,
      'desc': desc,
    };
  }

  @override
  String toString() {
    return 'ImageData{code: $code, src: $src, href: $href, desc: $desc}';
  }
}