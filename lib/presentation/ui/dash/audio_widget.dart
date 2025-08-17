// import 'package:flutter/material.dart';
//
// class AudioMessageWidget extends StatefulWidget {
//   final String audioUrl;
//   final int duration; // 秒
//
//   const AudioMessageWidget({
//     super.key,
//     required this.audioUrl,
//     required this.duration,
//   });
//
//   @override
//   State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
// }
//
// class _AudioMessageWidgetState extends State<AudioMessageWidget> {
//   late AudioPlayer _player;
//   bool isPlaying = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     _player.setSourceUrl(widget.audioUrl);
//   }
//
//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }
//
//   void togglePlay() async {
//     if (isPlaying) {
//       await _player.pause();
//     } else {
//       await _player.play();
//     }
//     setState(() {
//       isPlaying = !isPlaying;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           IconButton(
//             icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
//             onPressed: togglePlay,
//           ),
//           Text("${widget.duration}\""),
//         ],
//       ),
//     );
//   }
// }
