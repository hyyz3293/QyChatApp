import 'package:flutter/material.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/models.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';

class TextComplexMessageView extends StatelessWidget {
  const TextComplexMessageView({
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textMessage = message.message;

    // 获取富文本内容（如果可用）
    final richText = richTextBuilder?.call(message);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
            constraints: BoxConstraints(
                maxWidth: chatBubbleMaxWidth ??
                    MediaQuery.of(context).size.width * 0.75),
            padding: _padding ??
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
            margin: _margin ??
                EdgeInsets.fromLTRB(
                    5, 0, 6, message.reaction.reactions.isNotEmpty ? 15 : 2),
            decoration: BoxDecoration(
              color: highlightMessage ? highlightColor : _color,
              borderRadius: _borderRadius(textMessage),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  child: Text("${message.complex!.title}", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),),
                ),
                SizedBox(height: 10,),
                textMessage.isUrl
                    ? LinkPreview(
                  linkPreviewConfig: _linkPreviewConfig,
                  url: textMessage,
                )
                    : GestureDetector(
                  onTap: () {
                    // if (message.digest != "") {
                    //   if (message.digest != null) launchUrl(Uri.parse(message.digest));
                    // }
                  },
                  child:_buildTextContent(textTheme, textMessage, richText),
                ),
              ],
            )
        ),
        if (message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            key: key,
            isMessageBySender: isMessageBySender,
            reaction: message.reaction,
            messageReactionConfig: messageReactionConfig,
          ),
      ],
    );
  }

  // 构建文本内容（支持富文本或普通文本）
  Widget _buildTextContent(TextTheme textTheme, String textMessage, InlineSpan? richText) {
    final defaultStyle = _textStyle ?? textTheme.bodyMedium!.copyWith(
      color: Colors.grey,
      fontSize: 16,
    );
    // 检测并处理简单富文本标记
    if (_containsSimpleRichText(textMessage)) {
      // 处理图片路径 - 添加前缀
      final processedHtml = _processImageUrls(message.complex!.content);
      if (message.digest != "") {
        _processImageUrls(message.digest!);
      }
      return Html(
        data: processedHtml,
        style: {
          "body": Style(
            fontSize: FontSize(16.0),
            color: Colors.grey,
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

  // 解析简单富文本标记
  Widget _parseSimpleRichText(String text, TextStyle defaultStyle) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    bool isBold = false;
    bool isItalic = false;
    bool isCode = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // 处理粗体标记
      if (char == '*' && i + 1 < text.length && text[i + 1] == '*') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: _getCurrentStyle(defaultStyle, isBold, isItalic, isCode),
          ));
          buffer.clear();
        }
        isBold = !isBold;
        i++; // 跳过下一个星号
        continue;
      }

      // 处理斜体标记
      if (char == '*') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: _getCurrentStyle(defaultStyle, isBold, isItalic, isCode),
          ));
          buffer.clear();
        }
        isItalic = !isItalic;
        continue;
      }

      // 处理代码标记
      if (char == '`') {
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: _getCurrentStyle(defaultStyle, isBold, isItalic, isCode),
          ));
          buffer.clear();
        }
        isCode = !isCode;
        continue;
      }

      buffer.write(char);
    }

    // 添加剩余文本
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(
        text: buffer.toString(),
        style: _getCurrentStyle(defaultStyle, isBold, isItalic, isCode),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  // 获取当前文本样式
  TextStyle _getCurrentStyle(
      TextStyle baseStyle,
      bool isBold,
      bool isItalic,
      bool isCode,
      ) {
    return baseStyle.copyWith(
      fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
      fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
      backgroundColor: isCode ? Colors.grey[800] : null,
      fontFamily: isCode ? 'monospace' : baseStyle.fontFamily,
    );
  }

  EdgeInsetsGeometry? get _padding => isMessageBySender
      ? outgoingChatBubbleConfig?.padding
      : inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => isMessageBySender
      ? outgoingChatBubbleConfig?.margin
      : inComingChatBubbleConfig?.margin;

  LinkPreviewConfiguration? get _linkPreviewConfig => isMessageBySender
      ? outgoingChatBubbleConfig?.linkPreviewConfig
      : inComingChatBubbleConfig?.linkPreviewConfig;

  TextStyle? get _textStyle => isMessageBySender
      ? outgoingChatBubbleConfig?.textStyle
      : inComingChatBubbleConfig?.textStyle;

  BorderRadiusGeometry _borderRadius(String message) => isMessageBySender
      ? outgoingChatBubbleConfig?.borderRadius ??
      (message.length < 37
          ? BorderRadius.circular(replyBorderRadius1)
          : BorderRadius.circular(replyBorderRadius2))
      : inComingChatBubbleConfig?.borderRadius ??
      (message.length < 29
          ? BorderRadius.circular(replyBorderRadius1)
          : BorderRadius.circular(replyBorderRadius2));

  Color get _color => isMessageBySender
      ? outgoingChatBubbleConfig?.color ?? Colors.purple
      : inComingChatBubbleConfig?.color ?? Colors.grey.shade500;
}

// 富文本构建器类型定义
typedef InlineSpan = TextSpan;
typedef RichTextBuilder = InlineSpan? Function(Message message);