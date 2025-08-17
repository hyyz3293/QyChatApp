// import 'dart:async';
// import 'dart:convert';
// import 'package:boilerplate/presentation/utils/global_utils.dart';
// import 'package:date_format/date_format.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
// import 'package:uuid/uuid.dart';
//
// import '../../ui/model/im_user_online.dart';
// import '../../ui/model/message_send_model.dart';
// import '../../ui/model/socket_im_message.dart';
// import '../dio/dio_client.dart';
//
// class SocketIoProtocol {
//   // Engine.IO 消息类型
//   static const open = '0';      // 连接打开
//   static const close = '1';     // 连接关闭
//   static const ping = '2';      // 心跳ping
//   static const pong = '3';      // 心跳pong
//   static const message = '4';   // 普通消息
//   static const upgrade = '5';   // 协议升级
//   static const noop = '6';      // 空操作
//
//   // Socket.IO 消息子类型
//   static const connect = '0';   // 命名空间连接
//   static const disconnect = '1';// 命名空间断开
//   static const event = '2';     // 事件消息
//   static const ack = '3';       // 应答消息
//   static const error = '4';     // 错误消息
//   static const binaryEvent = '5'; // 二进制事件
// }
//
// // sending	正在发送中	消息已开始发送但尚未离开你的设备（如网络较慢时卡在此状态）。
// // sent	已发送到服务器	消息已从你的设备成功发送至服务商服务器（对方设备尚未收到）。
// // delivered	已送达对方设备	服务器已将消息推送到对方手机/客户端（对方是否查看未知）。
// // seen	已被对方查看	对方在设备上打开了聊天窗口并看到了消息（显示已读回执）。
// // error	发送失败	消息因网络中断、对方号码无效、服务器问题等原因未能发出。
//
// class SocketIOManager {
//   static SocketIOManager? _instance;
//   io.Socket? _socket;
//   bool _isConnecting = false;
//   int _reconnectAttempt = 0;
//   Timer? _reconnectTimer;
//   late String _serverUrl;
//
//   // 心跳机制相关变量
//   Timer? _heartbeatTimer;        // 自定义心跳发送计时器
//   Timer? _heartbeatTimeoutTimer; // 自定义心跳超时计时器
//   final int _heartbeatInterval = 30; // 自定义心跳间隔(秒)
//   final int _heartbeatTimeout = 10;  // 自定义心跳超时时间(秒)
//   bool _isWaitingHeartbeatResponse = false; // 是否等待自定义心跳响应
//
//   // Socket.IO 标准 ping/pong 机制变量
//   Timer? _pingTimeoutTimer;       // 等待服务器 ping 的超时计时器
//   final int _pingTimeout = 30;    // 服务器 ping 超时时间(秒，建议与服务器保持一致)
//
//   bool isReturnMsg = false;
//
//
//   late StreamController<List<Message>> _messagesController;
//   late StreamController<Message> _updateController;
//
//   late StreamController<List<User>> _usersController;
//   late List<Message> _roomMessages = [];
//
//   late User _currentUser;
//
//   late int _currentUserId = -1;
//
//   // 获取当前用户
//   User get currentUser => _currentUser;
//
//   // 获取消息流
//   Stream<List<Message>> get messagesStream => _messagesController.stream;
//
//   // 获取消息流
//   Stream<Message> get updateStream => _updateController.stream;
//
//
//   // 获取用户流
//   Stream<List<User>> get usersStream => _usersController.stream;
//
//   Uuid _uuid = Uuid();
//
//   // 事件回调映射表
//   final Map<String, Function(dynamic)> _eventListeners = {};
//
//   // 私有构造函数
//   SocketIOManager._();
//
//   /// 获取单例实例（自动初始化）
//   factory SocketIOManager() {
//     _instance ??= SocketIOManager._();
//     _instance!._initSocket();
//     return _instance!;
//   }
//
//   /// 初始化Socket连接
//   void _initSocket() {
//     if (_isConnecting || _socket?.connected == true) return;
//
//     // 初始化消息和用户控制器
//     _messagesController = StreamController<List<Message>>.broadcast();
//     _updateController = StreamController<Message>.broadcast();
//     _usersController = StreamController<List<User>>.broadcast();
//     _roomMessages = [];
//
//     connect();
//   }
//
//   // 添加到这里 ↓
//   void dispose() {
//     disconnect();
//
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = null;
//
//     _heartbeatTimeoutTimer?.cancel();
//     _heartbeatTimeoutTimer = null;
//
//     _pingTimeoutTimer?.cancel();
//     _pingTimeoutTimer = null;
//
//     if (!_messagesController.isClosed) {
//       _messagesController.close();
//     }
//
//     if (!_usersController.isClosed) {
//       _usersController.close();
//     }
//
//     _eventListeners.clear();
//     _roomMessages.clear();
//     _instance = null;
//
//     print('♻️ SocketIOManager 资源已完全释放');
//   }
//
//   /// 连接到 Socket.IO 服务器
//   Future<void> connect() async {
//     if (_isConnecting || _socket?.connected == true) return;
//
//     _isConnecting = true;
//     _resetReconnect();
//
//     // 获取本地存储的连接参数
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var cid = sharedPreferences.getInt("cid");
//     var token = sharedPreferences.getString("token");
//     var userid = sharedPreferences.getInt("userId");
//     var accid = sharedPreferences.getString("accid");
//
//     _currentUserId = userid!;
//     _currentUser = User(id: "${userid}");
//
//     print("userId======${userid}");
//
//     // 构建连接URL和参数
//     String url = "wss://uat-ccc.qylink.com:9991/qy.im.socket.io/"
//         "?cid=$cid"
//         "&accid=$accid"
//         "&token=$token"
//         "&userid=$userid"
//         "&EIO=3"
//         "&transport=websocket";
//
//     printN("url: == ${url}");
//     _serverUrl = url;
//
//     try {
//       _socket = io.io(
//         'https://uat-ccc.qylink.com:9991',
//         io.OptionBuilder()
//             .setTransports(['websocket'])
//             .setPath('/qy.im.socket.io')
//             .setQuery({
//           'cid': '${cid}',
//           'accid': '$accid',
//           'token': '${token}',
//           'userid': '${userid}',
//           'EIO': '3',
//           'transport': 'websocket'
//         })
//             .enableForceNew()
//             .build(),
//       );
//
//       // 注册 Socket.IO 核心事件监听
//       _socket!
//         ..onConnect((_) {
//           print('✅ 连接成功');
//           _onConnected();
//         })
//         ..onDisconnect((_) {
//           print('❌ 断开连接');
//           _onDisconnected();
//         })
//         ..onError((data) => printN('❌ 错误: $data'))
//         ..on('msgContent', (data) => printN('📩 收到消息: $data'))
//         ..on('event', (data) => printN('📩 收到消息: $data'))
//         ..on('socket-im-communication', (data) {
//           printN('📩 收到消息: $data');
//           handleSocketMessage('$data');
//         })
//           // 监听服务器发送的 ping 事件，回复 pong
//         ..on('ping', (_) => _handleServerPing())
//           // 监听客户端发送 pong 后的确认（部分服务器会触发）
//         ..on('pong', (_) => _handleServerPongAck());
//          // 监听自定义心跳响应
//         //..on('heartbeat_response', (_) => _onHeartbeatResponse());
//
//       await _socket!.connect();
//     } catch (e) {
//       print('❌ Socket连接失败: $e');
//       _isConnecting = false;
//     }
//   }
//
//   /// 连接成功处理
//   void _onConnected() {
//     _isConnecting = false;
//     _resetReconnect();
//     //_startHeartbeatMechanisms(); // 启动所有心跳机制
//
//     if (!isReturnMsg) {
//       isReturnMsg = true;
//       sendOnlineMsg();
//     }
//   }
//
//   /// 断开连接处理
//   void _onDisconnected() {
//     _isConnecting = false;
//     _handleDisconnect();
//   }
//
//   // ---------------------- Socket.IO 标准 Ping/Pong 机制 ----------------------
//
//   /// 处理服务器发送的 ping，回复 pong
//   void _handleServerPing() {
//     print('🏓 收到服务器 ping，回复 pong');
//     // 回复 pong 给服务器（Socket.IO 要求客户端必须响应 ping）
//     _socket?.emit('pong');
//     // 重置 ping 超时计时器（证明服务器仍活跃）
//     _resetPingTimeoutTimer();
//   }
//
//   /// 处理服务器对 pong 的确认（可选，根据服务器实现）
//   void _handleServerPongAck() {
//     print('🏓 服务器确认收到 pong');
//     _resetPingTimeoutTimer();
//   }
//
//   /// 启动服务器 ping 超时检测
//   void _startPingTimeoutTimer() {
//     _pingTimeoutTimer?.cancel();
//     _pingTimeoutTimer = Timer(Duration(seconds: _pingTimeout), () {
//       print('⏰ 服务器长时间未发送 ping，连接可能已失效');
//       _socket?.disconnect(); // 主动断开并触发重连
//       _onDisconnected();
//     });
//   }
//
//   /// 重置服务器 ping 超时计时器
//   void _resetPingTimeoutTimer() {
//     _pingTimeoutTimer?.cancel();
//     _startPingTimeoutTimer();
//   }
//
//
//   // ---------------------- 消息接收处理-start ---------------------- //
//
//   /// 安全解析 socket 返回的非标准 JSON 消息
//   void handleSocketMessage(dynamic data) {
//     try {
//       if (data is Map<String, dynamic>) {
//         print("✅ 已是 Map，直接使用");
//         _handleData(data);
//       } else if (data is String) {
//         //String fixed = fixPseudoJson(data);
//         //Map<String, dynamic> parsed = jsonDecode(fixed);
//         var parsed = extractMsgContent(data);
//         _handleData(parsed);
//       } else {
//         print("⚠️ 不支持的数据类型: ${data.runtimeType}");
//       }
//     } catch (e, stack) {
//       print("❌ 解析失败: $e");
//       print(stack);
//     }
//   }
//
//   void _handleData(Map<String, dynamic> msgContent) {
//     //var msgContent = json['msgContent'];
//     print("✅ 消息内容: ${msgContent['sendName']}");
//
//     printN("_handleSocketIm  msgContent= ${msgContent}");
//     var msgBean = ImUserOnlineEvent.fromJson(msgContent);
//     String? enumType = msgBean.enumType;
//     String? type = msgBean.type;
//     String? msg = msgBean.msg;
//     String msgId = msgBean.msgId ?? "";
//     int? userId = msgBean.msgSendId ?? 0;
//     var dateTime = DateTime.now();
//
//     if (enumType != "") {
//       switch(enumType) {
//         case "imOnlineed":
//         //收到回复 自动进入转人工窗口
//           convertToHumanTranslation();
//           break;
//         case "imSeatReturnResult":
//           //非在线时间
//           var message = TextMessage(
//             createdAt: dateTime,
//             id: "${msgId}",
//             status: MessageStatus.sent,
//             text: "${msg}",
//             authorId: '${userId}',
//           );
//           _sendMessage(message);
//           break;
//         case "text":
//           //文本
//           msgId = msgBean.messId ?? "";
//           msg = msgBean.content;
//           // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
//           // msg = msg!.replaceAll(RegExp(r'</p>'), '');
//           var message = TextMessage(
//             createdAt: dateTime,
//             id: "${msgId}",
//             status: MessageStatus.sent,
//             text: "${msg}",
//             authorId: '${userId}',
//           );
//           _sendMessage(message);
//           break;
//         case "img":
//         //图片
//           msgId = msgBean.messId ?? "";
//           msg = msgBean.content;
//           var imgs = msgBean.imgs;
//           if (imgs!.length > 0) {
//             for(int i = 0; i < imgs.length; i++) {
//               var message = ImageMessage(
//                 createdAt: dateTime,
//                 id: "${msgId}",
//                 status: MessageStatus.sent,
//                 text: "${msg}",
//                 authorId: '${userId}', source: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}',
//               );
//               _sendMessage(message);
//             }
//           }
//
//           break;
//       }
//     } else if (type != "") {
//       switch(type) {
//         case "msg":
//           var message = TextMessage(
//             createdAt: dateTime,
//             id: "${msgId}",
//             status: MessageStatus.sent,
//             text: "${msg}",
//             authorId: '${userId}',
//           );
//
//           _sendMessage(message);
//
//           break;
//       }
//     }
//     }
//
//   Map<String, dynamic> extractMsgContent(String rawData) {
//     // 1. 找到 msgContent 的起始位置
//     int startIndex = rawData.indexOf('msgContent:');
//     if (startIndex == -1) return {};
//
//     // 2. 找到 msgContent 的开始大括号
//     int braceStartIndex = rawData.indexOf('{', startIndex);
//     if (braceStartIndex == -1) return {};
//
//     // 3. 使用栈匹配大括号以找到结束位置
//     int braceCount = 0;
//     int braceEndIndex = braceStartIndex;
//
//     for (int i = braceStartIndex; i < rawData.length; i++) {
//       if (rawData[i] == '{') {
//         braceCount++;
//       } else if (rawData[i] == '}') {
//         braceCount--;
//         if (braceCount == 0) {
//           braceEndIndex = i;
//           break;
//         }
//       }
//     }
//
//     // 4. 提取 msgContent 部分的字符串
//     String msgContentStr = rawData.substring(braceStartIndex, braceEndIndex + 1);
//
//     // // 5. 修复键名缺少引号的问题
//     // msgContentStr = msgContentStr.replaceAllMapped(
//     //   RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*):'),
//     //       (Match m) => '"${m.group(1)}":',
//     // );
//
//     // 6. 解析为 JSON 对象
//     try {
//       return jsonDecode(msgContentStr);
//     } catch (e) {
//       print('解析 JSON 失败: $e');
//       return {};
//     }
//   }
//
//   String fixPseudoJson(String input) {
//     // 移除控制字符
//     input = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[mGK]'), '');
//
//     printN("fixPseudoJson 1: ${input}");
//
//     // 修复 key: → "key":
//     input = input.replaceAllMapped(
//       RegExp(r'([{\s,])(\w+)\s*:'),
//           (match) => '${match[1]}"${match[2]}":',
//     );
//     printN("fixPseudoJson 2: ${input}");
//     // 修复 value 没有引号的情况（仅处理 event 和 accid 中的）
//     input = input.replaceAllMapped(
//       RegExp(r':\s*([a-zA-Z0-9_\-]+)([,}])'),
//           (match) {
//         // 如果值本身是数字，不加引号
//         final val = match[1]!;
//         final isNumeric = RegExp(r'^\d+$').hasMatch(val);
//         return isNumeric
//             ? ': $val${match[2]}'
//             : ': "$val"${match[2]}';
//       },
//     );
//     printN("fixPseudoJson 3: ${input}");
//     // 修复数组中的字符串（例：[3006_CUS_563] → ["3006_CUS_563"]）
//     input = input.replaceAllMapped(
//       RegExp(r'\[(\s*[a-zA-Z0-9_]+)\]'),
//           (match) => '["${match[1]!.trim()}"]',
//     );
//     printN("fixPseudoJson 4: ${input}");
//     return input;
//   }
//
//
//
//   // ---------------------- 消息接收处理-end ---------------------- //
//
//
//   // ---------------------- 其他原有方法 ----------------------
//
//   int get currentUserId => _currentUserId;
//
//   /// 处理断开连接（启动自定义重连）
//   void _handleDisconnect() {
//     if (_reconnectTimer?.isActive ?? false) return;
//
//     _reconnectAttempt++;
//     final delaySeconds = (_reconnectAttempt * _reconnectAttempt).clamp(1, 30);
//     print('⏳ 将在 ${delaySeconds}s 后尝试第 $_reconnectAttempt 次重连...');
//
//     _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
//       print('🔁 尝试重连...');
//       connect();
//     });
//   }
//
//   /// 重置重连状态
//   void _resetReconnect() {
//     _reconnectAttempt = 0;
//     _reconnectTimer?.cancel();
//     _reconnectTimer = null;
//   }
//
//   /// 发送消息
//   void send(String event, dynamic data) {
//     if (_socket?.connected != true) {
//       print('⚠️ 发送失败：未连接服务器');
//       return;
//     }
//     _socket?.emit(event, data);
//   }
//
//   /// 监听事件
//   void on(String event, Function(dynamic) callback) {
//     _eventListeners[event] = callback;
//   }
//
//   /// 移除监听
//   void off(String event) {
//     _eventListeners.remove(event);
//   }
//
//   /// 断开连接
//   void disconnect() {
//     _resetReconnect();
//     _socket?.disconnect();
//     _socket?.clearListeners();
//     _socket = null;
//     _isConnecting = false;
//     print('⛔ 主动断开连接');
//   }
//
//   /// 获取当前连接状态
//   bool get isConnected => _socket?.connected ?? false;
//
//   // 重新发送消息
//   void resendMessage(Message message) {
//     _updateMessageStatus(message.id, MessageStatus.sending);
//   }
//
//   // 更新消息状态
//   void _updateMessageStatus(String messageId, MessageStatus status) {
//     final index = _roomMessages.indexWhere((m) => m.id == messageId);
//     print("_updateMessageStatus==index=${index}");
//     print("_updateMessageStatus===${_roomMessages[index]}");
//
//     if (index != -1) {
//       final oldMessage = _roomMessages[index];
//       Message updatedMessage;
//
//       if (oldMessage is TextMessage) {
//         updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
//       } else if (oldMessage is ImageMessage) {
//         updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
//       } else if (oldMessage is AudioMessage) {
//         updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
//       } else {
//         return;
//       }
//       print("_updateMessageStatus===${updatedMessage.authorId}");
//       _roomMessages[index] = updatedMessage;
//       _messagesController.add(List.from(_roomMessages));
//     }
//   }
//
//   // 更新消息状态
//   void _updateMessageStatusNew(Message msg) {
//     _updateController.add(msg);
//   }
//
//   // 发送上线事件
//   Future<void> sendOnlineMsg() async {
//     printN("上线");
//
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var id = sharedPreferences.getInt("channel_id") ?? 0;
//     var type = sharedPreferences.getInt("channel_type") ?? 0;
//     var name = sharedPreferences.getString("channel_name") ?? "";
//     var accid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//
//     var bean = ImUserOnlineEvent();
//     bean.event = "IM-USER-ONLINE";
//     bean.channelName = name;
//     bean.channelId = id;
//     bean.channelType = type;
//     bean.enumType = "imUserOnline";
//     bean.type = 'notice';
//     bean.ip = '127.0.0.1';
//     bean.webUrl = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=0fa684c5166b4f65bba9231f071a756d";
//     bean.browserTitle = "在线客服";
//     bean.referrer = "";
//     bean.landing = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=0fa684c5166b4f65bba9231f071a756d";
//     bean.browser = "chrome";
//     bean.engine = "";
//     bean.terminal = "Win10";
//     String msg = json.encode(bean);
//
//     SocketIMMessage socketIMMessage = SocketIMMessage(
//         toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
//
//
//     _socket!.emit('socket-im-communication', socketIMMessage.toJson());
//   }
//
//   // 转人工
//   Future<void> convertToHumanTranslation() async {
//     printN("转人工");
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var accid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//     var bean = ImUserOnlineEvent();
//     bean.event = "IM-ACCESS-SEAT";
//     bean.type = 'notice';
//     bean.enumType = "imAccessSeat";
//     String msg = json.encode(bean);
//
//     SocketIMMessage socketIMMessage = SocketIMMessage(
//         toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
//     _socket!.emit('socket-im-communication', socketIMMessage.toJson());
//   }
//
//   // 发送文本消息
//   Future<void> sendTextMessage(String text) async {
//     if (text.isEmpty) return;
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var cid = sharedPreferences.getInt("cid") ?? 0;
//     var accid = sharedPreferences.getString("accid") ?? "";
//     var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     String msgId = '${_uuid.v4()}';
//     var dateTime = DateTime.now();
//     var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
//     ServiceMessageBean serviceMessageBean =
//
//     ServiceMessageBean(
//         type: 'chat',
//         from: '${accid}',
//         to: '${cpmpanyAccid}',
//         channelType: '${1}',
//         time: millisecondsSinceEpoch,
//         messId: msgId,
//         flow: 'out',
//         scene: 'p2p',
//         msgSendId: '${userId}',
//         msgSendType: 2, enumType: 'text', content: '${text}'
//     );
//
//     var message = TextMessage(
//       createdAt: dateTime,
//       id: msgId,
//       status: MessageStatus.sending,
//       text: text,
//       authorId: '${userId}',
//     );
//
//     _sendMessage(message);
//     printN("sendData====${message}");
//
//     var sendData = await DioClient().sendMessage(serviceMessageBean);
//     Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
//     if (sendData) {
//       printN("sendData=success= 更新 msg  ${msgId}" );
//       _updateMessageStatusNew(updatedMessage);
//     } else {
//       printN("sendData=fail= 更新 msg  ${msgId}" );
//
//       _updateMessageStatusNew(updatedMessage);
//     }
//     printN("sendData====${sendData}");
//   }
//
//   // 发送图片消息
//   Future<void> sendPictureMessage(String imgPath) async {
//     if (imgPath.isEmpty) return;
//
//     print("sendPictureMessage-----path= ${imgPath}");
//
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var cid = sharedPreferences.getInt("cid") ?? 0;
//     var accid = sharedPreferences.getString("accid") ?? "";
//     var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     String msgId = '${_uuid.v4()}';
//     var dateTime = DateTime.now();
//     var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
//
//
//     ServiceMessageBean serviceMessageBean =
//     ServiceMessageBean(
//         type: 'chat',
//         from: '${accid}',
//         to: '${cpmpanyAccid}',
//         channelType: '${1}',
//         time: millisecondsSinceEpoch,
//         messId: msgId,
//         flow: 'out',
//         scene: 'p2p',
//         msgSendId: '${userId}',
//         msgSendType: 2, enumType: 'text', content: '${imgPath}'
//     );
//
//     var message = ImageMessage(
//       createdAt: dateTime,
//       id: msgId,
//       status: MessageStatus.sending,
//       authorId: '${userId}',
//       source: '${imgPath}',
//     );
//
//     _sendMessage(message);
//     printN("sendData====${message}");
//
//     var sendData = await DioClient().uploadFile(imgPath);
//     printN("sendData====${sendData}");
//     Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
//     if (sendData) {
//       printN("sendData=success= 更新 msg  ${msgId}" );
//       _updateMessageStatusNew(updatedMessage);
//     } else {
//       printN("sendData=fail= 更新 msg  ${msgId}" );
//
//       _updateMessageStatusNew(updatedMessage);
//     }
//     printN("sendData====${sendData}");
//   }
//
//
//   // 发送视频消息
//   Future<void> sendVideoMessage(String imgPath) async {
//     if (imgPath.isEmpty) return;
//
//     print("sendPictureMessage-----path= ${imgPath}");
//
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var cid = sharedPreferences.getInt("cid") ?? 0;
//     var accid = sharedPreferences.getString("accid") ?? "";
//     var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     String msgId = '${_uuid.v4()}';
//     var dateTime = DateTime.now();
//     var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
//
//
//     ServiceMessageBean serviceMessageBean =
//     ServiceMessageBean(
//         type: 'chat',
//         from: '${accid}',
//         to: '${cpmpanyAccid}',
//         channelType: '${1}',
//         time: millisecondsSinceEpoch,
//         messId: msgId,
//         flow: 'out',
//         scene: 'p2p',
//         msgSendId: '${userId}',
//         msgSendType: 2, enumType: 'text', content: '${imgPath}'
//     );
//
//     var message = VideoMessage(
//       createdAt: dateTime,
//       id: msgId,
//       status: MessageStatus.sending,
//       authorId: '${userId}',
//       source: '${imgPath}',
//     );
//
//     _sendMessage(message);
//     printN("sendData====${message}");
//
//     var sendData = await DioClient().uploadFile(imgPath);
//     printN("sendData====${sendData}");
//     Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
//     if (sendData) {
//       printN("sendData=success= 更新 msg  ${msgId}" );
//       _updateMessageStatusNew(updatedMessage);
//     } else {
//       printN("sendData=fail= 更新 msg  ${msgId}" );
//
//       _updateMessageStatusNew(updatedMessage);
//     }
//     printN("sendData====${sendData}");
//   }
//
//
//   // 发送语音消息
//   Future<void> sendAudioMessage(String imgPath,int seconds) async {
//     if (imgPath.isEmpty) return;
//
//     print("sendPictureMessage-----path= ${imgPath}");
//
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var cid = sharedPreferences.getInt("cid") ?? 0;
//     var accid = sharedPreferences.getString("accid") ?? "";
//     var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//     var userId = sharedPreferences.getInt("userId") ?? 0;
//     String msgId = '${_uuid.v4()}';
//     var dateTime = DateTime.now();
//     var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
//
//
//     ServiceMessageBean serviceMessageBean =
//     ServiceMessageBean(
//         type: 'chat',
//         from: '${accid}',
//         to: '${cpmpanyAccid}',
//         channelType: '${1}',
//         time: millisecondsSinceEpoch,
//         messId: msgId,
//         flow: 'out',
//         scene: 'p2p',
//         msgSendId: '${userId}',
//         msgSendType: 2, enumType: 'text', content: '${imgPath}'
//     );
//
//     var message = AudioMessage(
//       createdAt: dateTime,
//       id: msgId,
//       status: MessageStatus.sending,
//       authorId: '${userId}',
//       source: '${imgPath}',
//       duration: Duration(seconds: seconds),
//     );
//
//     _sendMessage(message);
//     printN("sendData====${message}");
//
//     var sendData = await DioClient().uploadFile(imgPath);
//     printN("sendData====${sendData}");
//     Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
//     if (sendData) {
//       printN("sendData=success= 更新 msg  ${msgId}" );
//       _updateMessageStatusNew(updatedMessage);
//     } else {
//       printN("sendData=fail= 更新 msg  ${msgId}" );
//
//       _updateMessageStatusNew(updatedMessage);
//     }
//     printN("sendData====${sendData}");
//   }
//
//
//   // 发送消息的通用方法
//   void _sendMessage(Message message) {
//     try {
//       _addMessageToRoom(message);
//       printN("_sendMessage => ${message}");
//     } catch (e) {
//       printN('发送消息失败: $e');
//     }
//   }
//
//   // 添加消息到房间
//   void _addMessageToRoom(Message message) {
//     _roomMessages.insert(0, message);
//     _messagesController.add(List.from(_roomMessages));
//   }
//
// }