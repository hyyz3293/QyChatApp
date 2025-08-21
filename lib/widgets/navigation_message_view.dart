import 'dart:async';
import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:qychatapp/widgets/reaction_widget.dart';
import 'package:qychatapp/widgets/share_icon.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/config_models/image_message_configuration.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../models/data_models/message.dart';
import '../presentation/ui/model/im_user_menu.dart';

class NavigationMessageView extends StatefulWidget {
  const NavigationMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    //this.messageReactionConfig,
    this.highlightVideo = false,
    this.highlightScale = 1.2,
  }) : super(key: key);

  final Message message;
  final bool isMessageBySender;
  //final MessageReactionConfiguration? messageReactionConfig;
  final bool highlightVideo;
  final double highlightScale;

  @override
  State<NavigationMessageView> createState() => _NavigationState();
}

class _NavigationState extends State<NavigationMessageView> {

  List<ChatMenuItem> _navigationList = [];

  @override
  void initState() {
    super.initState();
    if ( widget.message.navigationList != null &&  widget.message.navigationList!.isNotEmpty) {
      _navigationList = widget.message.navigationList!;
    }

  }
  

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
      widget.isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
            borderRadius:BorderRadius.circular(27),
            color: Color(0xff383152),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _navigationList.map((item) {
              return _buildInfoRow(item);
            }).toList(),
          ),
        )
      ],
    );
  }


// 构建信息行 - 支持多行文本
  Widget _buildInfoRow(ChatMenuItem scene) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print("Selected: ${scene.menuTitle}");
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          constraints: BoxConstraints(
            minHeight: 48, // 最小高度确保触摸区域足够
          ),
          alignment: Alignment.centerLeft,
          child:  Expanded(
            child: Text(
              "11111111111111111111111111111111111111111111${scene.menuTitle}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              softWrap: true, // 允许换行
              maxLines: 3, // 最大行数限制
              overflow: TextOverflow.ellipsis, // 超出部分显示省略号
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
  }
  


}
