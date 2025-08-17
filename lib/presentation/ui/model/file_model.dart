class FileData {
  final int id;
  final dynamic cid; // 可能是 null 或其他类型
  final String filecode;
  final String filename;
  final String filepath;
  final String relativepath;
  final int size;
  final int delFlag;
  final dynamic createTime; // 可能是 null 或其他类型
  final dynamic updateTime; // 可能是 null 或其他类型

  FileData({
    required this.id,
    this.cid,
    required this.filecode,
    required this.filename,
    required this.filepath,
    required this.relativepath,
    required this.size,
    required this.delFlag,
    this.createTime,
    this.updateTime,
  });

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cid': cid,
      'filecode': filecode,
      'filename': filename,
      'filepath': filepath,
      'relativepath': relativepath,
      'size': size,
      'delFlag': delFlag,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  // 从 JSON 创建
  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      id: json['id'] as int,
      cid: json['cid'],
      filecode: json['filecode'] as String,
      filename: json['filename'] as String,
      filepath: json['filepath'] as String,
      relativepath: json['relativepath'] as String,
      size: json['size'] as int,
      delFlag: json['delFlag'] as int,
      createTime: json['createTime'],
      updateTime: json['updateTime'],
    );
  }
}