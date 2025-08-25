import 'dart:async';
import 'dart:convert';
import 'dart:convert' as convert;
import 'package:audioplayers/audioplayers.dart';
import 'package:qychatapp/models/data_models/chat_user.dart';
import 'package:qychatapp/presentation/utils/global_utils.dart';
import 'package:event_bus/event_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';
import '../../../models/data_models/message.dart';
import '../../../models/data_models/reply_message.dart';
import '../../../values/enumeration.dart';
import '../../constants/assets.dart';
import '../../ui/model/channel_config_model.dart';
import '../../ui/model/each_api_response.dart';
import '../../ui/model/file_model.dart';
import '../../ui/model/im_user_menu.dart';
import '../../ui/model/im_user_online.dart';
import '../../ui/model/image_bean.dart';
import '../../ui/model/message_send_model.dart';
import '../../ui/model/sence_config_model.dart';
import '../../ui/model/socket_im_message.dart';
import '../dio/dio_client.dart';
import '../service_locator.dart';

class SocketIoProtocol {
  // Engine.IO 消息类型
  static const open = '0';      // 连接打开
  static const close = '1';     // 连接关闭
  static const ping = '2';      // 心跳ping
  static const pong = '3';      // 心跳pong
  static const message = '4';   // 普通消息
  static const upgrade = '5';   // 协议升级
  static const noop = '6';      // 空操作

  // Socket.IO 消息子类型
  static const connect = '0';   // 命名空间连接
  static const disconnect = '1';// 命名空间断开
  static const event = '2';     // 事件消息
  static const ack = '3';       // 应答消息
  static const error = '4';     // 错误消息
  static const binaryEvent = '5'; // 二进制事件
}

// sending	正在发送中	消息已开始发送但尚未离开你的设备（如网络较慢时卡在此状态）。
// sent	已发送到服务器	消息已从你的设备成功发送至服务商服务器（对方设备尚未收到）。
// delivered	已送达对方设备	服务器已将消息推送到对方手机/客户端（对方是否查看未知）。
// seen	已被对方查看	对方在设备上打开了聊天窗口并看到了消息（显示已读回执）。
// error	发送失败	消息因网络中断、对方号码无效、服务器问题等原因未能发出。

class CSocketIOManager {
  static CSocketIOManager? _instance;
  io.Socket? _socket;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  late String _serverUrl;

  // 心跳机制相关变量
  Timer? _heartbeatTimer;        // 自定义心跳发送计时器
  Timer? _heartbeatTimeoutTimer; // 自定义心跳超时计时器
  final int _heartbeatInterval = 30; // 自定义心跳间隔(秒)
  final int _heartbeatTimeout = 10;  // 自定义心跳超时时间(秒)
  bool _isWaitingHeartbeatResponse = false; // 是否等待自定义心跳响应

  // Socket.IO 标准 ping/pong 机制变量
  Timer? _pingTimeoutTimer;       // 等待服务器 ping 的超时计时器
  final int _pingTimeout = 30;    // 服务器 ping 超时时间(秒，建议与服务器保持一致)

  bool isReturnMsg = false;


  late StreamController<Message> _messagesController;
  late StreamController<Message> _messagesController2;

  late StreamController<Message> _updateController;
  late EventBus eventBus;

  //late StreamController<List<User>> _usersController;
  late List<Message> _roomMessages = [];

  //late User _currentUser;

  late int _currentUserId = -1;

  late AudioPlayer _audioPlayer;


  // 获取当前用户
  //User get currentUser => _currentUser;

  // 获取消息流
  Stream<Message> get messagesStream => _messagesController.stream;

  Stream<Message> get messagesStream2 => _messagesController2.stream;


  // 获取消息流
  Stream<Message> get updateStream => _updateController.stream;

  Uuid _uuid = Uuid();
  bool _isPlaying = false;

  // 事件回调映射表
  final Map<String, Function(dynamic)> _eventListeners = {};

  bool isSendImg = false;
  bool isFirstImg = false;
  bool isWelcome = false;


  // 私有构造函数
  CSocketIOManager._();

  /// 获取单例实例（自动初始化）
  factory CSocketIOManager() {
    _instance ??= CSocketIOManager._();
    _instance!._initSocket();
    return _instance!;
  }

  bool socketConnect() {
    try {
      return  _socket!.connected;
    }catch(e) {}
    return false;
  }

  /// 初始化Socket连接
  void _initSocket() {
    if (_isConnecting || _socket?.connected == true) return;

    // 初始化消息和用户控制器
    _messagesController = StreamController<Message>.broadcast();
    _messagesController2 = StreamController<Message>.broadcast();

    _updateController = StreamController<Message>.broadcast();
    //_usersController = StreamController<List<User>>.broadcast();
    _roomMessages = [];
    _audioPlayer = AudioPlayer();
    eventBus = EventBus();
    connect();
  }

  // 添加到这里 ↓
  void dispose() {
    disconnect();

    _audioPlayer.dispose();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;

    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;

    if (!_messagesController.isClosed) {
      _messagesController.close();
    }

    if (!_messagesController2.isClosed) {
      _messagesController2.close();
    }
    // if (!_usersController.isClosed) {
    //   _usersController.close();
    // }

    _eventListeners.clear();
    _roomMessages.clear();
    _instance = null;

    print('♻️ SocketIOManager 资源已完全释放');
  }

