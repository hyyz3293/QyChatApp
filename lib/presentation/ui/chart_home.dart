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
    2, (index) => TextEditingController(),
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
    _controllers[1].text = "E4D6FAEC3F6A662BB1D2D8427907DC83A0E9D73F5A8FBCF09F6267C33948F4CAF490D8A89589B84213C70303E0997A61C66786CEF1F8A9B7D9F1F67D8B695B98951BE6C5AC012832CAF53E4186B0FFE9D955579D0FAC311367283707BBDA8A98C3D21E6824CD3D62A8B6327F56915FE1297F1B7E9D430587E5F5EEDBC86A70E65802BBA374F7921E21CC4AE63AE4E87AF06DC359E678ED8FFE22C8FB2966AE22621D3F8C5A64CFB1138EEE7D8E785B8FFBE5B20A21F2C96610B8C54BD95DACC9315BF9D373C2B908A9FE8D1A7AA7F45C2BB6EEF0DC88250E9C88147C57BFAD1CE532D418274F2C0064CCABDAA650FD92838284425441528C45BD1AFB1E11AFDE";
  }

  Widget _buildRoot() {
    return Scaffold(
      backgroundColor: Color(0XFFf4f5f7),
      appBar: AppBar(
        title: Text('聊天'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0XFFd5d8e4),
                Color(0XFFb6bfcb)
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding:  EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 6个竖向排列的输入框
              for (int i = 0; i < 2; i++)

                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextField(
                    controller: _controllers[i],
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: i == 0 ? "ChannelCode" :
                      i == 1 ? "userInfo" :
                      '输入框 ${i + 1}',
                      hintStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.black,
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

  Future<void> _showValues() async {
    var channelCode = _controllers[0].text;
    if (channelCode.isEmpty) {
      showToast("请输入ChannelCode");
      return;
    }
    var userInfo = _controllers[1].text;
    if (channelCode.isEmpty) {
      showToast("请输入userInfo");
      return;
    }
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("channel_code", channelCode);
    GoRouter.of(context).push(Routes.ChartTestRoot, extra: {
      'channelCode': channelCode,
      'userInfo': userInfo,
    });
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