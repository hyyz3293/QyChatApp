import 'dart:async';


import 'package:boilerplate/presentation/ui/model/channel_account_model.dart';
import 'package:boilerplate/presentation/ui/model/channel_config_model.dart';
import 'package:boilerplate/presentation/utils/dio/dio_client.dart';
import 'package:boilerplate/presentation/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global_utils.dart';
import '../utils/websocket/chat_socket_manager.dart';
import '../utils/websocket/socket_manager.dart';
import 'model/api_response.dart';
import 'model/user_account_model.dart';


class ChartHomeScreen extends StatefulWidget {
  @override
  State<ChartHomeScreen> createState() => _ChartHomeScreenState();
}

class _ChartHomeScreenState extends State<ChartHomeScreen> with WidgetsBindingObserver {

  // 创建6个文本控制器
  final List<TextEditingController> _controllers = List.generate(
    1,
        (index) => TextEditingController(),
  );


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("app 从后台到前台");

    } else if (state == AppLifecycleState.paused) {
      print("app 从前台到后台");
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _controllers[0].text = "0fa684c5166b4f65bba9231f071a756d";

  }

  Widget _buildRoot() {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天'),
      ),
      body: Padding(
        padding:  EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 6个竖向排列的输入框
              for (int i = 0; i < 1; i++)

                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextField(
                    controller: _controllers[i],
                    decoration: InputDecoration(
                      hintText:i == 0 ? "ChannelCode" : '输入框 ${i + 1}',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),
                ),

              SizedBox(height: 30),

              // 按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //_buildButton('清空', Colors.orange, _clearAllFields),
                  _buildButton('确定', Colors.green, _showValues),
                  //_buildButton('取消', Colors.red, () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  Future<void> _showValues() async {
    var channelCode = _controllers[0].text;
    if (channelCode.isEmpty) {
      showToast("请输入ChannelCode");
      return;
    }

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("channel_code", channelCode);

    GoRouter.of(context).push(Routes.ChartTestRoot, extra: channelCode);

    // if (CSocketIOManager().isConnected) {
    //   print("------>>>> 已连接");
    //   GoRouter.of(context).push(Routes.ChartTestRoot);
    // } else {
    //   print("------>>>> 未连接");
    //
    //   loadData();
    // }
    //loadData();
    //GoRouter.of(context).push(Routes.ChartTestRoot);

    // String values = '';
    // for (int i = 0; i < _controllers.length; i++) {
    //   values += '输入框 ${i + 1}: ${_controllers[i].text}\n';
    // }
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text('输入内容'),
    //     content: Text(values),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: Text('确定'),
    //       )
    //     ],
    //   ),
    // );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: _buildRoot()
    );
  }

  @override
  void dispose() {
    // 销毁所有控制器
    for (var controller in _controllers) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }


  Future<void> loadData() async {
    var json = await DioClient().getChannelConfig();
    //var logger = Logger();
    // 解析
    final response = ApiResponse<ChannelConfigModel>.fromJson(
      json,
          (dataJson) => ChannelConfigModel.fromJson(dataJson),
    );
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
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
    sharedPreferences.setString("accid", userAccount.accid);
    sharedPreferences.setString("cpmpanyAccid", userAccount.cpmpanyAccid);

    sharedPreferences.setInt("channel_id", channelAccount.id);
    sharedPreferences.setInt("channel_type", channelAccount.type);
    sharedPreferences.setString("channel_name", channelAccount.name);

    printN("app-token- ${userAccount.token}");
    printN("app-userId- ${userAccount.userid}");

    printN("app-UserinfoMessage- ${userInfoJson}");


    // if (!CSocketIOManager().isConnected) {
    //   CSocketIOManager().connect();
    // }

    //GoRouter.of(context).push(Routes.ChartTestRoot, extra: c);

  }




}