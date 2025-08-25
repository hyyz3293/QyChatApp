import 'dart:io';
import 'package:qychatapp/presentation/utils/global_utils.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/model/message_send_model.dart';


class Endpoints {
  Endpoints._();

  // 正式 url
  static const String baseUrl = "https://uat-ccc.qylink.com:9991";


  // connectTimeout
  static const Duration connectionTimeout = Duration(milliseconds: 1200000);

  // receiveTimeout
  static const Duration receiveTimeout = Duration(milliseconds: 150000);
}

class DioClient {
  // 获取Dio实例的getter方法
  Dio get dio => _dio;

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    _dio = Dio();
    _initializeDio();
  }

  static final DioClient _singleton = DioClient._internal();

  late Dio _dio;

  void _initializeDio() {
    _dio
      ..options.baseUrl = Endpoints.baseUrl
      ..options.connectTimeout = Endpoints.connectionTimeout
      ..options.receiveTimeout = Endpoints.receiveTimeout;

    // 添加一个拦截器来检查身份验证令牌
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // // 声明一个列表，包含所有需要令牌的受保护端点路径
        // const List<String> protectedEndpoints = [
        //   '/add_resource_to_collection',
        //   '/buy_resource',
        //   '/del_resource',
        //   '/get_my_collections',
        //   '/get_my_library',
        // ];

        // // 检查是否是受保护的端点
        // bool isProtectedEndpoint = protectedEndpoints
        //     .any((endpoint) => options.path.contains(endpoint));

        // if (isProtectedEndpoint) {
        //   String? token = await getIt<UserSharedHelper>().authToken;
        //
        //   if (token == null) {
        //     // 不继续执行请求
        //     return handler.reject(DioException(
        //       requestOptions: options,
        //       error: 'Auth token not available, user is not logged in.',
        //     ));
        //   } else {
        //     // 如果有令牌，则继续执行请求
        //     options.headers['Authorization'] = '$token';
        //   }
        // }

        // // 用户类型 (普通用户不传)
        // UserRole userRole = await getIt<UserSharedHelper>().userRole;
        //
        // if (userRole == UserRole.Developer) {
        //   // 开发者用户
        //   options.headers['userType'] = 'developer';
        // } else if (userRole == UserRole.BetaTester) {
        //   // 内测用户
        //   options.headers['userType'] = 'betaTester';
        // }
        //
        // // 判断是否是登录状态
        // bool isLogin = await getIt<UserSharedHelper>().isLoggedIn;
        //
        // if (isLogin) {
        //   String? userId = await getIt<UserSharedHelper>().userId;
        //   printN("userId:${userId}");
        //   printN("options.path:${options.path}");
        //   // 只有这个接口用的ID是亚马逊id
        //   if (options.path.contains("/user/get_user_info")) {
        //     userId = await getIt<UserSharedHelper>().awsId;
        //     printN("awsId ->:${userId}");
        //   }
        //
        //   // 确保userId存在 ----todo jack update_user_info 这个接口不能要user_id
        //   if (userId.isNotEmpty &&
        //       !options.queryParameters.containsKey('user_id') &&
        //       !options.queryParameters.containsKey('userId') &&
        //       !options.path.contains("/user/update_user_info")) {
        //     if (options.method.toUpperCase() == 'GET') {
        //       options.queryParameters.addAll({'user_id': userId});
        //     } else {
        //       // 如果data是FormData，直接添加
        //       if (options.data is FormData) {
        //         FormData formData = options.data as FormData;
        //         formData.fields.add(MapEntry('user_id', userId));
        //       }
        //       // 如果data是Map，则直接添加
        //       else if (options.data is Map<String, dynamic>) {
        //         Map<String, dynamic> data =
        //             options.data as Map<String, dynamic>;
        //         data['user_id'] = userId;
        //       }
        //       // 如果没有任何数据被发送, 则创建一个包含userId的Map
        //       else if (options.data == null) {
        //         options.data = {'user_id': userId};
        //       }
        //     }
        //   }
        //
        //   // // 请求头加token
        //   // String? idToken = await getIt<UserSharedHelper>().authToken;
        //   //
        //   // if (idToken != null) {
        //   //   options.headers['ID-TOKEN'] = idToken;
        //   // }
        // }

        // 如果没有身份认证要求或已有令牌，则继续执行请求
        return handler.next(options);
      },
    ));

    // 添加一个拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 打印请求相关信息
        print('发送请求： ${options.method} ${options.path}');
        print('请求头部： ${options.headers}');
        print('请求参数： ${options.queryParameters}');
        if (options.data != null) {
          if (options.data is FormData) {
            final formData = options.data as FormData;
            final formDataMap = <String, dynamic>{};

            // FormData中可能包含文件（用MultipartFile表示），也可能包含字段（用MapEntry表示）
            for (final MapEntry<String, MultipartFile> file in formData.files) {
              formDataMap[file.key] = 'File: ${file.value.filename}';
            }

            formData.fields.forEach((element) {
              formDataMap[element.key] = element.value;
            });

            // 打印出所有字段及其值
            print('请求体--> $formDataMap');
          } else {
            // 如果请求体不是FormData，直接打印它
            print('请求体--> ${options.data}');
          }
        }
        handler.next(options); // 继续请求
      },
      onResponse: (response, handler) {
        // 打印响应相关信息
        print('响应数据: ${response.data}');
        handler.next(response); // 继续响应
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          print('接口返回401,退出登录。');

          //await getIt<UserSharedHelper>().logOut();
        } else {
          // 对于非401错误，打印错误并继续
          print('请求错误： ${e.toString()}');
          handler.next(e); // 继续错误处理
        }
      },
    ));
  }

  // Get:-----------------------------------------------------------------------
  Future<dynamic> get(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      // (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      //     (HttpClient client) {
      //   client.badCertificateCallback =
      //       (X509Certificate cert, String host, int port) => true;
      //   return client;
      // };

      final Response response = await _dio.get(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

// Post:----------------------------------------------------------------------
  Future<dynamic> post(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final Response response = await _dio.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      throw e;
    }
  }

// Put:-----------------------------------------------------------------------
  Future<dynamic> put(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final Response response = await _dio.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  var time = 0;
// Delete:--------------------------------------------------------------------
  Future<dynamic> delete(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      final Response response = await _dio.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      throw e;
    }
  }

  // 1、获取TOKEN接口
  Future<Map<String, dynamic>> getAppToken() async {
    try {
      // Map<String, dynamic> dataMap = {};
      // dataMap["channelCode"] = "0fa684c5166b4f65bba9231f071a756d";
      // printN("app_token---start");
      // printN("app_token---dataMap---.>>>>${dataMap}");
      // Map<String, dynamic> response =
      // await get(
      //     Endpoints.baseUrl + "/api/imBase/imWebParam/public/getConfigurationParam",
      //     queryParameters: dataMap);
      // printN("app_token---success----${response}");
      // return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("app_token---error----${e.toString()}");
    }
    printN("app_token---end");
    return {};
  }

  // 2、获取渠道配置参数
  Future<Map<String, dynamic>> getChannelConfig() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var channelCode = sharedPreferences.getString("channel_code");
      Map<String, dynamic> dataMap = {};
      dataMap["channelCode"] = channelCode;
      printN("app_token---start");
      printN("app_token---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await get(
          Endpoints.baseUrl + "/api/imBase/imWebParam/public/getConfigurationParam",
          queryParameters: dataMap);
      printN("app_token---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("app_token---error----${e.toString()}");
    }
    printN("app_token---end");
    return {};
  }

  // 3、获取用户信息
  Future<Map<String, dynamic>> getUserinfoMessage() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var cid = sharedPreferences.getInt("cid") ?? 0;
      var channelCode = sharedPreferences.getString("channel_code");
      Map<String, dynamic> dataMap = {};
      dataMap["cid"] = cid;
      dataMap["channelCode"] = channelCode;
      dataMap['userID'] = "";
      printN("userinfo---start");
      printN("userinfo---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await post(
          Endpoints.baseUrl + "/api/imBase/imVisitor/getAccount",
          queryParameters: dataMap);
      printN("userinfo---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("userinfo---error----${e.toString()}");
    }
    printN("userinfo---end");
    return {};
  }

  // 4、获取场景配置
  Future<Map<String, dynamic>> getSceneConfig() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      //var channelCode = sharedPreferences.getString("channel_code");
      var cid = sharedPreferences.getInt("cid") ?? 0;

      Map<String, dynamic> dataMap = {};
      //dataMap["channelCode"] = channelCode;
      dataMap["sceneName"] = "";
      dataMap["cid"] = cid;
      printN("Scene---start");
      printN("Scene---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await get("${Endpoints.baseUrl}/api/imBase/sceneconfig/querySceneKeys",
          queryParameters: dataMap);
      printN("Scene---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("Scene---error----${e.toString()}");
    }
    printN("Scene---end");
    return {};
  }

  // 5、获取历史消息
  Future<Map<String, dynamic>> getHistoryList(int page, int lastTime) async {
    try {
      Map<String, dynamic> dataMap = {};
      dataMap["page"] = page;
      dataMap["limit"] = 30;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var userId = sharedPreferences.getInt("userId") ?? 0;
      dataMap["time"] = lastTime;
      dataMap["userid"] = '${userId}';
      //lt/gt小于/大于指定时间戳
      dataMap["compare"] = "lt";
      printN("history---start");
      printN("history---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await get(
          Endpoints.baseUrl + "/api/imBase/servicerecorddetailed/queryPage",
          queryParameters: dataMap);
      printN("history---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("history---error----${e.toString()}");
    }
    printN("history---end");
    return {};
  }

  // 6、获取当前会话消息
  Future<Map<String, dynamic>> getCurrRecordByAccid() async {
    try {
      Map<String, dynamic> dataMap = {};
      dataMap["accid"] = "";
      printN("CurrRecord---start");
      printN("CurrRecord---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await get(
          Endpoints.baseUrl + "/pi/imBase/servicerecorddetailed/getCurrRecordByAccid",
          queryParameters: dataMap);
      printN("CurrRecord---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("CurrRecord---error----${e.toString()}");
    }
    printN("CurrRecord---end");
    return {};
  }

  // 7、发送消息
  Future<bool> sendMessage(ServiceMessageBean serviceMessageBean) async {
    try {
      Map<String, dynamic> dataMap = {};
      dataMap = serviceMessageBean.toJson();
      Map<String, dynamic> response =
      await post(
          Endpoints.baseUrl + "/messageproxy/sendMsgV2",
          data: dataMap);
      printN("sendMessage---success----${response}");
      //{msg: success, code: 0, data: {code: 200, data: {timetag: 1754620306277}}}
      if (response["data"]["code"] == 200)
        return true;
    } catch (e) {
      // 请求失败，抛出异常
      printN("sendMessage---error----${e.toString()}");
    }
    printN("sendMessage---end");
    return false;
  }

  // 8、留言接口
  Future<Map<String, dynamic>> leaveMessage(
      String customerName,
      String customerPhone,
      String info,
      String content,
      ) async {
    try {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var cid = sharedPreferences.getInt("cid") ?? 0;
      var userId = sharedPreferences.getInt("userId") ?? 0;
    var channel_id = sharedPreferences.getInt("channel_id") ?? 0;
    var channel_type = sharedPreferences.getInt("channel_type") ?? 0;



    Map<String, dynamic> dataMap = {};
      dataMap["customerName"] = "$customerName";
      dataMap["customerPhone"] = "$customerPhone";
      dataMap["info"] = "$info";
      dataMap["content"] = "$content";
      dataMap["cid"] = "$cid";
      dataMap["userid"] = "$userId";
      dataMap["channelType"] = "$channel_type";
      dataMap["channelId"] = "${channel_id}";

      printN("leaveMessage---start");
      printN("leaveMessage---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await post(
          Endpoints.baseUrl + "/api/imBase/baseImLeaveMessage/leaveMessage",
          data: dataMap);
      printN("leaveMessage---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("leaveMessage---error----${e.toString()}");
    }
    printN("leaveMessage---end");
    return {};
  }

  // 9、查询基础配置信息
  Future<Map<String, dynamic>> queryCommonConfig() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var cid = sharedPreferences.getInt("cid") ?? 0;
      Map<String, dynamic> dataMap = {};
      dataMap["cid"] = cid;
      dataMap["channelCode"] = "0fa684c5166b4f65bba9231f071a756d";
      dataMap['userID'] = "a9184b47a17040c2aed2d72703a247b3";
      printN("userinfo---start");
      printN("userinfo---dataMap---.>>>>${dataMap}");
      Map<String, dynamic> response =
      await post(
          Endpoints.baseUrl + "/api/imBase/baseImLeaveMessage/leaveMessage",
          queryParameters: dataMap);
      printN("userinfo---success----${response}");
      return response;
    } catch (e) {
      // 请求失败，抛出异常
      printN("userinfo---error----${e.toString()}");
    }
    printN("userinfo---end");
    return {};
  }

  // 9、上传文件
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      // 1. 创建文件对象
      File file = File(filePath);

      // 2. 检查文件是否存在
      if (!await file.exists()) {
        printN("文件不存在: $filePath");
        return {};
      }

      // 3. 获取文件名（不含路径）
      String fileName = path.basename(filePath);

      // 4. 创建 FormData
      FormData formData = FormData.fromMap({
        "files": await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        // 可添加其他表单字段
        // "key": "value",
      });

      // 5. 发送请求
      Map<String, dynamic> response = await post(
        Endpoints.baseUrl + "/api/fileservice/file/upload",
        data: formData, // 使用 formData 作为请求体
      );

      printN("文件上传成功: $response");

      // 6. 根据响应判断是否成功
      return response; // 根据实际接口返回调整判断逻辑
    } catch (e) {
      printN("文件上传失败: ${e.toString()}");
      return {};
    }
  }

}
