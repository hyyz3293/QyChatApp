import 'dart:async';
import 'package:qychatapp/presentation/utils/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChartHomeScreen extends StatefulWidget {
  @override
  State<ChartHomeScreen> createState() => _ChartHomeScreenState();
}

class _ChartHomeScreenState extends State<ChartHomeScreen> with WidgetsBindingObserver {

  final List<TextEditingController> _controllers = List.generate(
    1, (index) => TextEditingController(),
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
                  _buildButton('确定', Colors.green, _showValues),
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

}