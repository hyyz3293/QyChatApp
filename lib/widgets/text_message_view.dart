import 'package:flutter/material.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/models.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';

class TextMessageView extends StatefulWidget {
  const TextMessageView({
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
  State<TextMessageView> createState() => _TextMessageViewState();
}

class _TextMessageViewState extends State<TextMessageView> {
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
              maxWidth:
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
                : _buildTextContent(textTheme, textMessage, richText),
          ),
        if (widget.message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            key: widget.key,
            isMessageBySender: widget.isMessageBySender,
            reaction: widget.message.reaction,
            messageReactionConfig: widget.messageReactionConfig,
          ),
      ],
    );
  }

  // 构建文本内容（支持富文本或普通文本）
  Widget _buildTextContent(TextTheme textTheme, String textMessage, InlineSpan? richText) {
    final defaultStyle = _textStyle ?? textTheme.bodyMedium!.copyWith(
      color: Colors.black,
      fontSize: 16,
    );

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
            color: Colors.black,
            textDecoration: TextDecoration.underline,
          ),
          "img": Style(
            //margin: EdgeInsets.zero,
            //padding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
        },
        extensions: [
          TagExtension(
            tagsToExtend: {"img"},
            builder: (extensionContext) {
              final src = extensionContext.attributes['src'];
              if (src != null) {
                return GestureDetector(
                  onTap: () => _showImageDialog(src),
                  child: Image.network(
                    src,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
        String fullUrl = 'https://uat-ccc.qylink.com:7100';
        if (!src.startsWith('/')) {
          fullUrl += '/';
        }
        fullUrl += src;
        print("===-====${fullUrl}");

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

  // 显示图片放大对话框
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // 点击背景关闭
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              // 图片内容
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 富文本构建器类型定义
typedef InlineSpan = TextSpan;
typedef RichTextBuilder = InlineSpan? Function(Message message);