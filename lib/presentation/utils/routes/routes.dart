import 'package:qychatapp/presentation/ui/chart/chart_message.dart';
import 'package:qychatapp/presentation/ui/chart/chart_out_view.dart';
import 'package:qychatapp/presentation/ui/chart_home.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/dash/dash_chart_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class Routes {
  Routes._();

  static const String ChartRoot = '/chart-root';
  static const String ChartTestRoot = '/chart-test-root';
  static const String ChartHomeRoot = '/chart-home-root';
  static const String DashChartHomeRoot = '/dash-chart-home-root';
  static const String ChatMessageRoot = '/chat-message-root';


  // 初始化GoRouter
  static final routes = GoRouter(
    debugLogDiagnostics: true,
    observers: [routeObserver],
    initialLocation: ChartRoot,
    routes: [
      GoRoute(
        path: Routes.ChartRoot,
        pageBuilder: (context, state) {
          return MaterialPage<dynamic>(
            key: state.pageKey,
            child: ChartHomeScreen(), // 传递字符串参数
          );
        },
      ),
      GoRoute(
        path: Routes.ChartTestRoot,
        pageBuilder: (context, state) {
          final Map urlMap = state.extra as Map? ?? {};
          final String channelCode = urlMap["channelCode"];
          final String userInfo = urlMap["userInfo"];
          return MaterialPage<dynamic>(
            key: state.pageKey,
            child: ChartExternalScreen(channelCode: channelCode, userInfo: userInfo,), // 传递字符串参数
          );
        },
      ),
      GoRoute(
        path: Routes.ChatMessageRoot,
        pageBuilder: (context, state) {
          return MaterialPage<dynamic>(
            key: state.pageKey,
            child: ChatMessageScreen(), // 传递字符串参数
          );
        },
      ),
    ],
  );
}

// 上下返回 UpDownReturn
class UpDownTransitionPage extends Page<dynamic> {
  final Widget child;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  UpDownTransitionPage({
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.reverseTransitionDuration = const Duration(milliseconds: 20),
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return child;
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        // 下滑进入的动画
        var enterTween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));
        var enterAnimation = animation.drive(enterTween);

        // 从顶部滑下来的旧页面退出动画
        var exitTween = Tween(begin: Offset.zero, end: Offset(0.0, 1.0))
            .chain(CurveTween(curve: Curves.easeIn));
        var exitAnimation = secondaryAnimation.drive(exitTween);

        // 当正向动画播放时使用进入动画，当反向动画播放时使用退出动画
        return SlideTransition(
          position: animation.status == AnimationStatus.reverse
              ? exitAnimation
              : enterAnimation,
          child: child,
        );
      },
    );
  }
}
