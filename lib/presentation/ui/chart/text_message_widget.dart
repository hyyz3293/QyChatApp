// import 'package:flutter/material.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class RichTextMessageWidget extends StatelessWidget {
//   final TextMessage message;
//   final bool isSentByMe;
//
//   const RichTextMessageWidget({
//     super.key,
//     required this.message,
//     required this.isSentByMe,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final bgColor = isSentByMe
//         ? theme.colorScheme.primary.withOpacity(0.1)
//         : theme.colorScheme.secondary.withOpacity(0.1);
//     final textColor = Colors.black;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       constraints: const BoxConstraints(maxWidth: 300),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           if (!isSentByMe) ...[
//             _buildDecoration(context),
//             const SizedBox(width: 8),
//           ],
//
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(12),
//                 topRight: const Radius.circular(12),
//                 bottomLeft: Radius.circular(isSentByMe ? 12 : 0),
//                 bottomRight: Radius.circular(isSentByMe ? 0 : 12),
//               ),
//             ),
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 280),
//               child: _buildRichText(context, textColor),
//             ),
//           ),
//
//           if (isSentByMe) ...[
//             const SizedBox(width: 8),
//             _buildDecoration(context),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRichText(BuildContext context, Color? textColor) {
//     // 处理图片路径 - 添加前缀
//     final processedHtml = _processImageUrls(message.text);
//
//     return Html(
//       data: processedHtml,
//       style: {
//         "body": Style(
//           fontSize: FontSize(16.0),
//           color: textColor,
//          // margin: EdgeInsets.zero,
//           //padding: EdgeInsets.zero,
//         ),
//         "p": Style(
//             //margin: EdgeInsets.zero
//         ),
//         "b": Style(fontWeight: FontWeight.bold),
//         "i": Style(fontStyle: FontStyle.italic),
//         "u": Style(textDecoration: TextDecoration.underline),
//         "a": Style(
//           color: Colors.blue,
//           textDecoration: TextDecoration.underline,
//         ),
//         "img": Style(
//           //margin: EdgeInsets.zero,
//           //padding: EdgeInsets.zero,
//           alignment: Alignment.center,
//         ),
//       },
//       onLinkTap: (url, _, __,) {
//         if (url != null) launchUrl(Uri.parse(url));
//       },
//       shrinkWrap: true,
//     );
//   }
//
//   // 处理图片URL，添加前缀
//   String _processImageUrls(String html) {
//     return html.replaceAllMapped(
//       RegExp(r'<img\s+[^>]*src="([^"]+)"[^>]*>', caseSensitive: false),
//           (match) {
//         final imgTag = match.group(0)!;
//         final src = match.group(1)!;
//
//         // 如果已经是完整URL，直接返回
//         if (src.startsWith('http://') || src.startsWith('https://')) {
//           return imgTag;
//         }
//
//         // 添加前缀
//         String fullUrl = 'https://uat-ccc.qylink.com:9991';
//         if (!src.startsWith('/')) {
//           fullUrl += '/';
//         }
//         fullUrl += src;
//
//         // 替换原始src，并添加完整URL
//         return imgTag.replaceFirst('src="$src"', 'src="$fullUrl"');
//       },
//     );
//   }
//
//   Widget _buildDecoration(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: isSentByMe
//             ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
//             : Colors.grey[400],
//         shape: BoxShape.circle,
//       ),
//       child: Icon(
//         isSentByMe ? Icons.send : Icons.message,
//         size: 12,
//         color: isSentByMe ? Theme.of(context).colorScheme.primary : Colors.white,
//       ),
//     );
//   }
// }