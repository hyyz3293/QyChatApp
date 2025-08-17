import 'dart:math';

import 'package:boilerplate/controller/chat_controller.dart';
import 'package:boilerplate/extensions/extensions.dart';
import 'package:boilerplate/models/config_models/feature_active_config.dart';
import 'package:boilerplate/models/config_models/message_list_configuration.dart';
import 'package:boilerplate/models/config_models/suggestion_list_config.dart';
import 'package:boilerplate/models/data_models/message.dart';
import 'package:boilerplate/models/data_models/reply_message.dart';
import 'package:boilerplate/values/enumeration.dart';
import 'package:boilerplate/values/typedefs.dart';
import 'package:boilerplate/widgets/suggestions/suggestion_list.dart';
import 'package:boilerplate/widgets/type_indicator_widget.dart';
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
  bool get isSent => widget.status != MessageStatus.pending;

  bool isVisible = false;

  _attachOnStatusChangeListeners() {
    if (isSent) {
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
