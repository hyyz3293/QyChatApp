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

import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/models.dart';
import 'package:flutter/material.dart';

import 'reaction_widget.dart';
import 'share_icon.dart';

class ImageMessageView extends StatelessWidget {
  const ImageMessageView({
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

  String get imageUrl => message.message;

  // 新增：图片消息气泡背景色（与文本消息默认风格一致）
  Color get _bubbleColor => isMessageBySender ? Colors.purple : Colors.grey.shade500;

  Widget get iconButton => ShareIcon(
    shareIconConfig: imageMessageConfig?.shareIconConfig,
    imageUrl: imageUrl,
  );

  void _openFullScreenImage(BuildContext context) {
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
                      child: _buildFullScreenImage()),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
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

  Widget _buildFullScreenImage() {
    if (imageUrl.isUrl) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
      );
    } else if (imageUrl.fromMemory) {
      return Image.memory(
        base64Decode(imageUrl.substring(imageUrl.indexOf('base64') + 7)),
        fit: BoxFit.contain,
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildImageWidget(BuildContext c) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(c),
      child: (() {
        if (imageUrl.isUrl) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover, // 改为cover以填满背景
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          );
        } else if (imageUrl.fromMemory) {
          return Image.memory(
            base64Decode(imageUrl.substring(imageUrl.indexOf('base64') + 7)),
            fit: BoxFit.cover, // 改为cover以填满背景
          );
        } else {
          return Image.file(
            File(imageUrl),
            fit: BoxFit.cover, // 改为cover以填满背景
          );
        }
      }()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
      isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
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
                  height: imageMessageConfig?.height ?? 200,
                  width: imageMessageConfig?.width ?? MediaQuery.of(context).size.width * 0.4,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffb9cfe3),
                    borderRadius: imageMessageConfig?.borderRadius ?? BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: imageMessageConfig?.borderRadius ?? BorderRadius.circular(14),
                    child: _buildImageWidget(context),
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