  /// 连接到 Socket.IO 服务器
  Future<void> connect() async {
    if (_isConnecting || _socket?.connected == true) {
      if (_socket?.connected == true) {
        sendOnlineMsg();
      }
      return;
    }

    _isConnecting = true;
    _resetReconnect();

    // 获取本地存储的连接参数
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid");
    var token = sharedPreferences.getString("token");
    var userid = sharedPreferences.getInt("userId");
    var useridReal = sharedPreferences.getString("userIdReal");
    var accid = sharedPreferences.getString("accid");

    if (token == "")
      return;


    _currentUserId = userid!;
    //_currentUser = User(id: "${userid}");

    print("userId======${userid}");

    // 构建连接URL和参数
    String url = "wss://uat-ccc.qylink.com:9991/qy.im.socket.io/"
        "?cid=$cid"
        "&accid=$accid"
        "&token=$token"
        "&userid=$userid"
        "&EIO=3"
        "&transport=websocket";

    printN("url: == ${url}");
    _serverUrl = url;

    try {
      _socket = io.io(
        'https://uat-ccc.qylink.com:9991',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath('/qy.im.socket.io')
            .setQuery({
          'cid': '${cid}',
          'accid': '$accid',
          'token': '${token}',
          'userid': '${userid}',
          'EIO': '3',
          'transport': 'websocket'
        }).enableForceNew().build(),
      );

      // 注册 Socket.IO 核心事件监听
      _socket!
        ..onConnect((_) {
          print('✅ 连接成功');
          _onConnected();
        })
        ..onDisconnect((_) {
          print('❌ 断开连接');
          _onDisconnected();
        })
        ..onError((data) => printN('❌ 错误: $data'))
        ..on('msgContent', (data) => printN('📩 收到消息: $data'))
        ..on('event', (data) => printN('📩 收到消息: $data'))
        ..on('socket-im-communication', (data) {
          printN('📩 收到消息: $data');
          handleSocketMessage('$data');
        })
          // 监听服务器发送的 ping 事件，回复 pong
        ..on('ping', (_) => _handleServerPing())
          // 监听客户端发送 pong 后的确认（部分服务器会触发）
        ..on('pong', (_) => _handleServerPongAck());
         // 监听自定义心跳响应
        //..on('heartbeat_response', (_) => _onHeartbeatResponse());

      await _socket!.connect();
    } catch (e) {
      print('❌ Socket连接失败: $e');
      _isConnecting = false;
    }
  }

