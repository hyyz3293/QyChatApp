import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:qychatapp/controller/chat_controller.dart';
import 'package:qychatapp/extensions/extensions.dart';
import 'package:qychatapp/models/config_models/feature_active_config.dart';
import 'package:qychatapp/models/config_models/message_list_configuration.dart';
import 'package:qychatapp/models/config_models/suggestion_list_config.dart';
import 'package:qychatapp/models/data_models/message.dart';
import 'package:qychatapp/models/data_models/reply_message.dart';
import 'package:qychatapp/values/enumeration.dart';
import 'package:qychatapp/values/typedefs.dart';
import 'package:qychatapp/widgets/suggestions/suggestion_list.dart';
import 'package:qychatapp/widgets/type_indicator_widget.dart';
import 'package:qychatapp/widgets/reaction_widget.dart';
import 'package:dio/dio.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_bubble.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../models/config_models/voice_message_configuration.dart';
import '../presentation/utils/service_locator.dart';
import 'chatui_textfield.dart';

class VoiceMessageView extends StatefulWidget {
  const VoiceMessageView({
    Key? key,
    required this.screenWidth,
    required this.message,
    required this.isMessageBySender,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.onMaxDuration,
    this.messageReactionConfig,
    this.config,
  }) : super(key: key);

  /// Provides configuration related to voice message.
  final VoiceMessageConfiguration? config;

  /// Allow user to set width of chat bubble.
  final double screenWidth;

  /// Provides message instance of chat.
  final Message message;
  final Function(int)? onMaxDuration;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  @override
  State<VoiceMessageView> createState() => _VoiceMessageViewState();
}

class _VoiceMessageViewState extends State<VoiceMessageView> {
  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;
  final ValueNotifier<PlayerState> _playerState = ValueNotifier(PlayerState.stopped);
  PlayerWaveStyle playerWaveStyle = const PlayerWaveStyle(scaleFactor: 70);

  // 新增状态变量
  bool _isLoading = false; // 是否正在下载
  bool _isCurrentlyPlaying = false; // 当前是否正在播放
  bool _shouldAutoPlay = false; // 是否需要自动播放
  double _downloadProgress = 0;
  String? _localFilePath; // 下载后的本地文件路径
  CancelToken? _downloadToken; // 用于取消下载

  PlayerState get playerState => _playerState.value;

