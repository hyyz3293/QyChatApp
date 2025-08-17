class ApiResponse<T> {
  //final String msg;
  final int code;
  final T data;
  final dynamic page;

  ApiResponse({
    //required this.msg,
    required this.code,
    required this.data,
    this.page,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return ApiResponse<T>(
      //msg: json['msg'] as String,
      code: json['code'] as int? ?? 0,
      data: fromJsonT(json['data'] as Map<String, dynamic>),
      page: json['page'],
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      //'msg': msg,
      'code': code,
      'data': toJsonT(data),
      'page': page,
    };
  }
}