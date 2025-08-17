// import 'dart:async';
// import 'package:qychatapp/presentation/ui/chart/text_message_widget.dart';
// import 'package:qychatapp/presentation/ui/chart/video_message_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../utils/global_utils.dart';
// import '../../utils/websocket/chart_manager.dart';
// import '../../utils/websocket/socket_manager.dart';
// import 'audio_message_widget.dart';
// import 'composer.dart';
//
// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   String _cachedCurrentUserId = "";
//
//
//   bool _isSound = true;
//   final _chatController = InMemoryChatController();
//   StreamSubscription<List<Message>>? _messageSubscription;
//   StreamSubscription<Message>? _updateSubscription;
//
//   bool _isConnected = false;
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     // 初始化时缓存用户ID
//     loadData();
//     _initializeChat();
//   }
//
//   Future<void> loadData() async {
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     setState(() {
//       _cachedCurrentUserId = "${userId}";
//     });
//     print("------------build userId----------$userId");
//     print("------------build _cachedCurrentUserId----------$_cachedCurrentUserId");
//
//
//   }
//
//   Future<void> _initializeChat() async {
//     try {
//       // 初始化聊天管理器
//       //await ChatManager.initialize();
//
//       // 订阅消息流
//       _messageSubscription = SocketIOManager().messagesStream.listen((messages) {
//         print("消息 更新");
//         // 只添加新消息，避免重复
//         final existingIds = _chatController.messages.map((m) => m.id).toSet();
//         final newMessages = messages.where((m) => !existingIds.contains(m.id)).toList();
//
//         if (newMessages.isNotEmpty) {
//           _chatController.insertAllMessages(newMessages);
//         }
//       });
//
//       // 订阅消息流
//       _updateSubscription = SocketIOManager().updateStream.listen((messages) {
//         print("消息 更新");
//         final index = _chatController.messages.indexWhere((m) => m.id == messages.id);
//         print("消息 更新  index=${index}");
//         _chatController.updateMessage(_chatController.messages[index], messages);
//       });
//
//       setState(() {
//         _isConnected = true;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('初始化失败: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _messageSubscription?.cancel();
//     _chatController.dispose();
//     SocketIOManager().dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("------------build----------$_cachedCurrentUserId");
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('小宇客服'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(_isSound ? Icons.volume_up : Icons.volume_off),
//             onPressed: _toggleSound,
//             tooltip: _isSound ? '打开声音' : '关闭声音',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           Expanded(
//             child: Chat(
//               chatController: _chatController,
//               currentUserId: "${_cachedCurrentUserId}",
//               builders: Builders(
//                 composerBuilder: (context) => FixedBottomComposer(),
//                 textMessageBuilder: (context, message, index, {
//                   required bool isSentByMe,
//                   MessageGroupStatus? groupStatus,
//                 }) => RichTextMessageWidget(message: message,isSentByMe: isSentByMe),
//                 imageMessageBuilder: (context, message, index, {
//                   required bool isSentByMe,
//                   MessageGroupStatus? groupStatus,
//                 }) => FlyerChatImageMessage(message: message, index: index),
//                 audioMessageBuilder: (context, message, index, {
//                   required bool isSentByMe,
//                   MessageGroupStatus? groupStatus,
//                 }) => AudioMessageWidget(message: message, isSentByMe: isSentByMe,),
//                 videoMessageBuilder: (context, message, index, {
//                   required bool isSentByMe,
//                   MessageGroupStatus? groupStatus,
//                 }) => ChatVideoMessage(message: message, isSentByMe: isSentByMe,),
//               ),
//               resolveUser: (UserID id) async {
//                 print("resolveUser====${id}");
//                 return User(id: id, );
//               },
//             ),
//           ),
//         ],
//       ),
//       //bottomNavigationBar: FixedBottomComposer(),
//     );
//   }
//
//   /// 显示重新发送菜单
//   void _showResendMenu(BuildContext context, Message message) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.refresh),
//               title: const Text('重新发送'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _resendMessage(message);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // 重新发送消息
//   void _resendMessage(Message message) {
//     //ChatManager.resendMessage(message);
//   }
//
//   void _toggleSound() {
//     setState(() {
//       _isSound = !_isSound;
//     });
//   }
// }