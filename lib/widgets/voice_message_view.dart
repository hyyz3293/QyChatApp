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
  PlayerWaveStyle playerWaveStyle = const PlayerWaveStyle(scaleFactor: 70,
      fixedWaveColor: Colors.grey,
      liveWaveColor: Colors.black12);

  // 新增状态变量
  bool _isLoading = false; // 是否正在下载
  bool _isCurrentlyPlaying = false; // 当前是否正在播放
  bool _shouldAutoPlay = false; // 是否需要自动播放
  double _downloadProgress = 0;
  String? _localFilePath; // 下载后的本地文件路径
  CancelToken? _downloadToken;

  // 强制重建 AudioFileWaveforms 的 key
  Key? _waveformKey; // 用于取消下载

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
        await _preparePlayer(_localFilePath!);
      } catch (e) {
        print('音频下载失败: $e');
        setState(() => _isLoading = false);
        // 这里可以添加错误处理UI
      }
    } else {
      // 本地文件直接播放
      _localFilePath = path; // 确保本地文件路径也被保存
      await _preparePlayer(path);
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
  Future<void> _preparePlayer(String path) async {
    // 先校验文件存在且非空
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      print('音频文件无效，跳过 preparePlayer: $path');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    // 生成唯一 key，强制重建 AudioFileWaveforms
    _waveformKey = ValueKey('${file.path}_${DateTime.now().millisecondsSinceEpoch}');

    controller = PlayerController()
      ..preparePlayer(
        path: path,
        noOfSamples: widget.config?.playerWaveStyle
            ?.getSamplesForWidth(widget.screenWidth * 0.5) ??
            playerWaveStyle.getSamplesForWidth(widget.screenWidth * 0.5) ??
            100,
        // playerWaveStyle: const PlayerWaveStyle(
        //   scaleFactor: 70,
        //   liveWaveColor: Colors.grey,   // 强制灰色
        //   showBottom: false,
        // ),
      ).whenComplete(() {
        widget.onMaxDuration?.call(controller.maxDuration);
        setState(() => _isLoading = false);
      });

    playerStateSubscription = controller.onPlayerStateChanged
        .listen((state) {
          setState(() {
            _playerState.value = state;
          });
          
          // 当播放器初始化完成时，如果需要自动播放则开始播放
          if (state == PlayerState.initialized && _shouldAutoPlay) {
            _shouldAutoPlay = false; // 重置标志
            try {
              controller.startPlayer();
            } catch (e) {
            }
          }
          
          // 根据播放器状态更新_isCurrentlyPlaying
          if (state == PlayerState.playing) {
            setState(() {
              _isCurrentlyPlaying = true;
            });
          } else if (state == PlayerState.paused || state == PlayerState.stopped) {
            setState(() {
              _isCurrentlyPlaying = false;
            });
          }
          
          // 播放完成后重置播放器状态，确保下次能正常播放
          if (state == PlayerState.stopped) {
            setState(() {
              _isCurrentlyPlaying = false;
            });
            // 不再自动 seekTo(0)，保留当前进度以便继续播放
          }
          
          // 当播放器暂停时，保留当前位置以便继续播放
          if (state == PlayerState.paused) {
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
    if (_waveformKey == null) {
      return SizedBox(
        width: widget.screenWidth * 0.5,
        height: 70,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
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
                          color: Colors.grey,
                        )
                    : widget.config?.pauseIcon ??
                        const Icon(
                          Icons.stop,
                          color: Colors.grey,
                        ),
              );
            },
            valueListenable: _playerState,
          ),
          AudioFileWaveforms(
            key: _waveformKey!,
            size: Size(widget.screenWidth * 0.50, 60),
            playerController: controller,
            waveformType: WaveformType.fitWidth,
            playerWaveStyle: playerWaveStyle,
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
    
    if (playerState.isPlaying) {
      try {
        controller.pausePlayer();
      } catch (e) {
      }
    } else {
      // 如果播放器未初始化，先准备播放器
      if (!playerState.isInitialised && _localFilePath != null) {
        _shouldAutoPlay = true; // 设置自动播放标志
        _preparePlayer(_localFilePath!);
      } else {
        try {
          controller.startPlayer();
        } catch (e) {
          setState(() {
            _isCurrentlyPlaying = false;
          });
        }
      }
    }
  }
}
