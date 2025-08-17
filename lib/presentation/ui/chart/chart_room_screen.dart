// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import '../../utils/websocket/chart_manager.dart';
//
// class ChatRoomScreen extends StatefulWidget {
//   const ChatRoomScreen({super.key});
//
//   @override
//   State<ChatRoomScreen> createState() => _ChatRoomScreenState();
// }
//
// class _ChatRoomScreenState extends State<ChatRoomScreen> {
//   List<Message> _messages = [];
//   List<User> _users = [];
//   late StreamSubscription _messageSubscription;
//   late StreamSubscription _userSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     ChatManager.initialize().then((_) {
//       _messageSubscription = ChatManager.messagesStream.listen((messages) {
//         setState(() => _messages = messages);
//       });
//
//       _userSubscription = ChatManager.usersStream.listen((users) {
//         setState(() => _users = users);
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _messageSubscription.cancel();
//     _userSubscription.cancel();
//     ChatManager.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         //title: Text("${ChatManager.chatRoom.name}"),
//         actions: [
//           // IconButton(
//           //   icon: const Icon(Icons.people),
//           //   onPressed: () => _showUserList(),
//           // ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 用户列表（顶部）
//           //_buildOnlineUsers(),
//
//           // // 消息列表
//           // Expanded(
//           //   child: ListView.builder(
//           //     reverse: true,
//           //     itemCount: _messages.length,
//           //     itemBuilder: (context, index) {
//           //       return _buildMessageBubble(_messages[index]);
//           //     },
//           //   ),
//           // ),
//           //
//           // // 输入框
//           // _buildInputArea(),
//         ],
//       ),
//     );
//   }
//
//   // Widget _buildOnlineUsers() {
//   //   return SizedBox(
//   //     height: 60,
//   //     child: ListView.builder(
//   //       scrollDirection: Axis.horizontal,
//   //       itemCount: _users.length,
//   //       itemBuilder: (context, index) {
//   //         return _buildUserAvatar(_users[index]);
//   //       },
//   //     ),
//   //   );
//   // }
//
//   Widget _buildUserAvatar(User user) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.blue,
//             child: Text(
//               "user.firstName?[0] ?? '?',",
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           //Text(user.firstName ?? '未知'),
//         ],
//       ),
//     );
//   }
//
//   // void _showUserList() {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (context) {
//   //       return ListView.builder(
//   //         itemCount: _users.length,
//   //         itemBuilder: (context, index) {
//   //           return ListTile(
//   //             leading: CircleAvatar(
//   //               child: Text(_users[index].firstName?[0] ?? '?'),
//   //             ),
//   //             title: Text(_users[index].firstName ?? '未知用户'),
//   //             subtitle: Text(_users[index].id),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
// }