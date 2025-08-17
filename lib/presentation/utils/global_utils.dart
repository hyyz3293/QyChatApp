
import 'package:logger/logger.dart';

/// 简写的日志输出函数
void printN(Object? message) {
  Logger logger = Logger();
  logger.e("${message.toString()}");
}
