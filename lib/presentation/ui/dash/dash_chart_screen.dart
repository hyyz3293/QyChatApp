// import 'dart:async';
// import 'dart:io';
// import 'package:qychatapp/presentation/ui/dash/dash_composer.dart';
// import 'package:qychatapp/presentation/utils/websocket/dash_socket_manager.dart';
// import 'package:dash_chat_2/dash_chat_2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:record/record.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../utils/global_utils.dart';
// import '../../utils/websocket/socket_manager.dart';
// import '../chart/audio_message_widget.dart';
// import 'data.dart';
//
// class DashChatScreen extends StatefulWidget {
//   const DashChatScreen({super.key});
//
//   @override
//   State<DashChatScreen> createState() => _DashChatScreenState();
// }
//
// class AnimatedBar extends StatelessWidget {
//   final double height;
//   final bool isActive;
//
//   const AnimatedBar({super.key, required this.height, required this.isActive});
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.symmetric(horizontal: 2),
//       width: 6,
//       height: isActive ? height * 1.5 : height,
//       decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(3)),
//     );
//   }
// }
//
// class _DashChatScreenState extends State<DashChatScreen> with TickerProviderStateMixin {
//   String _cachedCurrentUserId = "";
//   bool _isSound = true;
//   //final _chatController = InMemoryChatController();
//   StreamSubscription<List<ChatMessage>>? _messageSubscription;
//   //StreamSubscription<ChatMessage>? _updateSubscription;
//
//   //final TextEditingController _controller = TextEditingController();
//
//   final TextEditingController _textController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   bool _hasText = false; //是否输入
//   bool _hasKeyboard = true; // 是否展示软键盘/语音
//   bool _hasPhoto = false; // 相册/拍照
//   bool _hasEmoji = false; // 表情
//
//   // 语音录制相关状态
//   bool _isRecording = false;
//   bool _isCancelling = false;
//   int _recordingSeconds = 0;
//   late Timer _recordingTimer;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//   final AudioRecorder _audioRecorder = AudioRecorder();
//   String? _recordingPath;
//
//   final ImagePicker _picker = ImagePicker();
//
//   // 添加用于控制对话框的变量
//   bool _showRecordingDialog = false;
//
//   ChatUser user = ChatUser(
//     id: '1',
//     firstName: 'Charles',
//     lastName: 'Leclerc',
//     profileImage: 'https://firebasestorage.googleapis.com/v0/b/molteo-40978.appspot.com/o/1-intro-photo-final.jpeg?alt=media&token=daf78997-d8f0-49d1-9120-a9380bde48b5',
//   );
//
//   List<ChatMessage> messages = <ChatMessage>[
//     // ChatMessage(
//     //   text: 'Hey!',
//     //   user: user,
//     //   createdAt: DateTime.now(),
//     // ),
//   ];
//
//   //bool _isConnected = false;
//   //bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     // 初始化时缓存用户ID
//     loadData();
//     _initializeChat();
//
//     // 初始化文本监听
//     _textController.addListener(() {
//       setState(() {
//         _hasText = _textController.text.trim().isNotEmpty;
//       });
//     });
//
//     // 初始化脉冲动画控制器
//     _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
//
//     _pulseAnimation = Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
//
//     // 添加焦点监听器
//     _focusNode.addListener(_handleFocusChange);
//   }
//
//   Future<void> loadData() async {
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     setState(() {
//       messages = media;
//       _cachedCurrentUserId = "${userId}";
//       user = ChatUser(
//         id: '${_cachedCurrentUserId}',
//         firstName: 'Charles',
//         lastName: 'Leclerc',
//         profileImage: 'https://firebasestorage.googleapis.com/v0/b/molteo-40978.appspot.com/o/1-intro-photo-final.jpeg?alt=media&token=daf78997-d8f0-49d1-9120-a9380bde48b5',
//       );
//     });
//
//     print("------------build userId----------$userId");
//     print("------------build _cachedCurrentUserId----------$_cachedCurrentUserId");
//   }
//
//   Future<void> _initializeChat() async {
//     try {
//       // 初始化聊天管理器
//       //await ChatManager.initialize();
//
//       // 订阅消息流
//       _messageSubscription = ISocketIOManager().messagesStream.listen((msg) {
//         print("消息 更新 ${msg[0].customProperties}");
//         setState(() {
//           messages.insert(0, msg[0]);
//         });
//       });
//       //
//       // // 订阅消息流
//       // _updateSubscription = SocketIOManager().updateStream.listen((messages) {
//       //   print("消息 更新");
//       //   final index = _chatController.messages.indexWhere((m) => m.id == messages.id);
//       //   print("消息 更新  index=${index}");
//       //   _chatController.updateMessage(_chatController.messages[index], messages);
//       // });
//
//       // setState(() {
//       //   _isConnected = true;
//       //   _isLoading = false;
//       // });
//     } catch (e) {
//       print('初始化失败: $e');
//       // setState(() {
//       //   _isLoading = false;
//       // });
//     }
//   }
//
//   @override
//   void dispose() {
//     _messageSubscription?.cancel();
//     //_chatController.dispose();
//     ISocketIOManager().dispose();
//     _textController.dispose();
//     _focusNode.dispose();
//     _pulseController.dispose();
//     _stopRecordingTimer();
//     _focusNode.removeListener(_handleFocusChange);
//
//     // 释放录音资源
//     _audioRecorder.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("------------build----------$_cachedCurrentUserId");
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: Colors.grey,
//       appBar: AppBar(
//         title: Text('小宇客服'),
//         centerTitle: true,
//         actions: [IconButton(icon: Icon(_isSound ? Icons.volume_up : Icons.volume_off), onPressed: _toggleSound, tooltip: _isSound ? '打开声音' : '关闭声音')],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: DashChat(
//                   currentUser: user,
//                   readOnly: true,
//                   onSend: (ChatMessage m) {
//                     setState(() {
//                       messages.insert(0, m);
//                     });
//                   },
//                   messageOptions: MessageOptions(
//                     showCurrentUserAvatar: true, // ✅ 让自己消息显示头像
//                     showOtherUsersAvatar: true, // 如果你也要显示对方头像
//                     messageMediaBuilder: (message,previousMessage, nextMessage)  {
//                       print("-- message---->>>>>>>>>>>>>customProperties>>>>>>>${message.customProperties}");
//                       if (message.customProperties != null && message.customProperties!["type"] == "audio") {
//                         print("-- audio---->>>>>>>>>>>>>>>>>>>>");
//                         return AudioMessageWidget(url: '${message.customProperties!["url"]}',
//                           isSentByMe: true,);
//                       }
//                       return MediaContainer(
//                         message: message,
//                         isOwnMessage: message.user.id == user.id,
//                         messageOptions: const MessageOptions(),
//                       );
//                     }
//                   ),
//                   messages: messages,
//                   inputOptions: InputOptions(
//                     inputDecoration: InputDecoration(border: InputBorder.none, hintText: ''),
//                     alwaysShowSend: false,
//                     sendButtonBuilder: (_) => const SizedBox(width: 0, height: 0), // 完全无尺寸
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // 录音覆盖层
//           if (_isRecording) _buildRecordingOverlay(),
//         ],
//       ),
//
//       bottomNavigationBar: SafeArea(
//         child: Container(
//           color: Colors.white,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
//                 child: Row(
//                   children: [
//                     // 语音/键盘切换按钮
//                     IconButton(icon: Icon(_hasKeyboard ? Icons.mic : Icons.keyboard, color: Colors.black), onPressed: _handleKeyboard),
//
//                     // 输入框/语音按钮区域
//                     Expanded(child: _hasKeyboard ? _buildTextInput() : _buildVoiceButton()),
//
//                     const SizedBox(width: 8),
//
//                     // 表情按钮
//                     IconButton(padding: EdgeInsets.all(0), onPressed: _handleEmojiSend, icon: Icon(Icons.emoji_emotions_outlined, color: Colors.black)),
//
//                     // 发送/添加按钮
//                     _hasText
//                         ? ElevatedButton(onPressed: _handleTextSend, child: Text("发送", style: TextStyle(color: Colors.white)))
//                         : IconButton(padding: EdgeInsets.all(0), onPressed: _handleAdd, icon: Icon(Icons.add_circle_outline_rounded, color: Colors.black)),
//                   ],
//                 ),
//               ),
//               _hasPhoto || _hasEmoji
//                   ? Container(
//                 height: 150,
//                 width: double.infinity,
//                 child:
//                 _hasPhoto
//                     ? _buildMorePanel()
//                     : _hasEmoji
//                     ? _buildEmojiPanel()
//                     : Container(),
//               )
//                   : Container(),
//             ],
//           ),
//         ), // 你写的输入栏
//       ),
//     );
//   }
//
//   void _toggleSound() {
//     setState(() {
//       _isSound = !_isSound;
//     });
//   }
//
//   void _handleTextSend() {
//     final text = _textController.text.trim();
//     if (text.isEmpty) return;
//
//     // // 调用 Chat 组件的消息发送回调
//     // final onMessageSend = Provider.of<OnMessageSendCallback?>(context, listen: false);
//     // if (onMessageSend != null) {
//     //   //onMessageSend(types.PartialText(text: text));
//     //   onMessageSend(types.TextMessage(author: types.User(id: 'user_id_1'), id: '${_generateUUID}', text: '${text}') as String);
//     // }
//     printN("===> ${text}");
//
//     ISocketIOManager().sendTextMessage(text);
//
//     _textController.clear();
//     _focusNode.requestFocus();
//     setState(() => _hasText = false);
//   }
//
//   void _handleEmojiSend() {
//     _closeKeyboard();
//     // 表情发送逻辑
//     setState(() {
//       _hasKeyboard = true;
//       _hasEmoji = !_hasEmoji;
//       if (_hasEmoji) {
//         _hasPhoto = false;
//       }
//     });
//   }
//
//   void _handleAdd() {
//     _closeKeyboard();
//     // 添加附件逻辑
//     setState(() {
//       _hasPhoto = !_hasPhoto;
//       if (_hasPhoto) {
//         _hasEmoji = false;
//       }
//     });
//   }
//
//   // 焦点变化处理
//   void _handleFocusChange() {
//     if (_focusNode.hasFocus) {
//       // 输入框获得焦点时，隐藏表情和图片面板
//       setState(() {
//         _hasEmoji = false;
//         _hasPhoto = false;
//       });
//     }
//   }
//
//   void _handleKeyboard() {
//     setState(() {
//       _hasPhoto = false;
//       _hasEmoji = false;
//       _hasKeyboard = !_hasKeyboard;
//     });
//   }
//
//   // 文本输入框组件
//   Widget _buildTextInput() {
//     return Container(
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: TextField(
//         controller: _textController,
//         focusNode: _focusNode,
//         style: TextStyle(color: Colors.black),
//         decoration: InputDecoration(hintText: '输入消息...', hintStyle: TextStyle(color: Colors.black), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
//         textInputAction: TextInputAction.send,
//         onSubmitted: (_) => _handleTextSend(),
//         maxLines: 5,
//         minLines: 1,
//       ),
//     );
//   }
//
//   // 录音覆盖层组件
//   bool _isSending = false; // 发送状态
//   double _startX = 0.0; // 触摸起始X坐标
//   double _startY = 0.0; // 触摸起始Y坐标
//   double _slideProgress = 0.0; // 滑动进度
//
//   // 语音按钮组件
//   Widget _buildVoiceButton() {
//     return GestureDetector(
//       onTapDown: (details) {
//         _startX = details.globalPosition.dx;
//         _startY = details.globalPosition.dy;
//         _startRecording();
//       },
//       onTapUp: (details) => _stopRecording(),
//       onTapCancel: _stopRecording,
//       onPanUpdate: (details) {
//         // 计算滑动距离
//         double horizontalDrag = details.globalPosition.dx - _startX;
//         double verticalDrag = details.globalPosition.dy - _startY;
//
//         // 计算滑动进度 (0-1)
//         _slideProgress = (horizontalDrag.abs() + verticalDrag.abs()) / 100;
//         if (_slideProgress > 1.0) _slideProgress = 1.0;
//
//         // 左上方滑动检测 (向左且向上)
//         if (horizontalDrag < -50 && verticalDrag < -50) {
//           setState(() => _isCancelling = true);
//         }
//         // 右上方滑动检测 (向右且向上)
//         else if (horizontalDrag > 50 && verticalDrag < -50) {
//           setState(() => _isSending = true);
//         } else {
//           setState(() {
//             _isCancelling = false;
//             _isSending = false;
//           });
//         }
//       },
//       child: Container(
//         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//         alignment: Alignment.center,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.mic, color: Colors.black87, size: 20),
//             SizedBox(width: 8),
//             Text(_isRecording ? "松开结束" : "按住说话", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRecordingOverlay() {
//     return Stack(
//       children: [
//         // 半透明背景
//         Positioned.fill(child: AnimatedContainer(duration: Duration(milliseconds: 200), color: Colors.black54)),
//
//         // 录音内容
//         Positioned.fill(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 录音动画
//               ScaleTransition(
//                 scale: _pulseAnimation,
//                 child: AnimatedContainer(
//                   duration: Duration(milliseconds: 200),
//                   width: 140,
//                   height: 140,
//                   decoration: BoxDecoration(
//                     color: (_isCancelling || _isSending) ? Colors.red : Colors.green,
//                     shape: BoxShape.circle,
//                     boxShadow: [BoxShadow(color: (_isCancelling || _isSending) ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
//                   ),
//                   child: Icon(
//                     _isCancelling
//                         ? Icons.close
//                         : _isSending
//                         ? Icons.check
//                         : Icons.mic,
//                     color: Colors.white,
//                     size: 70,
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 40),
//
//               // 录音时间
//               Text('${_recordingSeconds.toString().padLeft(2, '0')}"', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
//
//               const SizedBox(height: 24),
//
//               // 提示文字
//               Text(
//                 _isCancelling
//                     ? '向左上滑动取消'
//                     : _isSending
//                     ? '向右上滑动发送'
//                     : '按住说话',
//                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
//               ),
//
//               const SizedBox(height: 30),
//
//               // 录音波形动画
//               Container(
//                 height: 60,
//                 width: 200,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(12, (index) {
//                     // 创建随机高度的波形条，模拟声音波动
//                     final randomHeight = (_recordingSeconds % 5 + (index % 3 + 1)) * 5.0 * (0.5 + _slideProgress * 0.5);
//                     return Padding(padding: const EdgeInsets.symmetric(horizontal: 2.5), child: AnimatedBar(height: randomHeight, isActive: _recordingSeconds % (index + 1) == 0));
//                   }),
//                 ),
//               ),
//
//               // 滑动提示箭头
//               if (!_isCancelling && !_isSending) ...[
//                 const SizedBox(height: 40),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Column(children: [Icon(Icons.arrow_left, color: Colors.white70, size: 24), SizedBox(height: 4), Text('取消', style: TextStyle(color: Colors.white70, fontSize: 14))]),
//                     SizedBox(width: 80),
//                     Column(children: [Icon(Icons.arrow_right, color: Colors.white70, size: 24), SizedBox(height: 4), Text('发送', style: TextStyle(color: Colors.white70, fontSize: 14))]),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildEmojiPanel() {
//     // 实际项目中可以使用emoji_picker_flutter等包
//     final emojis = List.generate(100, (index) => String.fromCharCode(0x1F600 + index));
//
//     return Container(
//       color: Colors.grey.shade100,
//       child: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
//         itemCount: emojis.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(onTap: () => _insertEmoji(emojis[index]), child: Text(emojis[index], style: const TextStyle(fontSize: 28)));
//         },
//       ),
//     );
//   }
//
//   void _insertEmoji(String emoji) {
//     final text = _textController.text;
//     final selection = _textController.selection;
//     final newText = text.replaceRange(selection.start, selection.end, emoji);
//     _textController.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: selection.start + emoji.length));
//
//     // 插入表情后更新文本状态
//     setState(() {
//       _hasText = newText.trim().isNotEmpty;
//     });
//   }
//
//   Widget _buildMorePanel() {
//     final actions = [
//       {
//         'icon': Icons.photo,
//         'label': '照片',
//         //'onTap': _pickImageFromGallery, // 打开相册
//       },
//       {
//         'icon': Icons.videocam,
//         'label': '视频',
//         //'onTap': _pickImageFromGallery, // 打开相册
//       },
//       {
//         'icon': Icons.camera_alt,
//         'label': '拍照',
//         //'onTap': _takePhoto, // 拍照
//       },
//       {
//         'icon': Icons.video_call,
//         'label': '录像',
//         //'onTap': _takePhoto, // 拍照
//       },
//     ];
//
//     return Container(
//       color: Colors.grey.shade100,
//       padding: const EdgeInsets.all(16),
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
//         itemCount: actions.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () {
//               var label = actions[index]['label'] as String;
//               print("-------------label :${label}");
//               if (label == "照片") {
//                 _pickImageFromGallery();
//               } else if (label == "视频") {
//                 _pickVideoFromGallery();
//               } else if (label == "拍照") {
//                 _takePhoto();
//               } else {
//                 _takeVideo();
//               }
//             }, // 绑定点击事件
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
//                   child: Icon(actions[index]['icon'] as IconData, color: Colors.black, size: 24),
//                 ),
//                 const SizedBox(height: 4),
//                 Flexible(
//                   child: Text(
//                     actions[index]['label'] as String,
//                     style: TextStyle(color: Colors.black, fontSize: 11, height: 1.1),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   void _closeKeyboard() {
//     FocusScope.of(context).unfocus();
//   }
//
//   // 打开相册选择图片
//   Future<void> _pickImageFromGallery() async {
//     try {
//       // 请求相册权限
//       final permission = await PhotoManager.requestPermissionExtend();
//
//       if (permission.isAuth || permission.hasAccess) {
//         // final status = await Permission.photos.request();
//         // if (status != PermissionStatus.granted) {
//         //   print('相册权限被拒绝');
//         //   return;
//         // }
//
//         // 选择图片
//         final XFile? image = await _picker.pickImage(
//           source: ImageSource.gallery,
//           maxWidth: 1800, // 限制图片宽度
//           maxHeight: 1800, // 限制图片高度
//           imageQuality: 85, // 图片质量
//         );
//
//         if (image != null) {
//           // 获取文件信息
//           final file = File(image.path);
//           final fileSize = await file.length();
//           final imageBytes = await file.readAsBytes();
//
//           // 获取图片尺寸
//           final decodedImage = await decodeImageFromList(imageBytes);
//           final width = decodedImage.width.toDouble();
//           final height = decodedImage.height.toDouble();
//
//           ISocketIOManager().sendPictureMessage(image.path);
//
//           // 关闭面板
//           setState(() => _hasPhoto = false);
//         }
//       }
//     } catch (e) {
//       print('选择图片失败: $e');
//     }
//   }
//
//   // 打开相册选择图片
//   Future<void> _pickVideoFromGallery() async {
//     try {
//       // 请求相册权限
//       final permission = await PhotoManager.requestPermissionExtend();
//
//       if (permission.isAuth || permission.hasAccess) {
//         // final status = await Permission.photos.request();
//         // if (status != PermissionStatus.granted) {
//         //   print('相册权限被拒绝');
//         //   return;
//         // }
//
//         // 选择图片
//         final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);
//
//         if (image != null) {
//           // // 获取文件信息
//           // final file = File(image.path);
//           // final fileSize = await file.length();
//           // final imageBytes = await file.readAsBytes();
//           //
//           // // 获取图片尺寸
//           // final decodedImage = await decodeImageFromList(imageBytes);
//           // final width = decodedImage.width.toDouble();
//           // final height = decodedImage.height.toDouble();
//
//           ISocketIOManager().sendVideoMessage(image.path);
//
//           // 关闭面板
//           setState(() => _hasPhoto = false);
//         }
//       }
//     } catch (e) {
//       print('选择图片失败: $e');
//     }
//   }
//
//   // 拍照功能
//   Future<void> _takePhoto() async {
//     try {
//       // 请求相机权限
//       final status = await Permission.camera.request();
//       if (status != PermissionStatus.granted) {
//         print('相机权限被拒绝');
//         return;
//       }
//
//       // 拍照
//       final XFile? photo = await _picker.pickImage(
//         source: ImageSource.camera,
//         //preferredCameraDevice: CameraDevice.rear,
//         // 关键参数：允许选择媒体类型
//         requestFullMetadata: true,
//       );
//
//       if (photo != null) {
//         ISocketIOManager().sendPictureMessage(photo.path);
//
//         // // 获取文件信息
//         // final file = File(photo.path);
//         // final fileSize = await file.length();
//         // final imageBytes = await file.readAsBytes();
//         //
//         // // 获取图片尺寸
//         // final decodedImage = await decodeImageFromList(imageBytes);
//         // final width = decodedImage.width.toDouble();
//         // final height = decodedImage.height.toDouble();
//
//         // // 发送图片消息
//         // final onMessageSend = Provider.of<OnMessageSendCallback?>(context, listen: false);
//         // if (onMessageSend != null) {
//         //   // onMessageSend(types.PartialImage(
//         //   //   name: photo.name,
//         //   //   size: fileSize,
//         //   //   width: width,
//         //   //   height: height,
//         //   //   uri: photo.path,
//         //   // ));
//         // }
//
//         // 关闭面板
//         setState(() => _hasPhoto = false);
//       }
//     } catch (e) {
//       print('拍照失败: $e');
//     }
//   }
//
//   // 录像功能
//   Future<void> _takeVideo() async {
//     try {
//       // 请求相机权限
//       final status = await Permission.camera.request();
//       if (status != PermissionStatus.granted) {
//         print('相机权限被拒绝');
//         return;
//       }
//
//       // 拍照
//       final XFile? photo = await _picker.pickVideo(source: ImageSource.camera, maxDuration: Duration(seconds: 60));
//
//       if (photo != null) {
//         ISocketIOManager().sendVideoMessage(photo.path);
//
//         // // 获取文件信息
//         // final file = File(photo.path);
//         // final fileSize = await file.length();
//         // final imageBytes = await file.readAsBytes();
//         //
//         // // 获取图片尺寸
//         // final decodedImage = await decodeImageFromList(imageBytes);
//         // final width = decodedImage.width.toDouble();
//         // final height = decodedImage.height.toDouble();
//
//         // // 发送图片消息
//         // final onMessageSend = Provider.of<OnMessageSendCallback?>(context, listen: false);
//         // if (onMessageSend != null) {
//         //   // onMessageSend(types.PartialImage(
//         //   //   name: photo.name,
//         //   //   size: fileSize,
//         //   //   width: width,
//         //   //   height: height,
//         //   //   uri: photo.path,
//         //   // ));
//         // }
//
//         // 关闭面板
//         setState(() => _hasPhoto = false);
//       }
//     } catch (e) {
//       print('拍照失败: $e');
//     }
//   }
//
//   // 开始录音
//   Future<void> _startRecording() async {
//     // 检查麦克风权限
//     final micStatus = await Permission.microphone.request();
//     if (micStatus != PermissionStatus.granted) {
//       print('麦克风权限被拒绝');
//       return;
//     }
//
//     // 检查存储权限（如果需要保存文件）
//     final storageStatus = await Permission.storage.request();
//     if (storageStatus != PermissionStatus.granted) {
//       print('存储权限被拒绝');
//       return;
//     }
//
//     try {
//       // 获取临时目录
//       final tempDir = await getTemporaryDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       _recordingPath = '${tempDir.path}/recording_$timestamp.mp3';
//
//       // 开始录音
//       // await _audioRecorder.start(
//       //   path: _recordingPath,
//       //   encoder: AudioEncoder.aacLc, // AAC编码，兼容性好
//       //   bitRate: 128000, // 128 kbps
//       //   samplingRate: 44100, // 44.1 kHz
//       // );
//       await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
//
//       HapticFeedback.mediumImpact(); // 触觉反馈
//       setState(() {
//         _isRecording = true;
//         _isCancelling = false;
//         _recordingSeconds = 0;
//       });
//
//       // 开始脉冲动画
//       _pulseController.repeat(reverse: true);
//
//       // 开始计时
//       _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         setState(() => _recordingSeconds = timer.tick);
//         if (timer.tick >= 60) _stopRecording(); // 最长60秒
//       });
//
//       print('开始录音: $_recordingPath');
//     } catch (e) {
//       print('录音启动失败: $e');
//       setState(() => _isRecording = false);
//     }
//   }
//
//   // 停止录音
//   Future<void> _stopRecording() async {
//     try {
//       // 停止录音
//       final path = await _audioRecorder.stop();
//
//       if (path == null) {
//         print('录音停止失败');
//         return;
//       }
//
//       HapticFeedback.mediumImpact(); // 触觉反馈
//
//       if (_isCancelling) {
//         print('录音已取消');
//         // 删除取消的录音文件
//         try {
//           await File(path).delete();
//           print('已删除取消的录音文件');
//         } catch (e) {
//           print('删除文件失败: $e');
//         }
//       } else {
//         print('录音完成，时长: $_recordingSeconds秒, 路径: $path');
//
//         ISocketIOManager().sendAudioMessage(path, _recordingSeconds);
//
//         // // 发送录音消息
//         // final onMessageSend = Provider.of<OnMessageSendCallback?>(context, listen: false);
//         // if (onMessageSend != null) {
//         //   final audioFile = File(path);
//         //   final fileSize = await audioFile.length();
//         //
//         //   // onMessageSend(types.PartialAudio(
//         //   //   duration: _recordingSeconds,
//         //   //   name: '语音消息',
//         //   //   size: fileSize,
//         //   //   uri: path,
//         //   // ));
//         // }
//       }
//     } catch (e) {
//       print('录音停止失败: $e');
//     } finally {
//       setState(() {
//         _isRecording = false;
//         _isCancelling = false;
//         _isSending = false;
//       });
//       _pulseController.stop();
//       _stopRecordingTimer();
//     }
//   }
//
//   // 取消录音（上滑取消）
//   void _cancelRecording() {
//     if (_isRecording && !_isCancelling) {
//       setState(() => _isCancelling = true);
//       print('取消录音');
//     }
//   }
//
//   // 停止计时器
//   void _stopRecordingTimer() {
//     if (_recordingTimer.isActive) {
//       _recordingTimer.cancel();
//     }
//   }
// }
