import 'dart:async';
import 'package:qychatapp/presentation/my_app.dart';
import 'package:qychatapp/presentation/utils/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await setPreferredOrientations();
    await PackageInfo.fromPlatform();
    await ServiceLocator.configureDependencies();
  } catch (e) {
    print('[main] Initialization error: $e');
    // 即使初始化出错，也要启动应用，避免白屏
  }

  // 全局捕获flutter异常
  FlutterError.onError = (FlutterErrorDetails details) {
    print('[flutter error]' + details.exceptionAsString());
    FlutterError.presentError(details);
  };

  runApp(OKToast(
    child: MyApp(),
  ));
}

Future<void> setPreferredOrientations() async {
  // 设置系统 UI 为边缘到边缘模式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 设置状态栏和导航栏样式
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent, // 状态栏透明
    systemNavigationBarColor: Colors.transparent, // 导航栏透明
    statusBarIconBrightness: Brightness.light, // 状态栏字体颜色为白色
    systemNavigationBarIconBrightness: Brightness.light, // 导航栏图标颜色为白色
  ));

  // 设置设备方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
