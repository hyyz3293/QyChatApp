// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:qychatapp/presentation/ui/model/im_user_online.dart';
// import 'package:qychatapp/presentation/utils/dio/dio_client.dart';
// import 'package:flutter_chat_core/flutter_chat_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:uuid/uuid.dart';
//
// import '../../ui/model/message_send_model.dart';
// import '../../ui/model/socket_im_message.dart';
// import '../../ui/model/socket_root_message.dart';
// import '../global_utils.dart';
// // 连接状态枚举
// enum ConnectionStatus {
//   disconnected,
//   connecting,
//   connected,
//   reconnecting
// }
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
// class ChatManager {
//   static late User _currentUser;
//   static late WebSocketChannel _channel;
//   static late StreamController<List<Message>> _messagesController;
//   static late StreamController<List<User>> _usersController;
//   static bool _isInitialized = false;
//   static List<Message> _roomMessages = [];
//   static final Uuid _uuid = Uuid();
//   static List<User> _roomUsers = [];
//   static bool isReturnMsg = false;
//
//   // 重连机制相关属性
//   static bool _isReconnecting = false;
//   static int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 10;
//   static const Duration _initialReconnectDelay = Duration(seconds: 2);
//   static Timer? _reconnectTimer;
//   static Timer? _heartbeatTimer;
//   static ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
//
//
//
//   // 连接状态流
//   static final StreamController<ConnectionStatus> _connectionStatusController =
//   StreamController<ConnectionStatus>.broadcast();
//
//   static Stream<ConnectionStatus> get connectionStatusStream =>
//       _connectionStatusController.stream;
//
//   // 最后活动时间
//   static DateTime? _lastActivityTime;
//
//   static Future<void> initialize() async {
//     if (_isInitialized && _connectionStatus == ConnectionStatus.connected) return;
//
//     _updateConnectionStatus(ConnectionStatus.connecting);
//
//     try {
//       // 5. 模拟连接 WebSocket
//       SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//       var cid = sharedPreferences.getInt("cid");
//       var token = sharedPreferences.getString("token");
//       var userid = sharedPreferences.getInt("userId");
//       var accid = sharedPreferences.getString("accid");
//
//       // 1. 初始化用户和房间
//       _currentUser = User(
//         id: "${userid}",
//       );
//
//       // 2. 初始化消息控制器
//       _messagesController = StreamController<List<Message>>.broadcast();
//
//       // 3. 初始化用户控制器
//       _usersController = StreamController<List<User>>.broadcast();
//
//       // 4. 初始化消息列表和用户列表
//       _roomMessages = [];
//       _roomUsers = [_currentUser];
//
//       String url  = "wss://uat-ccc.qylink.com:9991/qy.im.socket.io/"
//           "?cid=$cid"
//           "&accid=$accid"
//           "&token=$token"
//           "&userid=$userid"
//           "&EIO=3"
//           "&transport=websocket";
//
//       var uri = Uri.parse(url);
//       print("uri= ${uri}");
//
//       // 创建新连接
//       _channel = IOWebSocketChannel.connect(
//         uri,
//         pingInterval: const Duration(seconds: 30),
//       );
//
//       // 重置重连状态
//       _isReconnecting = false;
//       _reconnectAttempts = 0;
//       _reconnectTimer?.cancel();
//
//       // 监听来自服务器的消息
//       _channel.stream.listen(
//         _handleSocketData,
//         onError: (error) {
//           print("WebSocket错误: $error");
//           _addSystemMessage('连接错误: ${error.toString()}');
//           _handleDisconnection();
//         },
//         onDone: () {
//           print("WebSocket连接关闭，原因：${_channel.closeCode} ${_channel.closeReason}");
//
//           print("WebSocket连接关闭");
//           _addSystemMessage('连接已断开');
//           _handleDisconnection();
//         },
//       );
//
//       // 添加欢迎消息
//       _addSystemMessage('欢迎来到聊天室!');
//       _isInitialized = true;
//       _updateConnectionStatus(ConnectionStatus.connected);
//
//       // 启动心跳
//       _startHeartbeat();
//
//       // 记录活动时间
//       _lastActivityTime = DateTime.now();
//     } catch (e) {
//       print('初始化失败: $e');
//       _handleDisconnection();
//       rethrow;
//     }
//   }
//
//   // 处理Socket数据
//   static void _handleSocketData(dynamic data) {
//     try {
//       print('收到服务器消息: $data');
//
//       // 重置重连计数器
//       if (_isReconnecting) {
//         _reconnectAttempts = 0;
//         _isReconnecting = false;
//         _reconnectTimer?.cancel();
//       }
//
//       // 更新最后活动时间
//       _lastActivityTime = DateTime.now();
//
//       if (!isReturnMsg) {
//         isReturnMsg = true;
//         sendOnlineMsg();
//       }
//
//       try {
//         print('原始协议消息: $data');
//
//         if (data is! String || data.isEmpty) {
//           print('⚠️ 无效消息格式');
//           return;
//         }
//
//         // 解析消息前缀
//         final prefix = data[0];
//         final content = data.substring(1);
//
//         switch (prefix) {
//           case SocketIoProtocol.open:
//             _handleOpenMessage(content);
//             break;
//
//           case SocketIoProtocol.ping:
//             _handlePing();
//             break;
//
//           case SocketIoProtocol.message:
//             _handleDataMessage(content);
//             break;
//
//           case SocketIoProtocol.pong:
//             _handlePong();
//             break;
//
//           default:
//             print('⚠️ 未知协议前缀: $prefix');
//         }
//
//       } catch (e) {
//         print('协议解析错误: $e');
//       }
//     } catch (e) {
//       print('消息解析错误: $e');
//       _addSystemMessage('收到无效消息');
//     }
//   }
//
//   static int _pingInterval = 25000; // 默认25秒
//   static int _pingTimeout = 60000;  // 默认60秒
//
//   static void _handleOpenMessage(String content) {
//     print('🔓 连接已建立: $content');
//     final json = jsonDecode(content) as Map<String, dynamic>;
//
//     // 获取服务器配置的心跳参数
//     final pingInterval = (json['pingInterval'] as int? ?? 25000);
//     final pingTimeout = (json['pingTimeout'] as int? ?? 60000);
//
//     // 更新心跳配置
//     _configureHeartbeat(pingInterval, pingTimeout);
//
//     // 发送连接确认
//     //_sendConnectAck();
//   }
//
//   static void _configureHeartbeat(int interval, int timeout) {
//     _pingInterval = interval;
//     _pingTimeout = timeout;
//
//     print('⚙️ 心跳配置: ${interval}ms ping, ${timeout}ms 超时');
//
//     // 启动心跳
//     _startHeartbeat();
//   }
//
//   static void _handlePing() {
//     print('❤️ 收到Ping请求');
//     // 立即回复Pong
//     _channel.sink.add(SocketIoProtocol.pong);
//     _lastActivityTime = DateTime.now();
//   }
//
//   static void _handlePong() {
//     print('❤️ 收到Pong响应');
//     _lastActivityTime = DateTime.now();
//   }
//
//   static void _handleDataMessage(String content) {
//     if (content.isEmpty) return;
//
//     // 解析嵌套协议
//     final subPrefix = content[0];
//     final jsonContent = content.substring(1);
//
//     switch (subPrefix) {
//       case SocketIoProtocol.event:
//         _handleEventMessage(jsonContent);
//         break;
//
//       case SocketIoProtocol.connect:
//         print('🔌 命名空间已连接');
//         break;
//
//       default:
//         print('📦 收到数据消息: $jsonContent');
//         try {
//           final json = jsonDecode(jsonContent) as Map<String, dynamic>;
//           // 原始消息处理逻辑...
//         } catch (e) {
//           print('JSON解析错误: $e');
//         }
//     }
//   }
//
//   static void _handleEventMessage(String content) {
//     try {
//       final data = jsonDecode(content) as List;
//       if (data.length < 2) return;
//
//       final eventName = data[0] as String;
//       final eventData = data[1] as Map<String, dynamic>;
//
//       print('📡 收到事件: $eventName');
//
//       // 处理特定事件
//       if (eventName == 'text') {
//         final message = TextMessage.fromJson(eventData);
//         _addMessageToRoom(message);
//       }
//       // 其他事件处理...
//
//     } catch (e) {
//       print('事件解析错误: $e');
//     }
//   }
//
//
//   // 处理断开连接
//   static void _handleDisconnection() {
//
//     printN("_handleDisconnection");
//
//
//     if (_isReconnecting) return;
//
//     _updateConnectionStatus(ConnectionStatus.reconnecting);
//     _isReconnecting = true;
//     _reconnectAttempts = 0;
//
//     // 清除旧定时器
//     _reconnectTimer?.cancel();
//
//     // 启动重连
//     _scheduleReconnect();
//   }
//
//   // 调度重连
//   static void _scheduleReconnect() {
//     if (_reconnectAttempts >= _maxReconnectAttempts) {
//       print('⚠️ 达到最大重连次数 ($_maxReconnectAttempts)，停止重连');
//       _isReconnecting = false;
//       _updateConnectionStatus(ConnectionStatus.disconnected);
//       return;
//     }
//
//     // 指数退避策略
//     final delay = _initialReconnectDelay * pow(2, _reconnectAttempts);
//     _reconnectAttempts++;
//
//     print('⏱️ 将在 ${delay.inSeconds} 秒后尝试重连 (尝试 $_reconnectAttempts/$_maxReconnectAttempts)');
//
//     _reconnectTimer = Timer(delay, () async {
//       try {
//         print('🔄 尝试重新连接...');
//         _updateConnectionStatus(ConnectionStatus.reconnecting);
//
//         // 重新初始化
//         await initialize();
//
//         _isReconnecting = false;
//         print('✅ 重连成功');
//         _updateConnectionStatus(ConnectionStatus.connected);
//       } catch (e) {
//         print('❌ 重连失败: $e');
//         _scheduleReconnect();
//       }
//     });
//   }
//
//   // 启动心跳检测
//   static void _startHeartbeat() {
//     _heartbeatTimer?.cancel();
//
//     _heartbeatTimer = Timer.periodic(Duration(seconds: 25), (timer) {
//       if (_connectionStatus != ConnectionStatus.connected) {
//         return;
//       }
//
//       try {
//         // 检查活动状态
//         final idleDuration = DateTime.now().difference(_lastActivityTime!);
//         if (idleDuration > Duration(minutes: 1)) {
//           print('💤 连接空闲超过1分钟，发送保持活跃消息');
//           //_channel.sink.add('{"type":"keepalive"}');
//         }
//
//         // 发送心跳
//         final payload = jsonEncode([{"type": "ping", "data": 1}]);
//         String data ='${2}$payload';
//         printN("心跳：" + data);
//         _channel.sink.add("2");
//
//         print('💓 发送心跳');
//       } catch (e) {
//         print('心跳发送失败: $e');
//         _handleDisconnection();
//       }
//     });
//   }
//
//   // 更新连接状态
//   static void _updateConnectionStatus(ConnectionStatus status) {
//     _connectionStatus = status;
//     _connectionStatusController.add(status);
//   }
//
//   static void _addSystemMessage(String text) {
//     // 系统消息实现...
//   }
//
//   // 添加消息到房间
//   static void _addMessageToRoom(Message message) {
//     _roomMessages.insert(0, message);
//     _messagesController.add(List.from(_roomMessages));
//
//     // 更新活动时间
//     _lastActivityTime = DateTime.now();
//   }
//
//   // 添加用户到房间
//   static void _addUserToRoom(User user) {
//     // 实现...
//   }
//
//   // 从房间移除用户
//   static void _removeUserFromRoom(String userId) {
//     // 实现...
//   }
//
//   // 邀请用户加入房间
//   static void inviteUserToRoom(User user) {
//     // 实现...
//   }
//
//   // 当前用户离开房间
//   static void leaveRoom() {
//     // 实现...
//   }
//
//   // 发送文本消息
//   static Future<void> sendTextMessage(String text) async {
//     // 检查连接状态
//     if (_connectionStatus != ConnectionStatus.connected) {
//       print('⚠️ 发送消息前尝试重新连接...');
//       await reconnect();
//     }
//
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
//     final message = TextMessage(
//       createdAt: dateTime,
//       id: msgId,
//       status: MessageStatus.sending,
//       text: text, authorId: '${userId}',
//     );
//
//     _sendMessage(message);
//
//     var sendData = await DioClient().sendMessage(serviceMessageBean);
//     printN("sendData====${sendData}");
//   }
//
//   // 手动重连方法
//   static Future<void> reconnect() async {
//     if (_isReconnecting) return;
//
//     print('🔁 手动触发重连');
//     _updateConnectionStatus(ConnectionStatus.reconnecting);
//     _reconnectAttempts = 0;
//
//     try {
//       // 关闭旧连接
//       await _channel.sink.close();
//     } catch (e) {
//       print('关闭旧连接失败: $e');
//     }
//
//     _scheduleReconnect();
//   }
//
//   // 发送消息的通用方法
//   static void _sendMessage(Message message) {
//     try {
//       _addMessageToRoom(message);
//       printN("_sendMessage => ${message}");
//     } catch (e) {
//       printN('发送消息失败: $e');
//       _addSystemMessage('发送失败');
//     }
//   }
//
//   // 重新发送消息
//   static void resendMessage(Message message) {
//     _updateMessageStatus(message.id, MessageStatus.sending);
//     _sendMessage(message);
//   }
//
//   // 更新消息状态
//   static void _updateMessageStatus(String messageId, MessageStatus status) {
//     final index = _roomMessages.indexWhere((m) => m.id == messageId);
//     if (index != -1) {
//       final oldMessage = _roomMessages[index];
//       Message updatedMessage;
//
//       if (oldMessage is TextMessage) {
//         updatedMessage = oldMessage.copyWith(status: status);
//       } else if (oldMessage is ImageMessage) {
//         updatedMessage = oldMessage.copyWith(status: status);
//       } else if (oldMessage is AudioMessage) {
//         updatedMessage = oldMessage.copyWith(status: status);
//       } else {
//         return;
//       }
//
//       _roomMessages[index] = updatedMessage;
//       _messagesController.add(List.from(_roomMessages));
//     }
//   }
//
//   // 获取当前用户
//   static User get currentUser => _currentUser;
//
//   // 获取消息流
//   static Stream<List<Message>> get messagesStream => _messagesController.stream;
//
//   // 获取用户流
//   static Stream<List<User>> get usersStream => _usersController.stream;
//
//   static void dispose() {
//     try {
//       _reconnectTimer?.cancel();
//       _heartbeatTimer?.cancel();
//       _isReconnecting = false;
//
//       _channel.sink.close();
//       _messagesController.close();
//       _usersController.close();
//       _connectionStatusController.close();
//
//       _isInitialized = false;
//       _roomMessages.clear();
//       _roomUsers.clear();
//
//       _updateConnectionStatus(ConnectionStatus.disconnected);
//     } catch (e) {
//       print('释放资源失败: $e');
//     }
//   }
//
//   // 根据ID获取用户
//   static User? getUserById(String id) {
//     try {
//       return _roomUsers.firstWhere((user) => user.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
//
//
//
//   // 发送事件
//   static void sendEvent(String title, String eventName, Map<String, dynamic> data) {
//     // 确保连接正常
//     if (_connectionStatus != ConnectionStatus.connected) {
//       print('⚠️ 发送事件时连接未就绪');
//       return;
//     }
//
//     try {
//       final payload = jsonEncode([eventName, data]);
//       _channel.sink.add('${title}$payload');
//       print('📤 发送事件: $eventName');
//
//       // 更新活动时间
//       _lastActivityTime = DateTime.now();
//     } catch (e) {
//       print('发送事件失败: $e');
//       _handleDisconnection();
//     }
//   }
//
//   // 发送上线事件
//   static Future<void> sendOnlineMsg() async {
//     // 确保连接状态正常
//     if (_connectionStatus != ConnectionStatus.connected) {
//       print('⏳ 发送上线消息前等待连接...');
//       await initialize();
//     }
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
//
//     bean.enumType = "imUserOnline";
//     bean.type = 'notice';
//     bean.ip = '127.0.0.1';
//     bean.webUrl = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=0fa684c5166b4f65bba9231f071a756d";
//     bean.browserTitle =  "在线客服";
//     bean.referrer = "";
//     bean.landing =  "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=0fa684c5166b4f65bba9231f071a756d";
//     bean.browser = "chrome";
//     bean.engine = "";
//     bean.terminal = "Win10";
//     String msg = json.encode(bean);
//
//     SocketIMMessage socketIMMessage = SocketIMMessage(
//         toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
//
//     sendEvent("42", "socket-im-communication", socketIMMessage.toJson());
//   }
//
//   // 转人工
//   //42["socket-im-communication",
//   // {"msgContent":"{\"event\":\"IM-ACCESS-SEAT\",\
//   // "enumType\":\"imAccessSeat\",\"type\":\"notice\"}","event":"socket-im-communication","toAccid":["3006_SYS"]}]
//
//   static Future<void> convertToHumanTranslation() async {
//     // 确保连接状态正常
//     if (_connectionStatus != ConnectionStatus.connected) {
//       print('⏳ 发送上线消息前等待连接...');
//       await initialize();
//     }
//
//     SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
//     var accid = sharedPreferences.getString("cpmpanyAccid") ?? "";
//
//     var bean = ImUserOnlineEvent();
//     bean.event = "IM-ACCESS-SEAT";
//     bean.type = 'notice';
//     bean.enumType = "imAccessSeat";
//     String msg = json.encode(bean);
//
//     SocketIMMessage socketIMMessage = SocketIMMessage(
//         toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
//
//     sendEvent("42", "socket-im-communication", socketIMMessage.toJson());
//   }
//
// }