  late StreamSubscription<String> _audioSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _audioSubscription = getIt<EventBus>().on<String>().listen((event) {
      if (event == "audio")
        controller.stopPlayer();
    });
  }

  // 新增方法：初始化播放器
  Future<void> _initializePlayer() async {
    final path = widget.message.message;

    // 检查是否为网络URL
    if (path.startsWith('http')) {
      setState(() => _isLoading = true);
      try {
        _localFilePath = await _downloadAudio(path);
        _preparePlayer(_localFilePath!);
      } catch (e) {
        print('音频下载失败: $e');
        setState(() => _isLoading = false);
        // 这里可以添加错误处理UI
      }
    } else {
      // 本地文件直接播放
      _preparePlayer(path);
    }
  }

  // 新增方法：下载音频文件
  Future<String> _downloadAudio(String url) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = url.substring(url.lastIndexOf('/') + 1);
    final savePath = '${tempDir.path}/$fileName';

    // 如果文件已存在，直接使用
    if (File(savePath).existsSync()) {
      return savePath;
    }

    // 创建下载取消令牌
    _downloadToken = CancelToken();

    await Dio().download(
      url,
      savePath,
      cancelToken: _downloadToken,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress = received / total;
          });
        }
      },
    );

    return savePath;
  }

  // 准备播放器
  void _preparePlayer(String path) {
    controller = PlayerController()
      ..preparePlayer(
        path: path,
        noOfSamples: widget.config?.playerWaveStyle
            ?.getSamplesForWidth(widget.screenWidth * 0.5) ??
            playerWaveStyle.getSamplesForWidth(widget.screenWidth * 0.5),
      ).whenComplete(() {
        widget.onMaxDuration?.call(controller.maxDuration);
        setState(() => _isLoading = false);
      });

    playerStateSubscription = controller.onPlayerStateChanged
        .listen((state) {
          setState(() {
            _playerState.value = state;
          });
          print("播放器状态变化: $state");
          
          // 当播放器初始化完成时，如果需要自动播放则开始播放
          if (state == PlayerState.initialized && _shouldAutoPlay) {
            print("播放器已初始化，开始自动播放...");
            _shouldAutoPlay = false; // 重置标志
            try {
              controller.startPlayer();
              print("自动播放启动成功");
            } catch (e) {
              print("自动播放启动失败: $e");
            }
          }
          
          // 根据播放器状态更新_isCurrentlyPlaying
          if (state == PlayerState.playing) {
            setState(() {
              _isCurrentlyPlaying = true;
            });
            print("开始播放，_isCurrentlyPlaying设为true");
          } else if (state == PlayerState.paused || state == PlayerState.stopped) {
            setState(() {
              _isCurrentlyPlaying = false;
            });
            print("暂停/停止播放，_isCurrentlyPlaying设为false");
          }
          
          // 播放完成后重新准备播放器，确保下次能正常播放
          if (state == PlayerState.stopped) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted && _localFilePath != null) {
                print("播放完成，重新准备播放器");
                // 重新准备播放器
                controller.preparePlayer(
                  path: _localFilePath!,
                  noOfSamples: widget.config?.playerWaveStyle
                      ?.getSamplesForWidth(widget.screenWidth * 0.5) ??
                      playerWaveStyle.getSamplesForWidth(widget.screenWidth * 0.5),
                );
              }
            });
          }
        });
  }

  @override
  void dispose() {
    _audioSubscription.cancel();
    playerStateSubscription.cancel();
    controller.dispose();
    _playerState.dispose();
    // 取消进行中的下载
    _downloadToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 下载进度指示器
        if (_isLoading) _buildDownloadProgress(),

        // 音频播放器
        if (!_isLoading || _localFilePath != null) _buildAudioPlayer(),

        // 反应组件
        if (widget.message.reaction.reactions.isNotEmpty)
          ReactionWidget(
            isMessageBySender: widget.isMessageBySender,
            reaction: widget.message.reaction,
            messageReactionConfig: widget.messageReactionConfig,
          ),
      ],
    );
  }

  // 构建音频播放器
  Widget _buildAudioPlayer() {
    return Container(
      decoration: widget.config?.decoration ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isMessageBySender
                ? widget.outgoingChatBubbleConfig?.color
                : widget.inComingChatBubbleConfig?.color,
          ),
      padding: widget.config?.padding ??
          const EdgeInsets.symmetric(horizontal: 8),
      margin: widget.config?.margin ??
          EdgeInsets.symmetric(
            horizontal: 8,
            vertical: widget.message.reaction.reactions.isNotEmpty ? 15 : 0,
          ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<PlayerState>(
            builder: (context, state, child) {
              return IconButton(
                onPressed: _playOrPause,
                icon: state.isStopped || state.isPaused || state.isInitialised
                    ? widget.config?.playIcon ??
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    )
                    : widget.config?.pauseIcon ??
                    const Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
              );
            },
            valueListenable: _playerState,
          ),
          AudioFileWaveforms(
            size: Size(widget.screenWidth * 0.50, 60),
            playerController: controller,
            waveformType: WaveformType.fitWidth,
            playerWaveStyle:
            widget.config?.playerWaveStyle ?? playerWaveStyle,
            padding: widget.config?.waveformPadding ??
                const EdgeInsets.only(right: 10),
            margin: widget.config?.waveformMargin,
            animationCurve: widget.config?.animationCurve ?? Curves.easeIn,
            animationDuration: widget.config?.animationDuration ??
                const Duration(milliseconds: 500),
            enableSeekGesture: widget.config?.enableSeekGesture ?? true,
          ),
        ],
      ),
    );
  }

  // 构建下载进度指示器
  Widget _buildDownloadProgress() {
    return Container(
      width: widget.screenWidth * 0.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey[600],
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isMessageBySender
                  ? widget.outgoingChatBubbleConfig?.color ?? Colors.blue
                  : widget.inComingChatBubbleConfig?.color ?? Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '下载音频中: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _playOrPause() {
    assert(
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android,
    "Voice messages are only supported with android and ios platform",
    );
    
    print("当前播放器状态: ${playerState.name}");
    print("音频文件路径: $_localFilePath");
    print("播放器是否已初始化: ${playerState.isInitialised}");
    print("播放器是否暂停: ${playerState.isPaused}");
    print("播放器是否停止: ${playerState.isStopped}");
    
    if (playerState.isPlaying) {
      print("准备暂停播放...");
      try {
        controller.pausePlayer();
        print("pausePlayer调用成功");
      } catch (e) {
        print("pausePlayer调用失败: $e");
      }
    } else {
      // 如果播放器未初始化，先准备播放器
      if (!playerState.isInitialised && _localFilePath != null) {
        print("播放器未初始化，先准备播放器...");
        _shouldAutoPlay = true; // 设置自动播放标志
        _preparePlayer(_localFilePath!);
      } else {
        print("准备开始播放...");
        try {
          controller.startPlayer();
          print("startPlayer调用成功");
        } catch (e) {
          print("startPlayer调用失败: $e");
          setState(() {
            _isCurrentlyPlaying = false;
          });
        }
      }
    }
  }
}
