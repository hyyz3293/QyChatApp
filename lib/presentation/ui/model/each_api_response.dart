import 'file_model.dart';

class EnhancedApiResponse {
  final String msg;
  final int code;
  final List<FileData> data;
  final Map<String, dynamic>? page; // 明确为 Map 或 null

  EnhancedApiResponse({
    required this.msg,
    required this.code,
    required this.data,
    required this.page,
  });

  factory EnhancedApiResponse.fromJson(Map<String, dynamic> json) {
    return EnhancedApiResponse(
      msg: _parseString(json['msg']),
      code: _parseInt(json['code']),
      data: _parseFileDataList(json['data']),
      page: json['page'] != null ? Map<String, dynamic>.from(json['page']) : null,
    );
  }

  // 类型安全的解析方法
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<FileData> _parseFileDataList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((item) => FileData.fromJson(item))
        .toList();
  }
}