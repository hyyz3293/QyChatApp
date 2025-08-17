import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:qychatapp/widgets/reaction_widget.dart';
import 'package:qychatapp/widgets/share_icon.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

import '../models/config_models/image_message_configuration.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../models/data_models/message.dart';

class VideoMessageView extends StatefulWidget {
  const VideoMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    this.videoMessageConfig,
    this.messageReactionConfig,
    this.highlightVideo = false,
    this.highlightScale = 1.2,
  }) : super(key: key);

  final Message message;
  final bool isMessageBySender;
  final VideoMessageConfiguration? videoMessageConfig;
  final MessageReactionConfiguration? messageReactionConfig;
  final bool highlightVideo;
  final double highlightScale;

  @override
  State<VideoMessageView> createState() => _VideoMessageViewState();
}

class _VideoMessageViewState extends State<VideoMessageView> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Timer? _hideControlsTimer;
  bool _showFullScreenControls = true;

  String get videoUrl => widget.message.message;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    print("_initializeVideoPlayer ${videoUrl}");
    if (videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.network(videoUrl);
    } else if (videoUrl.fromMemory) {
      // 处理 base64 视频
      final data = base64Decode(videoUrl.substring(videoUrl.indexOf('base64') + 7));
      _controller = VideoPlayerController.file(File.fromRawPath(data));
    } else {
      _controller = VideoPlayerController.file(File(videoUrl));
    }

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
        _startHideControlsTimer();
      } else {
        _controller.pause();
        _cancelHideControlsTimer();
      }
    });
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() {
        _showFullScreenControls = false;
      });
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  Widget get _videoPlayerWidget {
    if (!_isInitialized) {
      return Container(
        height: widget.videoMessageConfig?.height ?? 200,
        width: widget.videoMessageConfig?.width ?? 150,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final aspectRatio = _controller.value.aspectRatio;
    return GestureDetector(
      onTap: _togglePlayPause,
      onLongPress: () => widget.videoMessageConfig?.onLongPress?.call(widget.message),
      onDoubleTap: _toggleFullScreen,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
            child: VideoPlayer(_controller),
          ),
          if (!_isPlaying || _hideControlsTimer == null || _showFullScreenControls)
            AnimatedOpacity(
              opacity: _isPlaying ? 0.7 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            bottom: 5,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.fullscreen, color: Colors.white, size: 20),
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFullScreen() {
    if (!_isInitialized) return;

    // 取消控制条隐藏计时器
    _cancelHideControlsTimer();

    // 显示控制条
    setState(() {
      _showFullScreenControls = true;
    });

    // 进入全屏模式
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.fullscreen_exit, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (!_isPlaying)
                  Center(
                    child: IconButton(
                      icon: Icon(Icons.play_arrow, size: 50, color: Colors.white),
                      onPressed: _togglePlayPause,
                    ),
                  ),
              ],
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // 返回时恢复播放状态
      if (_isPlaying) {
        _startHideControlsTimer();
      }

      // 锁定竖屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    });

    // 允许横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Widget get iconButton => ShareIcon(
    shareIconConfig: widget.videoMessageConfig?.shareIconConfig,
    imageUrl: videoUrl,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
      widget.isMessageBySender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (widget.isMessageBySender &&
            !(widget.videoMessageConfig?.hideShareIcon ?? false)) iconButton,
        Stack(
          children: [
            GestureDetector(
              onTap: () => widget.videoMessageConfig?.onTap?.call(widget.message),
              child: Transform.scale(
                scale: widget.highlightVideo ? widget.highlightScale : 1.0,
                alignment: widget.isMessageBySender
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: widget.videoMessageConfig?.padding ?? EdgeInsets.zero,
                  margin: widget.videoMessageConfig?.margin ??
                      EdgeInsets.only(
                        top: 6,
                        right: widget.isMessageBySender ? 6 : 0,
                        left: widget.isMessageBySender ? 0 : 6,
                        bottom: widget.message.reaction.reactions.isNotEmpty ? 15 : 0,
                      ),
                  height: widget.videoMessageConfig?.height ?? 200,
                  width: widget.videoMessageConfig?.width ?? 150,
                  child: ClipRRect(
                    borderRadius: widget.videoMessageConfig?.borderRadius ??
                        BorderRadius.circular(14),
                    child: _videoPlayerWidget,
                  ),
                ),
              ),
            ),
            if (widget.message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                isMessageBySender: widget.isMessageBySender,
                reaction: widget.message.reaction,
                messageReactionConfig: widget.messageReactionConfig,
              ),
          ],
        ),
        if (!widget.isMessageBySender &&
            !(widget.videoMessageConfig?.hideShareIcon ?? false)) iconButton,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _cancelHideControlsTimer();
    super.dispose();
  }
}

// 视频消息配置类
class VideoMessageConfiguration {
  const VideoMessageConfiguration({
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius,
    this.hideShareIcon = false,
    this.onTap,
    this.onLongPress,
    this.shareIconConfig,
  });

  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final bool hideShareIcon;
  final Function(Message)? onTap;
  final Function(Message)? onLongPress;
  final ShareIconConfiguration? shareIconConfig;
}

// 扩展方法用于检测 base64 视频
extension StringExtensions on String {
  bool get fromMemory => contains('base64');
}