  Future<void> playAudio() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var isOpenSound = await sharedPreferences.getBool("sound") ?? true;
      if (!isOpenSound)
        return;
      if (_isPlaying)
        return;
      _isPlaying = true;
      await _audioPlayer.play(AssetSource('audio/ring.aac')); // 关键播放代码
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          print('播放完成');
          _isPlaying = false;
        }
      });
    } catch (e) {
      print("播放失败: $e");
    }
  }

  /// 连接成功处理
  void _onConnected() {
    _isConnecting = false;
    _resetReconnect();
    //_startHeartbeatMechanisms(); // 启动所有心跳机制

    //if (!isReturnMsg) {
      //isReturnMsg = true;
      sendOnlineMsg();
    //}
  }

  /// 断开连接处理
  void _onDisconnected() {
    _isConnecting = false;
    _handleDisconnect();
  }

  // ---------------------- Socket.IO 标准 Ping/Pong 机制 ----------------------

  /// 处理服务器发送的 ping，回复 pong
  void _handleServerPing() {
    print('🏓 收到服务器 ping，回复 pong');
    // 回复 pong 给服务器（Socket.IO 要求客户端必须响应 ping）
    _socket?.emit('pong');
    // 重置 ping 超时计时器（证明服务器仍活跃）
    _resetPingTimeoutTimer();
  }

  /// 处理服务器对 pong 的确认（可选，根据服务器实现）
  void _handleServerPongAck() {
    print('🏓 服务器确认收到 pong');
    _resetPingTimeoutTimer();
  }

  /// 启动服务器 ping 超时检测
  void _startPingTimeoutTimer() {
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = Timer(Duration(seconds: _pingTimeout), () {
      print('⏰ 服务器长时间未发送 ping，连接可能已失效');
      _socket?.disconnect(); // 主动断开并触发重连
      _onDisconnected();
    });
  }

  /// 重置服务器 ping 超时计时器
  void _resetPingTimeoutTimer() {
    _pingTimeoutTimer?.cancel();
    _startPingTimeoutTimer();
  }


  // ---------------------- 消息接收处理-start ---------------------- //

  /// 安全解析 socket 返回的非标准 JSON 消息
  void handleSocketMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        print("✅ 已是 Map，直接使用");
        _handleData(data);
      } else if (data is String) {
        //String fixed = fixPseudoJson(data);
        //Map<String, dynamic> parsed = jsonDecode(fixed);
        var parsed = extractMsgContent(data);
        _handleData(parsed);
      } else {
        print("⚠️ 不支持的数据类型: ${data.runtimeType}");
      }
    } catch (e, stack) {
      print("❌ 解析失败: $e");
      print(stack);
    }
  }

  Future<void> _handleData(Map<String, dynamic> msgContent) async {
    print("✅ 消息内容: ${msgContent['sendName']}");
    printN("_handleSocketIm  msgContent= ${msgContent}");
    var msgBean = ImUserOnlineEvent.fromJson(msgContent);
    String? enumType = msgBean.enumType;
    String? type = msgBean.type;
    String? msg = msgBean.msg;
    String msgId = msgBean.msgId ?? "";
    int? userId = msgBean.msgSendId ?? 0;
    String? sendName = msgBean.sendName;
    String? sendAvatar = msgBean.sendAvatar;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();


    if (!isFirstImg) {
      isFirstImg = true;
      var chat =  ChatUser(
        id: '${userId}',
        name: '${sendName}',
        profilePhoto: "${Assets.appImages}headImg6.png",
        imageType: ImageType.asset,
      );
      getIt<EventBus>().fire(chat);
    }


    if (!isSendImg && sendName != "" && sendAvatar != "") {
      isSendImg = true;
     var chat =  ChatUser(
       id: '${userId}',
       name: '${sendName}',
       profilePhoto: "${Endpoints.baseUrl}${sendAvatar}",
       imageType: ImageType.network,
     );
      getIt<EventBus>().fire(chat);
    }

    var dateTime = DateTime.now();
    printN("_handleSocketIm  enumType= ${enumType}");
    if (enumType != "") {
      var evaluationFlag = sharedPreferences.getInt("sharedPreferences");
      var serviceEvaluateTxt = sharedPreferences.getString("serviceEvaluateTxt");
      // //文本
      msgId = msgBean.messId ?? "";
      var message = Message(
        createdAt: dateTime,
        status: MessageStatus.delivered,
        message: "${serviceEvaluateTxt}",
        sentBy: '$userId',
        messageType: MessageType.overChat,
      );
      _sendMessage(message);

      switch(enumType) {

        case "imQueueNotice":
        playAudio();
        //文本
        msgId = msgBean.messId ?? "";
        var message = Message(
        createdAt: dateTime,
        status: MessageStatus.delivered,
        message: "开始排队",
        sentBy: '$userId',
        messageType: MessageType.overChat,
        );
        _sendMessage(message);
        break;
        case "imInvitationEvaluate":
        case "imCustomerOverChat":

          if (evaluationFlag != 0) {
            playAudio();

            sharedPreferences.setInt("serviceId", msgBean.serviceId ?? 0);

            //文本
            msgId = msgBean.messId ?? "";
            var message = Message(
              createdAt: dateTime,
              status: MessageStatus.delivered,
              message: "${serviceEvaluateTxt}",
              sentBy: '$userId',
              messageType: MessageType.overChat,
            );
            _sendMessage(message);
          }

          break;
        case "imUserOnline":
          playAudio();
          // //文本
          // msgId = msgBean.messId ?? "";
          // msg = "您好！有什么能帮助您的吗?";
          // // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          // var message = Message(
          //     createdAt: dateTime,
          //     //id: "${msgId}",
          //     status: MessageStatus.delivered,
          //     message: "${msg}",
          //     sentBy: '${userId}'
          //   //text: "${msg}",
          //   //user: ChatUser(id: '${userId}'),
          //   //authorId: '${userId}',
          // );
          // if (!isWelcome) {
          //   isWelcome = true;
          //   _sendMessage(message);
          // }
          sendSenseConfigMsg();
          break;
        case "imOnlineed":
        //收到回复 自动进入转人工窗口
          //convertToHumanTranslation();
          // msgId = msgBean.messId ?? "";
          // msg = "您好！有什么能帮助您的吗?";
          // // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          // var message = Message(
          //     createdAt: dateTime,
          //     //id: "${msgId}",
          //     status: MessageStatus.delivered,
          //     message: "${msg}",
          //     sentBy: '${userId}'
          //   //text: "${msg}",
          //   //user: ChatUser(id: '${userId}'),
          //   //authorId: '${userId}',
          // );
          // if (!isWelcome) {
          //   isWelcome = true;
          //   _sendMessage(message);
          // }
          sendSenseConfigMsg();
          playAudio();
          break;
        case "imSeatReturnResult":
          playAudio();
          //非在线时间
          var message = Message(
            createdAt: dateTime,
            //id: "${msgId}",
            status: MessageStatus.delivered,
            message: '${msg}',
            sentBy: '${userId}',
            //text: "${msg}",
            //authorId: '${userId}',
            //user: ChatUser(id: '${userId}'),
          );
          _sendMessage(message);
          break;

        case "complex":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          var complex = msgBean.complex;
          var message = Message(
              createdAt: dateTime,
              status: MessageStatus.delivered,
              message: "${convert.jsonEncode(complex)}",
              sentBy: '${userId}',
              messageType: MessageType.complex,
              complex: complex,
              digest: '${msgBean.digest}'
          );
          _sendMessage(message);
          break;

        case "navigation":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          var navigation = msgBean.navigationList;
          if (navigation!.isNotEmpty && navigation!.length > 0) {
            // for (int i = 0; i< navigation!.length;i++) {
            //
            //   printN("welcomeSpeec==== ${msgContent}");
            // }

          }
          var message = Message(
              createdAt: dateTime,
              //id: "${msgId}",
              status: MessageStatus.delivered,
              message: "${msgBean.title}",
              sentBy: '${userId}',
              messageType: MessageType.navigation,
              navigationList: navigation!.isNotEmpty ?navigation : []
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);

          break;
        case "welcomeSpeech":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          msg = "${msgBean.welcomeSpeech!.welcomeSpeech}";
          // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          var message = Message(
              createdAt: dateTime,
              //id: "${msgId}",
              status: MessageStatus.delivered,
              message: "${msg}",
              sentBy: '${userId}'
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);
          printN("welcomeSpeec==== ${msgContent}");
          break;

        case "link":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          var links = msgBean.links;
          if (links!.isNotEmpty && links!.length > 0) {
            // for (int i = 0; i< navigation!.length;i++) {
            //
            //   printN("welcomeSpeec==== ${msgContent}");
            // }
            var message = Message(
                createdAt: dateTime,
                //id: "${msgId}",
                status: MessageStatus.delivered,
                message: "${convert.jsonEncode(links)}",
                sentBy: '${userId}',
                messageType: MessageType.links,
                links: links
              //text: "${msg}",
              //user: ChatUser(id: '${userId}'),
              //authorId: '${userId}',
            );
            _sendMessage(message);
          }
          break;
        case "graphicText":
        case "imClick":
        case "navigation":
        case "knowGraphicText":
        case "navigation":
        case "text":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          msg = msgBean.content;
          // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          var message = Message(
            createdAt: dateTime,
            //id: "${msgId}",
            status: MessageStatus.delivered,
            message: "${msg}",
            sentBy: '${userId}'
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);
          break;
        case "media":
          playAudio();

          var video = '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${msgBean.conversationCode}';
          var message = Message(
              createdAt: dateTime,
              //id: "${msgId}",
              status: MessageStatus.delivered,
              message: '${video}',
              sentBy: '${userId}',
              messageType: MessageType.video
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);
          break;
        case "video":
          playAudio();
        //文本
          msgId = msgBean.messId ?? "";
          msg = msgBean.url;
          // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          var message = Message(
              createdAt: dateTime,
              //id: "${msgId}",
              status: MessageStatus.delivered,
              message: '${Endpoints.baseUrl}${msg}',
              sentBy: '${userId}',
              messageType: MessageType.video
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);
          break;
        case "voice":
          playAudio();
          //文本
          msgId = msgBean.messId ?? "";
          msg = msgBean.url;
          // msg = msg!.replaceAll(RegExp(r'<p[^>]*>'), '\n');
          // msg = msg!.replaceAll(RegExp(r'</p>'), '');
          var message = Message(
              createdAt: dateTime,
              //id: "${msgId}",
              status: MessageStatus.delivered,
              message: '${Endpoints.baseUrl}${msg}',
              sentBy: '${userId}',
              messageType: MessageType.voice
            //text: "${msg}",
            //user: ChatUser(id: '${userId}'),
            //authorId: '${userId}',
          );
          _sendMessage(message);
          break;
        case "image":
        case "img":
          playAudio();
        //图片
          msgId = msgBean.messId ?? "";
          msg = msgBean.content;
          var imgs = msgBean.imgs;
          if (imgs!.length > 0) {
            //List<ChatMedia> medias = [];
            for(int i = 0; i < imgs.length; i++) {
              // medias.add(ChatMedia(
              //   url: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}',
              //   type: MediaType.image,
              //   fileName: '',
              //   isUploading: false,
              // ));
              var message = Message(
                //medias: medias,
                  createdAt: dateTime,
                  //id: "${msgId}",
                  messageType: MessageType.image,
                  status: MessageStatus.delivered,
                  //authorId: '${userId}',
                  //source: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}'
                  //user: ChatUser(id: '${userId}'),
                  message: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}',
                  sentBy: '${userId}'
              );
              _sendMessage(message);
            }

            // var message = Message(
            //   //medias: medias,
            //   createdAt: dateTime,
            //   //id: "${msgId}",
            //     messageType: MessageType.image,
            //   status: MessageStatus.delivered,
            //   //authorId: '${userId}',
            //   //source: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}'
            //   //user: ChatUser(id: '${userId}'),
            //   message: '',
            //   sentBy: '${userId}'
            // );
            // _sendMessage(message);
          }
          break;
          //文件
        case "attached":
        case "attachment":
          playAudio();
          print(" attachment---->>>>");
          msgId = msgBean.messId ?? "";
          msg = msgBean.content;
          var attachment = msgBean.attachment;
          if (attachment!.length > 0) {
            for(int i = 0; i < attachment.length; i++) {
              var url = '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${attachment[i].code}';

              print(" attachment---->>>> ur l ==== ${url}");

              bool isAudio = isAudioFile(attachment[i].fileName);
              var message = Message(
                  createdAt: dateTime,
                  messageType: isAudio ? MessageType.voice : MessageType.file,
                  status: MessageStatus.delivered,
                  message: url,
                  sentBy: '${userId}'
              );
              _sendMessage(message);
            }
          }

          break;
      }
    } else if (type != "") {



      switch(type) {
        case "msg":
          playAudio();
          var message = Message(
            createdAt: dateTime,
            //id: "${msgId}",
            status: MessageStatus.delivered,
            // text: "${msg}",
            // //authorId: '${userId}',
            // user: ChatUser(id: '${userId}'),
            message: "${msg}", sentBy: '${userId}',
          );

          _sendMessage(message);

          break;
      }
    }
    }

  bool isAudioFile(String fileName) {
    const audioExtensions = {
      'mp3', 'wav', 'aac', 'ogg', 'flac',
      'm4a', 'wma', 'aiff', 'alac', 'opus',
      'mid', 'midi', 'amr', '3gp', 'ape'
    };

    // 处理无扩展名文件
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1) return false;

    // 提取扩展名并转为小写
    final ext = fileName.substring(lastDotIndex + 1).toLowerCase();

    return audioExtensions.contains(ext);
  }

  Map<String, dynamic> extractMsgContent(String rawData) {
    // 1. 找到 msgContent 的起始位置
    int startIndex = rawData.indexOf('msgContent:');
    if (startIndex == -1) return {};

    // 2. 找到 msgContent 的开始大括号
    int braceStartIndex = rawData.indexOf('{', startIndex);
    if (braceStartIndex == -1) return {};

    // 3. 使用栈匹配大括号以找到结束位置
    int braceCount = 0;
    int braceEndIndex = braceStartIndex;

    for (int i = braceStartIndex; i < rawData.length; i++) {
      if (rawData[i] == '{') {
        braceCount++;
      } else if (rawData[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          braceEndIndex = i;
          break;
        }
      }
    }

    // 4. 提取 msgContent 部分的字符串
    String msgContentStr = rawData.substring(braceStartIndex, braceEndIndex + 1);

    // // 5. 修复键名缺少引号的问题
    // msgContentStr = msgContentStr.replaceAllMapped(
    //   RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*):'),
    //       (Match m) => '"${m.group(1)}":',
    // );

    // 6. 解析为 JSON 对象
    try {
      return convert.jsonDecode(msgContentStr);
    } catch (e) {
      print('解析 JSON 失败: $e');
      return {};
    }
  }

  String fixPseudoJson(String input) {
    // 移除控制字符
    input = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[mGK]'), '');

    printN("fixPseudoJson 1: ${input}");

    // 修复 key: → "key":
    input = input.replaceAllMapped(
      RegExp(r'([{\s,])(\w+)\s*:'),
          (match) => '${match[1]}"${match[2]}":',
    );
    printN("fixPseudoJson 2: ${input}");
    // 修复 value 没有引号的情况（仅处理 event 和 accid 中的）
    input = input.replaceAllMapped(
      RegExp(r':\s*([a-zA-Z0-9_\-]+)([,}])'),
          (match) {
        // 如果值本身是数字，不加引号
        final val = match[1]!;
        final isNumeric = RegExp(r'^\d+$').hasMatch(val);
        return isNumeric
            ? ': $val${match[2]}'
            : ': "$val"${match[2]}';
      },
    );
    printN("fixPseudoJson 3: ${input}");
    // 修复数组中的字符串（例：[3006_CUS_563] → ["3006_CUS_563"]）
    input = input.replaceAllMapped(
      RegExp(r'\[(\s*[a-zA-Z0-9_]+)\]'),
          (match) => '["${match[1]!.trim()}"]',
    );
    printN("fixPseudoJson 4: ${input}");
    return input;
  }



  // ---------------------- 消息接收处理-end ---------------------- //


  // ---------------------- 其他原有方法 ----------------------

  int get currentUserId => _currentUserId;

  /// 处理断开连接（启动自定义重连）
  void _handleDisconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectAttempt++;
    final delaySeconds = (_reconnectAttempt * _reconnectAttempt).clamp(1, 30);
    print('⏳ 将在 ${delaySeconds}s 后尝试第 $_reconnectAttempt 次重连...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      print('🔁 尝试重连...');
      connect();
    });
  }

  /// 重置重连状态
  void _resetReconnect() {
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 发送消息
  void send(String event, dynamic data) {
    if (_socket?.connected != true) {
      print('⚠️ 发送失败：未连接服务器');
      return;
    }
    _socket?.emit(event, data);
  }

  /// 监听事件
  void on(String event, Function(dynamic) callback) {
    _eventListeners[event] = callback;
  }

  /// 移除监听
  void off(String event) {
    _eventListeners.remove(event);
  }

  /// 断开连接
  void disconnect() {
    _resetReconnect();
    _socket?.disconnect();
    _socket?.clearListeners();
    _socket = null;
    _isConnecting = false;
    print('⛔ 主动断开连接');
  }

  /// 获取当前连接状态
  bool get isConnected => _socket?.connected ?? false;

  // 重新发送消息
  void resendMessage(Message message) {
    //_updateMessageStatus(message.get, MessageStatus.sending);
  }

  // 更新消息状态
  void _updateMessageStatus(String messageId, MessageStatus status) {
    // final index = _roomMessages.indexWhere((m) => m.id == messageId);
    // print("_updateMessageStatus==index=${index}");
    // print("_updateMessageStatus===${_roomMessages[index]}");
    //
    // if (index != -1) {
    //   final oldMessage = _roomMessages[index];
    //   //ChatMessage updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
    //
    //   // if (oldMessage is TextMessage) {
    //   //   updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
    //   // } else if (oldMessage is ImageMessage) {
    //   //   updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
    //   // } else if (oldMessage is AudioMessage) {
    //   //   updatedMessage = oldMessage.copyWith(status: status, authorId: oldMessage.authorId);
    //   // } else {
    //   //   return;
    //   // }
    //   // print("_updateMessageStatus===${updatedMessage.authorId}");
    //   // _roomMessages[index] = updatedMessage;
    //   // _messagesController.add(List.from(_roomMessages));
    // }
  }

  // 更新消息状态
  void _updateMessageStatusNew(Message msg) {
    _updateController.add(msg);
  }

  //42["socket-im-communication",
  // {"msgContent":"{
  // \"event\":\"IM-CLICK\",
  // \"type\":\"notice\"
  // \"enumType\":\"imClick\",
  // \"msgSendId\":962,
  // \"msgSendType\":2,\
  // \"source\":1,
  // \"target\":\"1 \"
  // \"id\":\"18 \",\
  // "value\":\"多重，倒了后能不能搬得动？平时可以举起来健身吗?\"}","event":"socket-im-communication","toAccid":["3006_SYS"]}]
  // 场景配置项
  Future<void> sendSenseConfig(ChatMenuItem scene) async {
    printN("场景配置项");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var id = sharedPreferences.getInt("channel_id") ?? 0;
    var type = sharedPreferences.getInt("channel_type") ?? 0;
    var name = sharedPreferences.getString("channel_name") ?? "";
    var accid = sharedPreferences.getString("accid") ?? "";
    var channelCode = sharedPreferences.getString("channel_code");
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var userId = sharedPreferences.getInt("userId") ?? 0;


    var bean = ImUserOnlineEvent();
    bean.event = "IM-CLICK";
    bean.type = 'notice';
    bean.enumType = 'imClick';
    bean.msgSendId = cid;
    bean.msgSendType = 2;
    bean.source = 1;
    bean.target = 1;
    bean.id = "${scene.menuId}";
    bean.value = scene.menuTitle;

    String msg = json.encode(bean);

    SocketIMMessage socketIMMessage = SocketIMMessage(
        toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');

    printN("上线；；=accid=  ${accid}");


    printN("上线；；==  ${msg}");

    _socket!.emit('socket-im-communication', socketIMMessage.toJson());

    var message = Message(
      createdAt: DateTime.now(),
      //id: msgId,
      //status: MessageStatus.sending,
      message: '${scene.menuTitle}',
      sentBy: "$currentUserId",
      //authorId: '${userId}',
      //user:ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"),
    );

    _messagesController2.add(message);

  }


  Future<void> sendPress(ImEvaluationDefine item) async {
    printN("满意度////");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var id = sharedPreferences.getInt("channel_id") ?? 0;
    var type = sharedPreferences.getInt("channel_type") ?? 0;
    var name = sharedPreferences.getString("channel_name") ?? "";
    var accid = sharedPreferences.getString("accid") ?? "";
    var channelCode = sharedPreferences.getString("channel_code");
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var userId = sharedPreferences.getInt("userId") ?? 0;
    var serviceId = sharedPreferences.getInt("serviceId") ?? 0;

    // {"msgSendId":1085,
    // "msgSendType":2,
    // "event":"IM-EVALUATE",
    // "key":"1",
    // "value":"满意",
    // "serviceId":"1734",
    // "enumType":"evaluate",
    // "type":"notice"}
    // key对应pressKey
    // value对应pressValue
    // serviceId对应服务id

    var bean = ImUserOnlineEvent();
    bean.event = "IM-EVALUATE";
    bean.type = 'notice';
    bean.enumType = 'evaluate';
    bean.msgSendId = cid;
    bean.msgSendType = 2;
    bean.key = item.pressKey;
    bean.value = item.pressValue;
    bean.serviceId = serviceId;


    String msg = json.encode(bean);

    SocketIMMessage socketIMMessage = SocketIMMessage(
        toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');

    printN("上线；；=accid=  ${accid}");


    printN("上线；；==  ${msg}");

    _socket!.emit('socket-im-communication', socketIMMessage.toJson());

    var message = Message(
      createdAt: DateTime.now(),
      //id: msgId,
      //status: MessageStatus.sending,
      message: '${item.pressValue}',
      sentBy: "$currentUserId",
      //authorId: '${userId}',
      //user:ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"),
    );

    _messagesController2.add(message);

  }


  // 场景配置项
  Future<void> sendChatConfig(SenceConfigModel scene) async {
    printN("场景配置项");
    if (scene.id == -1){
      convertToHumanTranslation();
      return;
    }
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var id = sharedPreferences.getInt("channel_id") ?? 0;
    var type = sharedPreferences.getInt("channel_type") ?? 0;
    var name = sharedPreferences.getString("channel_name") ?? "";
    var accid = sharedPreferences.getString("accid") ?? "";
    var channelCode = sharedPreferences.getString("channel_code");
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var bean = ImUserOnlineEvent();
    bean.event = "IM-CLICK";
    bean.type = 'notice';
    bean.enumType = 'imClick';
    bean.msgSendId = cid;
    bean.msgSendType = 2;
    if (bean.type == "1") {
      bean.source = 2;
      bean.target = 1;
      bean.id = "${scene.value}";
    } else {
      bean.source = 2;
      bean.target = 1;
      bean.id = "${scene.value}";
    }
    bean.value = scene.name;
    String msg = json.encode(bean);
    SocketIMMessage socketIMMessage = SocketIMMessage(toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
    printN("场景配置项  CHat；；=accid=  ${accid}");
    printN("场景配置项 Chat ；；==  ${msg}");
    _socket!.emit('socket-im-communication', socketIMMessage.toJson());
    var message = Message(
      createdAt: DateTime.now(),
      message: scene.name,
      sentBy: "$currentUserId",
    );

    _messagesController2.add(message);
  }


  // 发送上线事件
  Future<void> sendOnlineMsg() async {
    printN("上线");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var id = sharedPreferences.getInt("channel_id") ?? 0;
    var type = sharedPreferences.getInt("channel_type") ?? 0;
    var name = sharedPreferences.getString("channel_name") ?? "";
    var accid = sharedPreferences.getString("accid") ?? "";
    var channelCode = sharedPreferences.getString("channel_code");

    var bean = ImUserOnlineEvent();
    bean.event = "IM-USER-ONLINE";
    bean.channelName = name;
    bean.channelId = id;
    bean.channelType = type;
    bean.enumType = "imUserOnline";
    bean.type = 'notice';
    bean.ip = '127.0.0.1';
    bean.webUrl = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=${channelCode}";
    bean.browserTitle = "在线客服";
    bean.referrer = "";
    bean.landing = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=${channelCode}";
    bean.browser = "chrome";
    bean.engine = "";
    bean.terminal = "Win10";
    String msg = json.encode(bean);

    SocketIMMessage socketIMMessage = SocketIMMessage(
        toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');

    printN("上线；；=accid=  ${accid}");


    printN("上线；；==  ${msg}");

    _socket!.emit('socket-im-communication', socketIMMessage.toJson());
  }

  // 发送场景信息
  Future<void> sendSenseConfigMsg() async {
    printN("场景 配置");

    //["socket-im-communication",
    // {"msgContent":"{\"event\":\"IM-SCENE-ACCESS\",
    // \"scene\":\"\",\
    // "location\":
    // \"https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=0fa684c5166b4f65bba9231f071a756d\"
    // ,\"cid\":3006,\"channel\":1,\"content\":\"\",
    // \"enumType\":\"accessMsg\",\"type\":\"notice\"}"
    // ,"event":"socket-im-communication","toAccid":["3006_SYS"]}]

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var id = sharedPreferences.getInt("channel_id") ?? 0;
    var type = sharedPreferences.getInt("channel_type") ?? 0;
    var name = sharedPreferences.getString("channel_name") ?? "";
    var accid = sharedPreferences.getString("accid") ?? "";
    var cid = sharedPreferences.getInt("cid") ?? 0;

    var channelCode = sharedPreferences.getString("channel_code");
    var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
    var bean = ImUserOnlineEvent();
    bean.event = "IM-SCENE-ACCESS";
    bean.scene = "";
    bean.location = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=${channelCode}";
    //bean.channelName = name;
    //bean.channelId = id;
    //bean.channelType = type;
    bean.enumType = "accessMsg";
    bean.type = 'notice';
    bean.cid  = cid;
    //bean.ip = '127.0.0.1';
    bean.content = "";

    //bean.webUrl = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=${channelCode}";
    //bean.browserTitle = "在线客服";
    //bean.referrer = "";
    //bean.landing = "https://uat-ccc.qylink.com:9991/static/im/mobileChannel.html?channelCode=${channelCode}";
    //bean.browser = "chrome";
    //bean.engine = "";
    //bean.terminal = "Win10";
    String msg = json.encode(bean);

    SocketIMMessage socketIMMessage = SocketIMMessage(
        toAccid: [cpmpanyAccid], event: 'socket-im-communication', msgContent: '${msg}');

    printN("场景 配置；；=accid=  ${cpmpanyAccid}");


    printN("场景 配置；；==  ${msg}");

    _socket!.emit('socket-im-communication', socketIMMessage.toJson());
  }

  // 转人工
  Future<void> convertToHumanTranslation() async {
    printN("转人工");
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var accid = sharedPreferences.getString("accid") ?? "";
    var bean = ImUserOnlineEvent();
    bean.event = "IM-ACCESS-SEAT";
    bean.type = 'notice';
    bean.enumType = "imAccessSeat";
    String msg = json.encode(bean);

    SocketIMMessage socketIMMessage = SocketIMMessage(
        toAccid: [accid], event: 'socket-im-communication', msgContent: '${msg}');
    _socket!.emit('socket-im-communication', socketIMMessage.toJson());
  }

  // 发送文本消息
  Future<void> sendMessage(String message,
      ReplyMessage replyMessage,
      MessageType messageType) async {
    if (messageType == MessageType.text) {
      sendTextMessage(message);
    } else if (messageType == MessageType.image) {
      sendPictureMessage(message);
    }else if (messageType == MessageType.video) {
      sendVideoMessage(message);
    }else if (messageType == MessageType.voice) {
      sendAudioMessage(message);
    }



  }


  // 发送文本消息
  Future<void> sendTextMessage(String text) async {
    if (text.isEmpty) return;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var accid = sharedPreferences.getString("accid") ?? "";
    var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
    var userId = sharedPreferences.getInt("userId") ?? 0;
    String msgId = '${_uuid.v4()}';
    var dateTime = DateTime.now();
    var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
    ServiceMessageBean serviceMessageBean =

    ServiceMessageBean(
        type: 'chat',
        from: '${accid}',
        to: '${cpmpanyAccid}',
        channelType: '${1}',
        time: millisecondsSinceEpoch,
        messId: msgId,
        flow: 'out',
        scene: 'p2p',
        msgSendId: '${userId}',
        msgSendType: 2, enumType: 'text', content: '${text}'
    );

    var message = Message(
      createdAt: dateTime,
      //id: msgId,
      //status: MessageStatus.sending,
      message: '${text}', sentBy: '$userId',
      //authorId: '${userId}',
      //user:ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"),
    );
    printN("sendData====${message}");
    var sendData = await DioClient().sendMessage(serviceMessageBean);
    printN("sendData====${sendData}");
  }

  // 发送图片消息
  Future<void> sendPictureMessage(String imgPath) async {
    if (imgPath.isEmpty) return;

    print("sendPictureMessage-----path= ${imgPath}");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var accid = sharedPreferences.getString("accid") ?? "";
    var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
    var userId = sharedPreferences.getInt("userId") ?? 0;
    String msgId = '${_uuid.v4()}';
    var dateTime = DateTime.now();
    var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;


    ServiceMessageBean serviceMessageBean =
    ServiceMessageBean(
        type: 'chat',
        from: '${accid}',
        to: '${cpmpanyAccid}',
        channelType: '${1}',
        time: millisecondsSinceEpoch,
        messId: msgId,
        flow: 'out',
        scene: 'p2p',
        msgSendId: '${userId}',
        msgSendType: 2,
        enumType: 'img', content: '${imgPath}',
    );

    var message = Message(
      // medias: <ChatMedia>[
      //   ChatMedia(
      //     url: '${imgPath}',
      //     type: MediaType.image,
      //     fileName: '',
      //     isUploading: false,
      //   ),
      // ],
      createdAt: dateTime,
      message: '${imgPath}',
      messageType: MessageType.image,
      sentBy: '${userId}',
      //id: msgId,
      //status: MessageStatus.sending,
      //authorId: '${userId}',
      //source: '${imgPath}',
      //user:ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"),
    );

   // _sendMessage(message);
    printN("sendData====${message}");

    var uploadFile = await DioClient().uploadFile(imgPath);
    printN("upload file ====${uploadFile}");

    final response = EnhancedApiResponse.fromJson(uploadFile,);
    List<ImageData>  imgs = [];
    if (response.data.isNotEmpty) {
      for (int i = 0; i < response.data.length;i++) {
        FileData fileData = response.data[i];
        ImageData data = ImageData(code: '${fileData.filecode}', src: '${fileData.filepath}', href: '', desc: '');
        imgs.add(data);
      }
    }

    serviceMessageBean.imgs = imgs;

    var sendMsg = await DioClient().sendMessage(serviceMessageBean);
    printN("sendMsg file ====${sendMsg}");

    // Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
    // if (sendData) {
    //   printN("sendData=success= 更新 msg  ${msgId}" );
    //   _updateMessageStatusNew(updatedMessage);
    // } else {
    //   printN("sendData=fail= 更新 msg  ${msgId}" );
    //
    //   _updateMessageStatusNew(updatedMessage);
    // }
  }


  // 发送视频消息
  Future<void> sendVideoMessage(String imgPath) async {
    if (imgPath.isEmpty) return;

    print("sendPictureMessage-----path= ${imgPath}");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var accid = sharedPreferences.getString("accid") ?? "";
    var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
    var userId = sharedPreferences.getInt("userId") ?? 0;
    String msgId = '${_uuid.v4()}';
    var dateTime = DateTime.now();
    var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;


    ServiceMessageBean serviceMessageBean =
    ServiceMessageBean(
        type: 'chat',
        from: '${accid}',
        to: '${cpmpanyAccid}',
        channelType: '${1}',
        time: millisecondsSinceEpoch,
        messId: msgId,
        flow: 'out',
        scene: 'p2p',
        msgSendId: '${userId}',
        msgSendType: 2, enumType: 'video', content: '${imgPath}',

    );

    // var message = VideoMessage(
    //   createdAt: dateTime,
    //   id: msgId,
    //   status: MessageStatus.sending,
    //   authorId: '${userId}',
    //   source: '${imgPath}',
    // );
    var message = Message(
      createdAt: dateTime,
      message: '${imgPath}',
      messageType: MessageType.custom,
      sentBy: '${userId}',

      //id: msgId,
      //status: MessageStatus.sent,
      //authorId: '${userId}',
      //source: '${imgPath}',
      //user:ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"), message: '',
    );

    //_sendMessage(message);
    printN("sendData====${message}");

    var uploadFile = await DioClient().uploadFile(imgPath);
    printN("upload file ====${uploadFile}");

    final response = EnhancedApiResponse.fromJson(uploadFile,);
    List<ImageData>  imgs = [];
    if (response.data.isNotEmpty) {
      for (int i = 0; i < response.data.length;i++) {
        FileData fileData = response.data[i];
        ImageData data = ImageData(code: '${fileData.filecode}', src: '${fileData.filepath}', href: '', desc: '');
        imgs.add(data);

        serviceMessageBean.code = fileData.filecode;
        serviceMessageBean.url = fileData.filepath;;
      }
    }
    serviceMessageBean.imgs = imgs;

    var sendMsg = await DioClient().sendMessage(serviceMessageBean);
    printN("sendMsg file ====${sendMsg}");
   }


  // 发送语音消息
  Future<void> sendAudioMessage(String imgPath) async {
    if (imgPath.isEmpty) return;

    print("sendPictureMessage-----path= ${imgPath}");

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid") ?? 0;
    var accid = sharedPreferences.getString("accid") ?? "";
    var cpmpanyAccid = sharedPreferences.getString("cpmpanyAccid") ?? "";
    var userId = sharedPreferences.getInt("userId") ?? 0;
    String msgId = '${_uuid.v4()}';
    var dateTime = DateTime.now();
    var millisecondsSinceEpoch = dateTime.millisecondsSinceEpoch;
    // var message = AudioMessage(
    //   createdAt: dateTime,
    //   id: msgId,
    //   status: MessageStatus.sending,
    //   authorId: '${userId}',
    //   source: '${imgPath}',
    //   duration: Duration(seconds: seconds),
    // );
    var message = Message(
      // medias: <ChatMedia>[
      //   ChatMedia(
      //     url: '${imgPath}',
      //     type: MediaType.file,
      //     fileName: '',
      //     isUploading: false,
      //   ),
      // ],
      createdAt: dateTime,
      message: '${imgPath}',
      messageType: MessageType.voice,
      sentBy: '${userId}',
      //id: msgId,
      //status: MessageStatus.sent,
      //authorId: '${userId}',
      //source: '${imgPath}',
      //user: ChatUser(id: '${userId}', lastName: "${userId}", firstName: "${userId}"),
    );

    //_sendMessage(message);
    printN("sendData==audio==${message}");

    var duration = await getAudioDuration(imgPath);

    var uploadFile = await DioClient().uploadFile(imgPath);
    printN("upload file ====${uploadFile}");
    printN("upload file ==duration==${duration}");

    ServiceMessageBean serviceMessageBean =
    ServiceMessageBean(
      type: 'chat',
      from: '${accid}',
      to: '${cpmpanyAccid}',
      channelType: '${1}',
      time: millisecondsSinceEpoch,
      messId: msgId,
      flow: 'out',
      scene: 'p2p',
      msgSendId: '${userId}',
      duration: duration,
      msgSendType: 2, enumType: 'voiceRecord', content: '${imgPath}',

    );
    final response = EnhancedApiResponse.fromJson(uploadFile,);
    List<ImageData>  imgs = [];
    if (response.data.isNotEmpty) {
      for (int i = 0; i < response.data.length;i++) {
        FileData fileData = response.data[i];
        ImageData data = ImageData(code: '${fileData.filecode}', src: '${fileData.filepath}', href: '', desc: '');
        imgs.add(data);

        serviceMessageBean.code = fileData.filecode;
        serviceMessageBean.url = fileData.filepath;;
      }
    }
    serviceMessageBean.imgs = imgs;

    var sendMsg = await DioClient().sendMessage(serviceMessageBean);
    printN("sendMsg file ====${sendMsg}");
    // Message updatedMessage = message.copyWith(status: MessageStatus.sent, authorId: message.authorId);
    // if (sendData) {
    //   printN("sendData=success= 更新 msg  ${msgId}" );
    //   _updateMessageStatusNew(updatedMessage);
    // } else {
    //   printN("sendData=fail= 更新 msg  ${msgId}" );
    //
    //   _updateMessageStatusNew(updatedMessage);
    // }
  }

  Future<int> getAudioDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      // 加载本地文件（网络音频用 player.setAudioSource(AudioSource.uri(Uri.parse(url))）
      await player.setSourceUrl(filePath);
      // 监听音频时长变化
      player.onDurationChanged.listen((Duration d) {
        print("音频长度: ${d.inMilliseconds} 毫秒");
        print("音频长度: ${d.inSeconds} 秒");
      });
      var di= await player.getDuration();
      return di!.inSeconds;
    } catch (e) {
      print("获取时长失败: $e");
      return 0;
    } finally {
      player.dispose(); // 释放资源
    }

  }


  // 发送消息的通用方法
  void _sendMessage(Message message) {
    try {
      _addMessageToRoom(message);
      printN("_sendMessage => ${message}");
    } catch (e) {
      printN('发送消息失败: $e');
    }
  }

  // 添加消息到房间
  void _addMessageToRoom(Message message) {
    // _roomMessages.insert(0, message);
    // _messagesController.add(List.from(_roomMessages));
    _messagesController.add(message);
    //eventBus.fire(MsgEvent(message));
  }

}