/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'dart:convert';
import 'dart:io';

import 'package:flutter_html/flutter_html.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/models.dart';
import 'package:qychatapp/presentation/utils/dio/dio_client.dart';
import 'package:qychatapp/presentation/ui/model/image_bean.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'reaction_widget.dart';
import 'share_icon.dart';

class ImageTxtMessageView extends StatelessWidget {
  const ImageTxtMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    this.imageMessageConfig,
    this.messageReactionConfig,
    this.highlightImage = false,
    this.highlightScale = 1.2,
  }) : super(key: key);

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration for image message appearance.
  final ImageMessageConfiguration? imageMessageConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents flag of highlighting image when user taps on replied image.
  final bool highlightImage;

  /// Provides scale of highlighted image when user taps on replied image.
  final double highlightScale;

  // 新增：图片+文本消息气泡背景色（与文本消息默认风格一致）
  Color get _bubbleColor => isMessageBySender ? Colors.purple : Colors.grey.shade500;

  // 获取图片列表
  List<ImageData> get imageList => message.imgs ?? [];

  // 获取标题
  String? get title => message.message;

  // 构建图片URL
  String _buildImageUrl(String code) {
    return '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}$code';
  }

  Widget get iconButton => ShareIcon(
    shareIconConfig: imageMessageConfig?.shareIconConfig,
    imageUrl: imageList.isNotEmpty ? _buildImageUrl(imageList.first.code) : '',
  );

  // 处理图片点击跳转
  Future<void> _onImageTap(ImageData imageData) async {
    if (imageData.href.isNotEmpty) {
      final Uri uri = Uri.parse(imageData.href);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('无法打开链接: ${imageData.href}');
      }
    }
  }

  // 打开全屏图片查看
  void _openFullScreenImage(BuildContext context, ImageData imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: Image.network(
                      _buildImageUrl(imageData.code),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // 构建单个图片组件
  Widget _buildImageWidget(BuildContext context, ImageData imageData) {
    return GestureDetector(
      onTap: () {
        // 长按打开全屏查看，点击跳转URL
        _onImageTap(imageData);
      },
      onLongPress: () {
        _openFullScreenImage(context, imageData);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          //border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _buildImageUrl(imageData.code),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                //color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 构建图片网格
  Widget _buildImageGrid(BuildContext context) {
    if (imageList.isEmpty) {
      return const SizedBox.shrink();
    }

    // 根据图片数量决定网格布局
    int crossAxisCount;
    double childAspectRatio;
    double imageHeight;

    if (imageList.length == 1) {
      crossAxisCount = 1;
      childAspectRatio = 1.2;
      imageHeight = 200;
    } else if (imageList.length == 2) {
      crossAxisCount = 2;
      childAspectRatio = 1.0;
      imageHeight = 150;
    } else if (imageList.length <= 4) {
      crossAxisCount = 2;
      childAspectRatio = 1.0;
      imageHeight = 120;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
      imageHeight = 100;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: imageHeight * ((imageList.length + crossAxisCount - 1) / crossAxisCount).ceil(),
        maxWidth: imageMessageConfig?.width ?? MediaQuery.of(context).size.width * 0.6,
      ),
      //color: Colors.red,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return _buildImageWidget(context, imageList[index]);
        },
      ),
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
  // 构建标题组件
  Widget _buildTitle() {
    if (title == null || title!.isEmpty) {
      return const SizedBox.shrink();
    }

    final processedHtml = _processImageUrls(title!);

    return Html(
      data: processedHtml,
      style: {
        "body": Style(
          fontSize: FontSize(16.0),
          color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    if (imageList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // if (isMessageBySender && !(imageMessageConfig?.hideShareIcon ?? false))
        //   iconButton,
        Stack(
          children: [
            GestureDetector(
              onTap: () => imageMessageConfig?.onTap != null
                  ? imageMessageConfig?.onTap!(message)
                  : null,
              child: Transform.scale(
                scale: highlightImage ? highlightScale : 1.0,
                alignment: isMessageBySender
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: imageMessageConfig?.padding ?? const EdgeInsets.all(8),
                  margin: imageMessageConfig?.margin ??
                      EdgeInsets.only(
                        top: 6,
                        right: isMessageBySender ? 6 : 0,
                        left: isMessageBySender ? 0 : 6,
                        bottom: message.reaction.reactions.isNotEmpty ? 15 : 0,
                      ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffb9cfe3),
                    borderRadius: imageMessageConfig?.borderRadius ??
                        BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageGrid(context),
                      _buildTitle(),
                    ],
                  ),
                ),
              ),
            ),
            if (message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                isMessageBySender: isMessageBySender,
                reaction: message.reaction,
                messageReactionConfig: messageReactionConfig,
              ),
          ],
        ),
        // if (!isMessageBySender && !(imageMessageConfig?.hideShareIcon ?? false))
        //   iconButton,
      ],
    );
  }
}