import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/models.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:qychatapp/presentation/ui/chart/press_view.dart';
import 'package:qychatapp/presentation/utils/websocket/chat_socket_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../presentation/ui/model/channel_config_model.dart';
import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';

class TextOverMessageView extends StatefulWidget {
  TextOverMessageView({
    Key? key,
    required this.isMessageBySender,
    required this.message,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.messageReactionConfig,
    this.highlightMessage = false,
    this.highlightColor,
    this.richTextBuilder, // 新增富文本构建器
  }) : super(key: key);

  final bool isMessageBySender;
  final Message message;
  final double? chatBubbleMaxWidth;
  final ChatBubble? inComingChatBubbleConfig;
  final ChatBubble? outgoingChatBubbleConfig;
  final MessageReactionConfiguration? messageReactionConfig;
  final bool highlightMessage;
  final Color? highlightColor;

  // 新增富文本构建器参数
  final RichTextBuilder? richTextBuilder;

  @override
  State<TextOverMessageView> createState() => _TextOverMessageViewState();
}

class _TextOverMessageViewState extends State<TextOverMessageView> {
  final TextEditingController _textController = TextEditingController();
  bool _hasShownDialog = false; // 添加标记，记录是否已经显示过弹窗


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textMessage = widget.message.message;

    // 获取富文本内容（如果可用）
    final richText = widget.richTextBuilder?.call(widget.message);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: widget.chatBubbleMaxWidth ??
                  MediaQuery.of(context).size.width * 0.75),
          padding: _padding ??
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
          margin: _margin ??
              EdgeInsets.fromLTRB(
                  5, 0, 6, widget.message.reaction.reactions.isNotEmpty ? 15 : 2),
          decoration: BoxDecoration(
            color: widget.highlightMessage ? widget.highlightColor : _color,
            borderRadius: _borderRadius(textMessage),
          ),
          child: textMessage.isUrl
              ? LinkPreview(
            linkPreviewConfig: _linkPreviewConfig,
            url: textMessage,
          )
              : GestureDetector(
            onTap: () {
              // 检查是否已经显示过弹窗
              if (!_hasShownDialog) {
                showDialogPress(context);
              }
            },
            child: _buildTextContent(textTheme, textMessage, richText),
          ),
        ),
        if (widget.message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            isMessageBySender: widget.isMessageBySender,
            reaction: widget.message.reaction,
            messageReactionConfig: widget.messageReactionConfig,
          ),
      ],
    );
  }

  Future<void> showDialogPress(BuildContext context) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String test = await sharedPreferences.getString("imEvaluationDefineList") ?? "";
     var testMap = convert.jsonDecode(test);
    final List<dynamic> sceneJson2 = testMap;
    List<ImEvaluationDefine> satisfactionOptions = sceneJson2
        .map((item) => ImEvaluationDefine.fromJson(item))
        .toList();

    // 显示对话框并等待用户选择
    final selectedItem = await showDialog<ImEvaluationDefine>(
      context: context,
      builder: (BuildContext context) {
        return EvaluationSelectorDialog(
          options: satisfactionOptions,
          title: "请选择满意度",
        );
      },
    );

    if (selectedItem != null) {
      // 设置标记，表示已经显示过弹窗并且用户已确定
      setState(() {
        _hasShownDialog = true;
      });
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('您选择了: ${selectedItem.pressValue} (ID: ${selectedItem.id})')),
      // );
      print('完整对象: $selectedItem');

      CSocketIOManager().sendPress(selectedItem);
    }
  }


  // 构建文本内容（支持富文本或普通文本）
  Widget _buildTextContent(TextTheme textTheme, String textMessage, InlineSpan? richText) {
    final defaultStyle = _textStyle ?? textTheme.bodyMedium!.copyWith(
      color: Colors.black,
      fontSize: 16,
    );

    // if (richText != null) {
    //   return RichText(
    //     text: richText,
    //     textAlign: TextAlign.start,
    //   );
    // }

    // 检测并处理简单富文本标记
    if (_containsSimpleRichText(textMessage)) {
      // 处理图片路径 - 添加前缀
      final processedHtml = _processImageUrls(widget.message.message);

      return Html(
        data: processedHtml,
        style: {
          "body": Style(
            fontSize: FontSize(16.0),
            color: Colors.black,
            // margin: EdgeInsets.zero,
            //padding: EdgeInsets.zero,
          ),
          "p": Style(
            //margin: EdgeInsets.zero
          ),
          "b": Style(fontWeight: FontWeight.bold),
          "i": Style(fontStyle: FontStyle.italic),
          "u": Style(textDecoration: TextDecoration.underline),
          "a": Style(
            color: Colors.blue,
            textDecoration: TextDecoration.underline,
          ),
          "img": Style(
            //margin: EdgeInsets.zero,
            //padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
        },
        onLinkTap: (url, _, __,) {
          if (url != null) launchUrl(Uri.parse(url));
        },
        shrinkWrap: true,
      );
    }

    return Text(
      textMessage,
      style: defaultStyle,
    );
  }

  // 处理图片URL，添加前缀
  String _processImageUrls(String html) {
    return html.replaceAllMapped(
      RegExp(r'<img\s+[^>]*src="([^"]+)"[^>]*>', caseSensitive: false),
          (match) {
        final imgTag = match.group(0)!;
        final src = match.group(1)!;

        // 如果已经是完整URL，直接返回
        if (src.startsWith('http://') || src.startsWith('https://')) {
          return imgTag;
        }

        // 添加前缀
        String fullUrl = 'https://uat-ccc.qylink.com:9991';
        if (!src.startsWith('/')) {
          fullUrl += '/';
        }
        fullUrl += src;

        // 替换原始src，并添加完整URL
        return imgTag.replaceFirst('src="$src"', 'src="$fullUrl"');
      },
    );
  }

  // 检测简单富文本标记（如 **粗体**）
  bool _containsSimpleRichText(String text) {
    //return text.contains('**') || text.contains('*') || text.contains('`');
    return true;
  }

  void _showDialog(BuildContext c) {
    showDialog(
      context: c,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('评价'),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: '请输入内容',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                // 处理确定按钮逻辑
                print('输入的内容: ${_textController.text}');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) {
      // 对话框关闭后清空输入框
      _textController.clear();
    });
  }



  EdgeInsetsGeometry? get _padding => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.padding
      : widget.inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.margin
      : widget.inComingChatBubbleConfig?.margin;

  LinkPreviewConfiguration? get _linkPreviewConfig => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.linkPreviewConfig
      : widget.inComingChatBubbleConfig?.linkPreviewConfig;

  TextStyle? get _textStyle => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.textStyle
      : widget.inComingChatBubbleConfig?.textStyle;

  BorderRadiusGeometry _borderRadius(String message) => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.borderRadius ??
      (message.length < 37
          ? BorderRadius.circular(replyBorderRadius1)
          : BorderRadius.circular(replyBorderRadius2))
      : widget.inComingChatBubbleConfig?.borderRadius ??
      (message.length < 29
          ? BorderRadius.circular(replyBorderRadius1)
          : BorderRadius.circular(replyBorderRadius2));

  Color get _color => widget.isMessageBySender
      ? widget.outgoingChatBubbleConfig?.color ?? Colors.purple
      : widget.inComingChatBubbleConfig?.color ?? Colors.grey.shade500;
}

// 富文本构建器类型定义
typedef InlineSpan = TextSpan;
typedef RichTextBuilder = InlineSpan? Function(Message message);