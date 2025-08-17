// import 'package:flutter/material.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import 'package:video_player/video_player.dart';
// import 'dart:io';
//
// class ChatVideoMessage extends StatefulWidget {
//   final VideoMessage message;
//   final bool isSentByMe;
//
//   const ChatVideoMessage({
//     super.key,
//     required this.message,
//     required this.isSentByMe,
//   });
//
//   @override
//   State<ChatVideoMessage> createState() => _ChatVideoMessageState();
// }
//
// class _ChatVideoMessageState extends State<ChatVideoMessage> {
//   late VideoPlayerController _controller;
//   bool _isPlaying = false;
//   bool _isLoading = true; // 初始化为 true
//   bool _showControls = false;
//   bool _isFullScreen = false;
//   double _playbackPosition = 0.0;
//   Duration _videoDuration = Duration.zero; // 使用 Duration 类型
//
//   @override
//   void initState() {
//     super.initState();
//
//     // 初始化视频控制器
//     _controller = VideoPlayerController.file(File(widget.message.source))
//       ..initialize().then((_) {
//         setState(() {
//           _isLoading = false;
//           _videoDuration = _controller.value.duration; // 获取视频时长
//           _controller.addListener(_updatePlaybackPosition);
//         });
//       }).catchError((e) {
//         setState(() {
//           _isLoading = false;
//           _videoDuration = Duration.zero;
//         });
//         print('视频初始化失败: $e');
//       });
//   }
//
//   void _updatePlaybackPosition() {
//     if (_controller.value.isInitialized) {
//       setState(() {
//         _playbackPosition = _controller.value.position.inMilliseconds /
//             _controller.value.duration.inMilliseconds;
//       });
//     }
//   }
//
//   void _togglePlayback() async {
//     if (!_controller.value.isInitialized) {
//       setState(() => _isLoading = true);
//       try {
//         await _controller.initialize();
//         setState(() {
//           _isLoading = false;
//           _videoDuration = _controller.value.duration; // 再次获取时长
//         });
//       } catch (e) {
//         setState(() => _isLoading = false);
//         print('播放失败: $e');
//       }
//     }
//
//     if (_isPlaying) {
//       await _controller.pause();
//     } else {
//       await _controller.play();
//     }
//
//     setState(() {
//       _isPlaying = !_isPlaying;
//       _showControls = true;
//     });
//   }
//
//   void _toggleFullScreen() {
//     if (_isFullScreen) {
//       Navigator.pop(context);
//     } else {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => _FullScreenVideoPlayer(
//             controller: _controller,
//             isPlaying: _isPlaying,
//           ),
//         ),
//       );
//     }
//     setState(() => _isFullScreen = !_isFullScreen);
//   }
//
//   String _formatDuration(Duration duration) {
//     if (duration == Duration.zero) return "00:00";
//
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
//
//   @override
//   void dispose() {
//     _controller.removeListener(_updatePlaybackPosition);
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final bgColor = widget.isSentByMe
//         ? theme.colorScheme.primary.withOpacity(0.1)
//         : theme.colorScheme.secondary.withOpacity(0.1);
//
//     return GestureDetector(
//       onTap: _togglePlayback,
//       onLongPress: () => setState(() => _showControls = !_showControls),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.7,
//         ),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(12),
//             topRight: const Radius.circular(12),
//             bottomLeft: Radius.circular(widget.isSentByMe ? 12 : 0),
//             bottomRight: Radius.circular(widget.isSentByMe ? 0 : 12),
//           ),
//         ),
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // 视频播放器 - 小窗口播放
//             if (_isPlaying && !_isFullScreen && _controller.value.isInitialized)
//               AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             else
//             // 视频缩略图 - 使用本地文件
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: widget.message.source != null && widget.message.source!.isNotEmpty
//                     ? Image.file(
//                   File(widget.message.source!),
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   height: 200,
//                   errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
//                 )
//                     : _buildPlaceholder(),
//               ),
//
//             // 播放按钮
//             if (!_isPlaying || _showControls)
//               Positioned.fill(
//                 child: AnimatedOpacity(
//                   opacity: _showControls ? 1.0 : 0.7,
//                   duration: const Duration(milliseconds: 300),
//                   child: Container(
//                     color: Colors.black.withOpacity(0.3),
//                     child: Center(
//                       child: _isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Icon(
//                         _isPlaying ? Icons.pause : Icons.play_arrow,
//                         size: 48,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//             // 视频时长
//             Positioned(
//               right: 8,
//               bottom: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   _formatDuration(_videoDuration),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//
//             // 进度条
//             if (_showControls && _controller.value.isInitialized)
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   height: 3,
//                   color: Colors.black.withOpacity(0.5),
//                   child: FractionallySizedBox(
//                     alignment: Alignment.centerLeft,
//                     widthFactor: _playbackPosition,
//                     child: Container(
//                       color: theme.colorScheme.primary,
//                     ),
//                   ),
//                 ),
//               ),
//
//             // 全屏按钮
//             if (_showControls)
//               Positioned(
//                 right: 8,
//                 top: 8,
//                 child: GestureDetector(
//                   onTap: _toggleFullScreen,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.fullscreen,
//                       size: 18,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlaceholder() {
//     return Container(
//       color: Colors.grey[200],
//       width: double.infinity,
//       height: 200,
//       child: const Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.videocam, size: 48, color: Colors.grey),
//           SizedBox(height: 8),
//           Text('视频预览', style: TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }
// }
//
// class _FullScreenVideoPlayer extends StatefulWidget {
//   final VideoPlayerController controller;
//   final bool isPlaying;
//
//   const _FullScreenVideoPlayer({
//     required this.controller,
//     required this.isPlaying,
//   });
//
//   @override
//   State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
// }
//
// class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
//   bool _showControls = true;
//   late bool _isPlaying;
//   late bool _isInitialized;
//
//   @override
//   void initState() {
//     super.initState();
//     _isPlaying = widget.isPlaying;
//     _isInitialized = widget.controller.value.isInitialized;
//
//     if (!_isInitialized) {
//       widget.controller.initialize().then((_) {
//         if (mounted) {
//           setState(() {
//             _isInitialized = true;
//             if (_isPlaying) {
//               widget.controller.play();
//             }
//           });
//         }
//       });
//     } else if (_isPlaying) {
//       widget.controller.play();
//     }
//
//     // 自动隐藏控制条
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) setState(() => _showControls = false);
//     });
//   }
//
//   void _togglePlayback() {
//     if (!_isInitialized) return;
//
//     if (_isPlaying) {
//       widget.controller.pause();
//     } else {
//       widget.controller.play();
//     }
//     setState(() {
//       _isPlaying = !_isPlaying;
//       _showControls = true;
//     });
//
//     // 自动隐藏控制条
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) setState(() => _showControls = false);
//     });
//   }
//
//   void _toggleControls() {
//     setState(() => _showControls = !_showControls);
//   }
//
//   String _formatDuration(Duration duration) {
//     if (duration == Duration.zero) return "00:00";
//
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // 视频播放器
//           if (_isInitialized)
//             Center(
//               child: AspectRatio(
//                 aspectRatio: widget.controller.value.aspectRatio,
//                 child: VideoPlayer(widget.controller),
//               ),
//             )
//           else
//             const Center(child: CircularProgressIndicator()),
//
//           // 控制层
//           if (_showControls)
//             GestureDetector(
//               onTap: _toggleControls,
//               behavior: HitTestBehavior.opaque,
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: Column(
//                   children: [
//                     AppBar(
//                       backgroundColor: Colors.transparent,
//                       elevation: 0,
//                       leading: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                     Expanded(
//                       child: Center(
//                         child: IconButton(
//                           icon: Icon(
//                             _isPlaying ? Icons.pause : Icons.play_arrow,
//                             size: 64,
//                             color: Colors.white,
//                           ),
//                           onPressed: _togglePlayback,
//                         ),
//                       ),
//                     ),
//                     // 进度条
//                     if (_isInitialized)
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           children: [
//                             Text(
//                               _formatDuration(widget.controller.value.position),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             Expanded(
//                               child: Slider(
//                                 value: widget.controller.value.position.inMilliseconds.toDouble(),
//                                 min: 0,
//                                 max: widget.controller.value.duration.inMilliseconds.toDouble(),
//                                 onChanged: (value) {
//                                   widget.controller.seekTo(Duration(milliseconds: value.toInt()));
//                                 },
//                                 activeColor: Theme.of(context).colorScheme.primary,
//                                 inactiveColor: Colors.grey[700],
//                               ),
//                             ),
//                             Text(
//                               _formatDuration(widget.controller.value.duration),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }