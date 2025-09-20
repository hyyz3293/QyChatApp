import 'dart:async';
import 'dart:convert';
import 'dart:convert' as convert;
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import '../../ui/model/attachment_bean.dart';
import '../../ui/model/channel_config_model.dart';
import '../../ui/model/complex_bean.dart';
import '../../ui/model/each_api_response.dart';
import '../../ui/model/file_model.dart';
import '../../ui/model/im_user_link.dart';
import '../../ui/model/im_user_menu.dart';
import '../../ui/model/im_user_online.dart';
import '../../ui/model/image_bean.dart';
import '../../ui/model/message_send_model.dart';
import '../../ui/model/sence_config_model.dart';
import '../../ui/model/socket_im_message.dart';
import '../../ui/model/user_account_model.dart';
import '../../ui/model/welcomeSpeech_bean.dart';
import '../dio/dio_client.dart';
import '../service_locator.dart';

// 定义重新加载数据的事件
class ReloadDataEvent {}


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

// 无在线客服事件类
class NoOnlineServiceEvent {
  final bool showNoService;
  
  NoOnlineServiceEvent(this.showNoService);
}

class CSocketIOManager {
  static CSocketIOManager? _instance;
  io.Socket? _socket;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  late String _serverUrl;
  // 连接尝试时间戳，用于限制连接频率
  int _lastConnectAttempt = 0;
  
  // 网络连接状态监听
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _wasConnected = false; // 记录上一次的连接状态

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

  bool isConfigMsg = false;

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
  CSocketIOManager._() {
    // 在构造函数中初始化 EventBus，确保只初始化一次
    eventBus = EventBus();
  }

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
    
    // 初始化网络状态监听
    _initConnectivityListener();
    
    // 检查连接状态，避免重复连接
    if (_socket?.connected != true) {
      printN("--connected-1");
      connect();
    } else {
      print('✅ 初始化时发现已连接，跳过连接');
    }
  }
  
  /// 初始化网络连接状态监听
  void _initConnectivityListener() {
    try {
      // 确保取消之前的订阅，避免重复监听
      if (_connectivitySubscription != null) {
        _connectivitySubscription!.cancel();
        _connectivitySubscription = null;
      }
      
      // 先检查当前网络状态
      Connectivity().checkConnectivity().then((List<ConnectivityResult> initialResults) {
        print('🌐 初始网络状态: $initialResults');
        _wasConnected = _socket?.connected ?? false;
        print('📡 初始连接状态: $_wasConnected');
      });
      
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        print('🌐 网络状态变化: $results');
        
        // 检查是否有任何连接可用
        bool hasConnection = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
        
        if (!hasConnection) {
          // 网络断开，记录状态
          _wasConnected = _socket?.connected ?? false;
          print('📵 网络已断开，之前连接状态: $_wasConnected');
        } else {
          // 网络恢复，检查连接状态后再决定是否重连
          print('🔌 网络已恢复，当前连接状态: ${_socket?.connected}');
          if (_socket?.connected != true && !_isConnecting) {
            print('🔄 网络恢复后尝试重新连接');
            // 在重连前调用ChartExternalScreen的loadData方法刷新数据
            //_reloadDataBeforeConnect();
          } else if (_socket?.connected == true) {
            print('✅ 网络恢复时发现已连接，跳过重连');
          } else if (_isConnecting) {
            print('⏳ 网络恢复时发现正在连接中，跳过重连');
          }
        }
      });
    } catch (e) {
      print('⚠️ 初始化网络监听失败: $e');
    }
  }
  
  // /// 在重连前触发数据重新加载
  // Future<void> _reloadDataBeforeConnect() async {
  //   try {
  //     print('📡 触发数据重新加载事件');
  //     // 发送重新加载数据事件
  //     eventBus.fire(ReloadDataEvent());
  //
  //     // 等待一段时间让数据加载完成
  //     await Future.delayed(Duration(milliseconds: 500));
  //
  //     // 然后再进行连接
  //     connect();
  //   } catch (e) {
  //     print('❌ 重新加载数据失败: $e');
  //     // 即使加载失败也尝试连接
  //     connect();
  //   }
  // }

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

  // 检查是否有有效的互联网连接
  Future<bool> isInternetAvailable() async {
    // 首先检查网络连接类型
    var connectivityResult = await Connectivity().checkConnectivity();

    // 如果没有网络连接，则肯定没有互联网
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return true;
  }

  /// 连接到 Socket.IO 服务器
  Future<void> connect() async {



    print('🔄 开始连接Socket...');

    bool _oin = await isInternetAvailable();
    // 检查WIFI状态
    if (!_oin) {
      print('⚠️ 无网络，跳过');
      return;
    }


    // 检查连接状态
    if (_isConnecting) {
      print('⚠️ 已有连接正在进行中，跳过');
      return;
    }
    
    if (_socket?.connected == true) {
      print('✅ 已连接，发送在线消息');
      sendOnlineMsg();
      return;
    }

    // 限制连接频率，至少间隔3秒
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastConnectAttempt < 3000) {
      print('🚫 连接请求过于频繁，已限流 (${(now - _lastConnectAttempt) / 1000}秒)');
      _isConnecting = false;
      return;
    }
    _lastConnectAttempt = now;
    
    _isConnecting = true;
    _resetReconnect();

    // 获取本地存储的连接参数
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var cid = sharedPreferences.getInt("cid");
    var token = sharedPreferences.getString("token");
    var userid = sharedPreferences.getInt("userId");
    var useridReal = sharedPreferences.getString("userIdReal");
    var accid = sharedPreferences.getString("accid");

    // 检查Token是否存在
    if (token == null || token.isEmpty) {
      print('❌ Token为空，尝试重新获取Token');
      try {
        // 尝试重新获取Token
        var userInfoJson = await DioClient().getUserinfoMessage();
        var userMap = userInfoJson["data"];
        var userAccount = UserAccountModel.fromJson(userMap);
        
        // 更新Token
        token = userAccount.token;
        sharedPreferences.setString("token", token);
        print('✅ 成功重新获取Token');
      } catch (e) {
        print('❌ 重新获取Token失败: $e');
        _isConnecting = false;
        return;
      }
    }
    
    // 再次检查Token
    if (token == null || token.isEmpty) {
      print('❌ Token仍然为空，取消连接');
      _isConnecting = false;
      return;
    }

    _currentUserId = userid!;
    print("🆔 userId: ${userid}");

    // 构建连接URL和参数
    String url = "wss://uat-ccc.qylink.com:9991/qy.im.socket.io/"
        "?cid=$cid"
        "&accid=$accid"
        "&token=$token"
        "&userid=$userid"
        "&EIO=3"
        "&transport=websocket";

    print("🔗 连接URL: ${url}");
    _serverUrl = url;

    // 设置连接超时
    Timer? connectionTimeout = Timer(Duration(seconds: 15), () {
      if (_socket?.connected != true) {
        print('⏱️ 连接超时，重置状态');
        _isConnecting = false;
      }
    });

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
      print('📡 注册Socket事件监听');
      _socket!
        ..onConnect((_) {
          print('✅ 连接成功');
          connectionTimeout?.cancel();
          _isConnecting = false;
          _onConnected();
        })
        ..onConnectError((data) {
          print('❌ 连接错误: $data');
          _isConnecting = false;
          
          // 连接错误时，彻底清理并重连
          print('🔄 连接错误，彻底清理后重连');
          
          // // 延迟后重新连接
          // Future.delayed(Duration(seconds: 2), () {
          //   _reloadDataBeforeConnect();
          // });
        })
        ..onDisconnect((_) {
          print('❌ 断开连接');
          _onDisconnected();
        })
        ..onError((data) {
          print('❌ 错误: $data');
          _isConnecting = false;
          
          // 发生错误时，彻底清理并重连
          print('🔄 发生错误，彻底清理后重连');
          
          // // 延迟后重新连接
          // Future.delayed(Duration(seconds: 2), () {
          //   _reloadDataBeforeConnect();
          // });
        })
        ..on('msgContent', (data) => print('📩 收到消息: $data'))
        ..on('event', (data) => print('📩 收到事件: $data'))
        ..on('socket-im-communication', (data) {
          print('📩 收到通信消息');
          handleSocketMessage('$data');
        })
        ..on('ping', (_) => _handleServerPing())
        ..on('pong', (_) => _handleServerPongAck());

      print('🔄 执行连接...');
      await _socket!.connect();
      print('🔄 连接命令已发送');
    } catch (e) {
      print('❌ Socket连接失败: $e');
      _isConnecting = false;
      connectionTimeout?.cancel();
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
    
    // 确保消息监听器正常工作
    print('✅ 连接成功，重新初始化消息监听');
    
    // 重新发送在线消息
    sendOnlineMsg();
    
    // 发送事件通知连接已恢复，让监听器重新注册
    print('📢 发送连接恢复事件');
    eventBus.fire(ReloadDataEvent());
  }

  /// 断开连接处理
  void _onDisconnected() {
    _isConnecting = false;
    _handleDisconnect();
  }
  
  /// 在重连前重新加载数据
  Future<void> _reloadDataBeforeConnect() async {
    print('🔄 重连前重新加载数据...');
    
    // 先彻底清理现有连接
    _forceCleanupSocket();
    
    try {
      // 使用EventBus发送重新加载数据的事件
      eventBus.fire(ReloadDataEvent());
      
      // 延迟一点时间等待数据加载和清理完成
      await Future.delayed(Duration(milliseconds: 2000));
      
      // 执行连接
      printN("--connected-2");
      connect();
    } catch (e) {
      print('❌ 重新加载数据失败: $e');
      // 即使加载失败也尝试连接
      printN("--connected-3");
      connect();
    }
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

  Future<void> handleEnumType({
    required String? enumType,
    required DateTime dateTime,
    required SharedPreferences sharedPreferences,
    int? evaluationFlag,
    String? serviceEvaluateTxt,
    // 以下为从ImUserOnlineEvent拆分出的非必传字段
    String? type,
    String? msg,
    String? msgId,
    String? messId,
    String? link,
    int? msgSendId,
    int? serviceId,
    ComplexData? complex, // 原msgBean.complex
    List<ChatMenuItem>? navigationList, // 原msgBean.navigationList
    String? title, // 原msgBean.title
    WelcomeSpeechData? welcomeSpeech, // 原msgBean.welcomeSpeech
    List<ChatLinkItem>? links, // 原msgBean.links
    String? content, // 原msgBean.content
    String? conversationCode, // 原msgBean.conversationCode
    String? url, // 原msgBean.url
    List<ImageData>? imgs, // 原msgBean.imgs
    List<AttachmentData>? attachment, // 原msgBean.attachment
    String? digest, // 原msgBean.digest
  }) async {
    // 从参数直接获取，无需再从msgBean获取
    int? userId = msgSendId ?? 0;

    switch(enumType) {
      case "imQueueNotice":
        playAudio();
        // 使用拆分后的messId字段
        msgId = messId ?? "";
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
          // 使用拆分后的serviceId字段
          sharedPreferences.setInt("serviceId", serviceId ?? 0);

          msgId = messId ?? "";
          var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "$serviceEvaluateTxt",
            sentBy: '$userId',
            messageType: MessageType.overChat,
          );
          _sendMessage(message);
        }
        break;

      case "imUserOnline":
        playAudio();
        if (!isConfigMsg) {
          isConfigMsg = true;
          sendSenseConfigMsg();
        }

        break;

      case "imOnlineed":
        // 防止重复处理imOnlineed事件导致循环连接
        printN("处理imOnlineed事件，当前isConfigMsg状态: $isConfigMsg");
        if (!isConfigMsg) {
          isConfigMsg = true;
          // 添加延迟，避免立即发送导致的循环
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_socket != null && _socket!.connected) {
              sendSenseConfigMsg();
            } else {
              printN("Socket未连接，跳过sendSenseConfigMsg调用");
            }
          });
        } else {
          printN("已经处理过imOnlineed事件，跳过重复处理");
        }
        playAudio();
        break;

      case "imSeatReturnResult":
        // 处理座席返回结果，通知UI显示"无在线客服"提示
        try {
          if (msg!.contains("无在线的客服")) {
            eventBus.fire(NoOnlineServiceEvent(true));
          } else {
            eventBus.fire(NoOnlineServiceEvent(false));
            msgId = messId ?? "";
            // 处理welcomeSpeech可能为null的情况
            var message = Message(
                createdAt: dateTime,
                status: MessageStatus.delivered,
                message: "$msg",
                sentBy: '$userId'
            );
            _sendMessage(message);
          }
        } catch (e) {
          print('解析 imSeatReturnResult 失败: $e');
        }
        break;

      case "complex":
        playAudio();
        msgId = messId ?? "";
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "${jsonEncode(complex)}",
            sentBy: '$userId',
            messageType: MessageType.complex,
            complex: complex,
            digest: '$digest'
        );
        _sendMessage(message);
        break;

      case "navigation":
        playAudio();
        msgId = messId ?? "";
        // 增加空安全判断，避免空指针
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "$title",
            sentBy: '$userId',
            messageType: MessageType.navigation,
            navigationList: navigationList
        );
        _sendMessage(message);
        break;
      case "knowGraphicText":
        playAudio();
        msgId = messId ?? "";

        printN("knowGraphicText imgs= ${imgs}");

        printN("knowGraphicText link= ${link}");
        // 增加空安全判断，避免空指针
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "$title",
            sentBy: '$userId',
            messageType: MessageType.knowGraphicText,
            imgs: imgs,
            link: link
        );
        _sendMessage(message);
        break;


      case "welcomeSpeech":
        playAudio();
        msgId = messId ?? "";
        // 处理welcomeSpeech可能为null的情况
        msg = "${welcomeSpeech?.welcomeSpeech ?? ""}";
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "$msg",
            sentBy: '$userId'
        );
        _sendMessage(message);
        break;

      case "link":
        playAudio();
        msgId = messId ?? "";
        if (links?.isNotEmpty ?? false) {
          var message = Message(
              createdAt: dateTime,
              status: MessageStatus.delivered,
              message: "${jsonEncode(links)}",
              sentBy: '$userId',
              messageType: MessageType.links,
              links: links
          );
          _sendMessage(message);
        }
        break;

      case "graphicText":
      case "imClick":
      case "text":
        playAudio();
        msgId = messId ?? "";
        msg = content; // 使用拆分后的content字段
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "$msg",
            sentBy: '$userId'
        );
        _sendMessage(message);
        break;

      case "media":
        playAudio();
        var video = '${Endpoints.baseUrlImg}${"/api/fileservice/file/preview/"}${conversationCode ?? ""}';
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: '$video',
            sentBy: '$userId',
            messageType: MessageType.video
        );
        _sendMessage(message);
        break;

      case "video":
        playAudio();
        msgId = messId ?? "";
        msg = url;
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: '${Endpoints.baseUrl}${url ?? ""}',
            sentBy: '$userId',
            messageType: MessageType.video
        );
        _sendMessage(message);
        break;

      case "voice":
        playAudio();
        msgId = messId ?? "";
        msg = url;
        var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: '${Endpoints.baseUrl}${url ?? ""}',
            sentBy: '$userId',
            messageType: MessageType.voice
        );
        _sendMessage(message);
        break;

      case "image":
      case "img":
        playAudio();
        msgId = messId ?? "";
        msg = content;
        // 空安全处理
        if (imgs?.isNotEmpty ?? false) {
          for(int i = 0; i < imgs!.length; i++) {
            var message = Message(
                createdAt: dateTime,
                messageType: MessageType.image,
                status: MessageStatus.delivered,
                message: '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${imgs[i].code}',
                sentBy: '$userId'
            );
            _sendMessage(message);
          }
        }
        break;

      case "attached":
      case "attachment":
        playAudio();
        msgId = messId ?? "";
        msg = content;
        if (attachment?.isNotEmpty ?? false) {
          for(int i = 0; i < attachment!.length; i++) {
            var url = '${Endpoints.baseUrl}${"/api/fileservice/file/preview/"}${attachment[i].code}';
            bool isAudio = isAudioFile(attachment[i].fileName);
            var message = Message(
                createdAt: dateTime,
                messageType: isAudio ? MessageType.voice : MessageType.file,
                status: MessageStatus.delivered,
                message: url,
                sentBy: '$userId'
            );
            _sendMessage(message);
          }
        }
        break;
    }
  }


