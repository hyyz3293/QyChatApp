import 'dart:math';

import 'package:qychatapp/controller/chat_controller.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/config_models/feature_active_config.dart';
import 'package:qychatapp/models/config_models/message_list_configuration.dart';
import 'package:qychatapp/models/config_models/suggestion_list_config.dart';
import 'package:qychatapp/models/data_models/message.dart';
import 'package:qychatapp/models/data_models/reply_message.dart';
import 'package:qychatapp/values/enumeration.dart';
import 'package:qychatapp/values/typedefs.dart';
import 'package:qychatapp/widgets/suggestions/suggestion_list.dart';
import 'package:qychatapp/widgets/type_indicator_widget.dart';
import 'package:flutter/material.dart';

class SendingMessageAnimatingWidget extends StatefulWidget {
  const SendingMessageAnimatingWidget(this.status, {Key? key})
      : super(key: key);

  final MessageStatus status;

  @override
  State<SendingMessageAnimatingWidget> createState() =>
      _SendingMessageAnimatingWidgetState();
}

class _SendingMessageAnimatingWidgetState
    extends State<SendingMessageAnimatingWidget> with TickerProviderStateMixin {
  bool get isSent => widget.status != MessageStatus.pending && widget.status != MessageStatus.offline;
  bool get isOffline => widget.status == MessageStatus.offline;

  bool isVisible = false;

  _attachOnStatusChangeListeners() {
    if (isSent && !isOffline) {
      Future.delayed(const Duration(milliseconds: 400), () {
        isVisible = true;
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _attachOnStatusChangeListeners();
    
    // 离线消息显示感叹号图标
    if (isOffline) {
      return Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 8),
        child: Icon(
          Icons.error_outline,
          color: Colors.red[700],
          size: 14,
        ),
      );
    }
    
    return AnimatedPadding(
      curve: Curves.easeInOutExpo,
      duration: const Duration(seconds: 1),
      padding: EdgeInsets.only(right: isSent ? 5 : 8.0, bottom: isSent ? 8 : 2),
      child: isVisible
          ? const SizedBox()
          : Transform.rotate(
              angle: !isSent ? pi / 10 : -pi / 12,
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 2,
                  bottom: 5,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.grey,
                  size: 12,
                ),
              )),
    );
  }
}
