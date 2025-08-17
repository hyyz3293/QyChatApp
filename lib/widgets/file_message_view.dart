import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:boilerplate/widgets/reaction_widget.dart';
import 'package:boilerplate/widgets/share_icon.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/config_models/image_message_configuration.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../models/data_models/message.dart';

class FileMessageView extends StatefulWidget {
  const FileMessageView({
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
  State<FileMessageView> createState() => _VideoMessageViewState();
}

class _VideoMessageViewState extends State<FileMessageView> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Timer? _hideControlsTimer;

  String get videoUrl => widget.message.message;

  // 判断是否是视频消息
  bool get _isVideo {
    final uri = Uri.tryParse(videoUrl);
    final path = uri?.path ?? videoUrl;
    final extension = path.split('.').last.toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.webm']
        .contains('.$extension');
  }

  // 获取文件名
  String get _fileName {
    final uri = Uri.tryParse(videoUrl);
    final path = uri?.path ?? videoUrl;
    return path.split('/').last;
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    if (videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.network(videoUrl);
    } else if (videoUrl.fromMemory) {
      // 处理 base64 视频（通常不推荐，但提供实现）
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
      if (mounted) setState(() {});
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  // // 打开文件
  // void _openFile() {
  //   print("_openFile");
  //   if (widget.videoMessageConfig?.onFileTap != null) {
  //     widget.videoMessageConfig!.onFileTap!(widget.message);
  //   }
  //   final filePath = widget.message.message; // 假设消息中包含文件路径
  //   OpenFile.open(filePath); // 使用 open_file 插件
  // }

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
            child: VideoPlayer(_controller),
          ),
          if (!_isPlaying || _hideControlsTimer == null)
            AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0,
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
        ],
      ),
    );
  }

  // 文件展示组件
  Widget get _fileWidget {
    return GestureDetector(
      onTap: _openFile,
      onLongPress: () => widget.videoMessageConfig?.onLongPress?.call(widget.message),
      child: Container(
        height: widget.videoMessageConfig?.height ?? 200,
        width: widget.videoMessageConfig?.width ?? 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: widget.videoMessageConfig?.borderRadius ?? BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              _fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              '点击查看文件',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: _isVideo ? _videoPlayerWidget : _fileWidget,
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
    if (_isVideo) {
      _controller.dispose();
    }
    _cancelHideControlsTimer();
    super.dispose();
  }



// 处理文件打开（自动处理本地文件/网络文件）
  Future<void> openOrDownloadFile(String filePath) async {
    // 情况1：本地文件路径
    if (await File(filePath).exists()) {
      await OpenFile.open(filePath);
      return;
    }

    // 情况2：网络链接
    if (filePath.startsWith('http')) {
      await _downloadAndOpen(filePath);
      return;
    }

    // 情况3：无效路径
    throw Exception('文件不存在或路径无效: $filePath');
  }

// 下载并打开网络文件
  Future<void> _downloadAndOpen(String url) async {
    try {
      // 创建临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName = url.substring(url.lastIndexOf('/') + 1);
      final savePath = '${tempDir.path}/$fileName';

      // 显示下载进度（可选）
      _showDownloadProgress();

      // 使用Dio下载文件
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            _updateProgress(progress); // 更新UI进度
          }
        },
      );

      // 打开下载的文件
      await OpenFile.open(savePath);

    } catch (e) {
      throw Exception('文件下载失败: ${e.toString()}');
    } finally {
      _hideProgress(); // 关闭进度显示
    }
  }

// 在你的组件中调用
  void _openFile() {

    print("_openFile");
    if (widget.videoMessageConfig?.onFileTap != null) {
      widget.videoMessageConfig!.onFileTap!(widget.message);
    }

    final filePath = widget.message.message; // 获取文件路径

    // 显示加载指示器
    // setState(() => _isLoading = true);

    openOrDownloadFile(filePath).catchError((error) {
      // 错误处理
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文件失败: $error'))
      );
    }).whenComplete(() {
      // setState(() => _isLoading = false);
    });
  }

// 进度显示方法（示例）
  void _showDownloadProgress() {
    // 实现你的进度显示UI（如：弹窗+进度条）
  }

  void _updateProgress(String percent) {
    // 更新进度显示
  }

  void _hideProgress() {
    // 隐藏进度显示
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
    this.onFileTap, // 新增文件点击回调
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
  final Function(Message)? onFileTap; // 用于处理文件点击事件
  final ShareIconConfiguration? shareIconConfig;
}

// 扩展方法用于检测 base64 视频
extension StringExtensions on String {
  bool get fromMemory => contains('base64');
}