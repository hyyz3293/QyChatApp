import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessageWidget extends StatefulWidget {
  final String url;
  final bool isSentByMe;

  const AudioMessageWidget({
    super.key,
    required this.url,
    required this.isSentByMe,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isError = false;
  late AnimationController _animationController;
  List<double> _audioLevels = [0.3, 0.6, 0.4, 0.8, 0.5, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 监听音频位置变化
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    // 监听音频时长
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    // 监听播放状态
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
      if (state == PlayerState.playing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    });

    // // 监听错误
    // _audioPlayer.onPlayerError.listen((error) {
    //   if (mounted) setState(() {
    //     _isError = true;
    //     _isLoading = false;
    //   });
    // });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoading = true;
          _isError = false;
        });

        await _audioPlayer.play(UrlSource(widget.url));

        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = _playerState == PlayerState.playing;
    final bgColor = widget.isSentByMe
        ? theme.colorScheme.primary.withOpacity(0.1)
        : theme.colorScheme.secondary.withOpacity(0.1);

    // 计算进度百分比 (0.0 - 1.0)
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      constraints: const BoxConstraints(maxWidth: 250),
      color: Colors.red,
      height: 100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: widget.isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!widget.isSentByMe) ...[
            _buildAudioVisualizer(isPlaying),
            const SizedBox(width: 8),
          ],

          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(widget.isSentByMe ? 12 : 0),
                  bottomRight: Radius.circular(widget.isSentByMe ? 0 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 进度条
                  Container(
                    height: 2,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 时长和状态
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_isError)
                        const Icon(Icons.error, size: 16, color: Colors.red)
                      else
                        Text(
                          _formatDuration(_position),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(width: 8),

                      Text(
                        "| ${_formatDuration(_duration)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (widget.isSentByMe) ...[
            const SizedBox(width: 8),
            _buildAudioVisualizer(isPlaying),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer(bool isPlaying) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // 当播放时，声波动画会更活跃
        final animationValue = isPlaying ? _animationController.value : 0.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            // 计算每个声波条的高度（基础高度 + 动画效果）
            double height = _audioLevels[index] * 20;
            if (isPlaying) {
              // 添加动画效果，使声波条有波动感
              height += height * animationValue * (index % 2 == 0 ? 0.5 : -0.3);
            }

            return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 2,
            height: height,
            decoration: BoxDecoration(
            color: widget.isSentByMe
            ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            borderRadius: BorderRadius.circular(1),
            ));
          })
        );
      },
    );
  }
}