
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

mixin ServiceLocator {

  static Future<void> configureDependencies() async {
    // 注册 Eventbus
    getIt.registerSingleton<EventBus>(EventBus());
  }


}