// 修改后的 _handleData 方法
  Future<void> _handleData(Map<String, dynamic> msgContent) async {
    print("✅ 消息内容: ${msgContent['sendName']}");
    printN("_handleSocketIm  msgContent= $msgContent");

    var msgBean = ImUserOnlineEvent.fromJson(msgContent);
    String? enumType = msgBean.enumType;
    String? type = msgBean.type;
    int? userId = msgBean.msgSendId ?? 0;
    String? sendName = msgBean.sendName;
    String? sendAvatar = msgBean.sendAvatar;

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var evaluationFlag = sharedPreferences.getInt("sharedPreferences");
    var serviceEvaluateTxt = sharedPreferences.getString("serviceEvaluateTxt");

    if (!isFirstImg) {
      isFirstImg = true;
      var chat = ChatUser(
        id: '$userId',
        name: '$sendName',
        profilePhoto: "${Assets.appImages}headImg6.png",
        imageType: ImageType.asset,
      );
      getIt<EventBus>().fire(chat);
    }

    if (!isSendImg && sendName != "" && sendAvatar != "") {
      isSendImg = true;
      var chat = ChatUser(
        id: '$userId',
        name: '$sendName',
        profilePhoto: "${Endpoints.baseUrl}$sendAvatar",
        imageType: ImageType.network,
      );
      getIt<EventBus>().fire(chat);
    }

    var dateTime = DateTime.now();
    printN("_handleSocketIm  enumType= $enumType");

    if (enumType != "") {
      // 调用提取的方法
      await handleEnumType(
          enumType: enumType,
          dateTime: dateTime,
          sharedPreferences: sharedPreferences,
          evaluationFlag: evaluationFlag,
          serviceEvaluateTxt: serviceEvaluateTxt,

          // -------------------------- 从 msgBean 提取的所有非必传字段 --------------------------
          type: msgBean.type,                  // 消息类型（如 "notice"）
          msg: msgBean.msg,                    // 原始消息内容
          msgId: msgBean.msgId,                // 消息ID（msgBean 原有字段）
          messId: msgBean.messId,              // 消息ID（msgBean 原有字段，与 msgId 区分）
          msgSendId: msgBean.msgSendId,        // 消息发送者ID
          serviceId: msgBean.serviceId,        // 服务ID（评价相关）
          complex: msgBean.complex,            // 复杂消息数据（ComplexData 类型）
          navigationList: msgBean.navigationList, // 导航菜单列表（ChatMenuItem 类型）
          title: msgBean.title,                // 导航/消息标题
          welcomeSpeech: msgBean.welcomeSpeech, // 欢迎语数据（WelcomeSpeechData 类型）
          links: msgBean.links,                // 链接列表（ChatLinkItem 类型）
          content: msgBean.content,            // 文本/媒体内容
          conversationCode: msgBean.conversationCode, // 会话编码（媒体预览用）
          url: msgBean.url,                    // 媒体URL（视频/语音）
          imgs: msgBean.imgs,                  // 图片列表（ImageData 类型）
          attachment: msgBean.attachment,      // 附件列表（AttachmentData 类型）
          digest: msgBean.digest,               // 复杂消息摘要
          link: msgBean.link,
      );
    } else if (type != "") {
      switch(type) {
        case "msg":
          playAudio();
          var message = Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: "${msgBean.msg}",
            sentBy: '$userId',
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
    print('🔄 处理断开连接，彻底清理后重连');
    
    // 彻底清理现有连接
    _forceCleanupSocket();
    
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectAttempt++;
    final delaySeconds = (_reconnectAttempt * _reconnectAttempt).clamp(1, 30);
    print('⏳ 将在 ${delaySeconds}s 后尝试第 $_reconnectAttempt 次重连...');

    _reconnectTimer = Timer(Duration(seconds: 30), () {
      print('🔁 尝试重连...');
      printN("--connected-4");
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

  /// 彻底清理Socket连接和相关资源
  void _forceCleanupSocket() {
    print('🧹 开始彻底清理Socket连接...');
    
    // 取消所有定时器
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    _heartbeatTimeoutTimer?.cancel();
    _heartbeatTimeoutTimer = null;
    
    _pingTimeoutTimer?.cancel();
    _pingTimeoutTimer = null;
    
    // 强制断开Socket连接
    if (_socket != null) {
      try {
        _socket?.disconnect();
        _socket?.clearListeners();
        _socket?.dispose();
      } catch (e) {
        print('⚠️ 清理Socket时出错: $e');
      }
      _socket = null;
    }
    
    // 重置连接状态
    _isConnecting = false;
    _resetReconnect();
    
    // 清理事件监听器
    _eventListeners.clear();
    
    print('✅ Socket连接已彻底清理完成');
  }

  /// 断开连接
  void disconnect() {
    _forceCleanupSocket();
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

      var message = Message(
        createdAt: DateTime.now(),
        message: scene.name,
        sentBy: "$currentUserId",
      );

      _messagesController2.add(message);

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
    bean.channel = id;
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
  Future<bool> sendMessage(String message,
      ReplyMessage replyMessage,
      MessageType messageType) async {
    if (messageType == MessageType.text) {
      return await sendTextMessage(message);
    } else if (messageType == MessageType.image) {
      return await sendPictureMessage(message);
    }else if (messageType == MessageType.video) {
      return await sendVideoMessage(message);
    }else if (messageType == MessageType.voice) {
      return await sendAudioMessage(message);
    }
    return false;
  }


  // 发送文本消息
  Future<bool> sendTextMessage(String text) async {
    if (text.isEmpty) return false;
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
    return sendData;
  }

  // 发送图片消息
  Future<bool> sendPictureMessage(String imgPath) async {
    if (imgPath.isEmpty) return false;

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
    return sendMsg;

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
  Future<bool> sendVideoMessage(String imgPath) async {
    if (imgPath.isEmpty) return false;

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
    return sendMsg;
   }


  // 发送语音消息
  Future<bool> sendAudioMessage(String imgPath) async {
    if (imgPath.isEmpty) return false;

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
    return sendMsg;
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