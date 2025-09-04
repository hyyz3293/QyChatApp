import 'dart:async';
import 'dart:convert';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:oktoast/oktoast.dart';
import 'package:qychatapp/presentation/ui/model/im_user_link.dart';
import 'package:qychatapp/presentation/utils/websocket/chat_socket_manager.dart';
import 'package:qychatapp/widgets/reaction_widget.dart';
import 'package:qychatapp/widgets/share_icon.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/config_models/image_message_configuration.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../models/data_models/message.dart';
import '../presentation/ui/model/im_user_menu.dart';

class LinksMessageView extends StatefulWidget {
  const LinksMessageView({
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
  State<LinksMessageView> createState() => _NavigationState();
}

class _NavigationState extends State<LinksMessageView> {

  List<ChatLinkItem> _linksList = [];

  @override
  void initState() {
    super.initState();
    if ( widget.message.links != null &&  widget.message.links!.isNotEmpty) {
      _linksList = widget.message.links!;
    }

  }
  

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: widget.isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7, // 限制最大宽度
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), // 使用较小的圆角
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 让子项填充宽度
            mainAxisSize: MainAxisSize.min,
            children: _buildNavigationItems(),
          ),
        )
      ],
    );
  }

  List<Widget> _buildNavigationItems() {
    List<Widget> items = [];

    for (int i = 0; i < _linksList.length; i++) {
      items.add(_buildInfoRow(_linksList[i]));

      // 添加分隔线（最后一个项目不添加）
      if (i < _linksList.length - 1) {
        items.add(Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.withOpacity(0.3),
          indent: 16,
          endIndent: 16,
        ));
      }
    }

    return items;
  }
// 构建信息行 - 支持多行文本
  Widget _buildInfoRow(ChatLinkItem scene) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ///print("Selected: ${scene.menuTitle}");
          //CSocketIOManager().sendSenseConfig(scene);
          _launchURL(context, scene.href);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            minHeight: 48, // 最小高度确保触摸区域足够
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${scene.text}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  softWrap: true, // 允许换行
                  maxLines: 3, // 最大行数限制
                  overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        showToast('无法打开链接');
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  


}
