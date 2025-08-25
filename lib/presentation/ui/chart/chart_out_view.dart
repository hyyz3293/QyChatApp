import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/dio/dio_client.dart';
import '../../utils/global_utils.dart';
import '../../utils/service_locator.dart';
import '../../utils/websocket/chat_socket_manager.dart';
import '../chatview/chat_view_screen.dart';
import '../model/api_response.dart';
import '../model/channel_account_model.dart';
import '../model/channel_config_model.dart';
import '../model/sence_config_model.dart';
import '../model/user_account_model.dart';

class ChartExternalScreen extends StatefulWidget {
  final String channelCode;
  ChartExternalScreen({Key? key, required this.channelCode}) : super(key: key);
  @override
  State<ChartExternalScreen> createState() => _ChartHomeScreenState();
}

class _ChartHomeScreenState extends State<ChartExternalScreen> with WidgetsBindingObserver {

  bool isLoadIng = true;

  @override
  void initState() {
    super.initState();
    initApp();
    //CSocketIOManager();
    loadData();
  }

  Future<void> loadData() async {

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("channel_code", widget.channelCode);

    var json = await DioClient().getChannelConfig();
    //var logger = Logger();
    // 解析
    final response = ApiResponse<ChannelConfigModel>.fromJson(
      json,
          (dataJson) => ChannelConfigModel.fromJson(dataJson),
    );
    //SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    try {
      // /**
      //  * 移动端--是否允许使用相册{1:是,0:否}
      //  */
      // private int windowOptionAppwebPhoto;
      // /**
      //  * 移动端--是否允许使用拍照功能{1:是,0:否}
      //  */
      // private int windowOptionAppwebShoot;
      // /**
      //  * 移动端--是否允许使用留言功能{1:是,0:否}
      //  */
      // private int windowOptionAppwebMsg;
      // /**
      //  * 移动端--是否允许使用转人工功能{1:是,0:否}
      //  */
      // private int windowOptionAppwebAgent;

      int windowOptionAppwebPhoto = response.data.accessParams.windowOptionAppwebPhoto;
      int windowOptionAppwebShoot = response.data.accessParams.windowOptionAppwebShoot;
      int windowOptionAppwebMsg = response.data.accessParams.windowOptionAppwebMsg;
      int windowOptionAppwebAgent = response.data.accessParams.windowOptionAppwebAgent;

      sharedPreferences.setInt("windowOptionAppwebPhoto", windowOptionAppwebPhoto);
      sharedPreferences.setInt("windowOptionAppwebShoot", windowOptionAppwebShoot);
      sharedPreferences.setInt("windowOptionAppwebMsg", windowOptionAppwebMsg);
      sharedPreferences.setInt("windowOptionAppwebAgent", windowOptionAppwebAgent);

      int evaluationFlag = response.data.evaluateParams.evaluationFlag;
      String serviceEvaluateTxt = response.data.evaluateParams.serviceEvaluateTxt;

      sharedPreferences.setInt("evaluationFlag", evaluationFlag);
      sharedPreferences.setString("serviceEvaluateTxt", serviceEvaluateTxt);



    }catch(e) {}


    var cid = response.data.accessParams.cid;
    sharedPreferences.setInt("cid", cid);
    print("app-ChannelConfig- ${response}");
    print("app-cid- ${cid}");

    var userInfoJson = await DioClient().getUserinfoMessage();
    var userMap = userInfoJson["data"];
    var channelMap = userInfoJson["channel"];
    var userAccount =  UserAccountModel.fromJson(userMap);
    var channelAccount =  ChannelAccountModel.fromJson(channelMap);


    sharedPreferences.setString("token", userAccount.token);
    sharedPreferences.setInt("userId", userAccount.id);

    sharedPreferences.setString("userIdReal", userAccount.userid);

    sharedPreferences.setString("accid", userAccount.accid);
    sharedPreferences.setString("cpmpanyAccid", userAccount.cpmpanyAccid);

    sharedPreferences.setInt("channel_id", channelAccount.id);
    sharedPreferences.setInt("channel_type", channelAccount.type);
    sharedPreferences.setString("channel_name", channelAccount.name);

    printN("app-token- ${userAccount.token}");
    printN("app-userId- ${userAccount.userid}");

    printN("app-UserinfoMessage- ${userInfoJson}");

    var sceneConfigJson = await DioClient().getSceneConfig();
    final List<dynamic> sceneJson = sceneConfigJson['data'];
    List<SenceConfigModel> sceneList = sceneJson
        .map((item) => SenceConfigModel.fromJson(item))
        .toList();
    printN("app-sceneList- ${sceneList}");

    sharedPreferences.setString("sence_config", convert.jsonEncode(sceneJson));

    setState(() {
      isLoadIng = false;
    });
    CSocketIOManager();
  }

  Future<void> initApp() async {
    try {
      await ServiceLocator.configureDependencies();
    } catch (e) {
      print('[main] Initialization error: $e');
      // 即使初始化出错，也要启动应用，避免白屏
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoadIng
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          strokeWidth: 3.0,
        ),
      )
          : ChatViewScreen(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}