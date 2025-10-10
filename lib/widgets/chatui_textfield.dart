import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' show File, Platform;
import 'package:file_picker/file_picker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qychatapp/presentation/ui/model/sence_config_model.dart';
import 'package:qychatapp/utils/constants/constants.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qychatapp/presentation/utils/routes/routes.dart';
import 'package:go_router/go_router.dart';
import '../models/config_models/send_message_configuration.dart';
import '../presentation/utils/global_utils.dart';
import '../presentation/utils/service_locator.dart';
import '../presentation/utils/websocket/chat_socket_manager.dart';
import '../utils/debounce.dart';
import '../utils/package_strings.dart';
import '../values/enumeration.dart';
import '../values/typedefs.dart';

class ChatUITextField extends StatefulWidget {
  const ChatUITextField({
    Key? key,
    this.sendMessageConfig,
    required this.focusNode,
    required this.textEditingController,
    required this.onPressed,
    required this.onRecordingComplete,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onTopSelected,
  }) : super(key: key);

  /// Provides configuration of default text field in chat.
  final SendMessageConfiguration? sendMessageConfig;

  /// Provides focusNode for focusing text field.
  final FocusNode focusNode;

  /// Provides functions which handles text field.
  final TextEditingController textEditingController;

  /// Provides callback when user tap on text field.
  final VoidCallBack onPressed;

  /// Provides callback once voice is recorded.
  final Function(String?) onRecordingComplete;

  /// Provides callback when user select images from camera/gallery.
  final StringsCallBack onImageSelected;

  final StringsCallBack onVideoSelected;

  final StringsCallBack onTopSelected;

  @override
  State<ChatUITextField> createState() => ChatUITextFieldState();
}

class ChatUITextFieldState extends State<ChatUITextField> with TickerProviderStateMixin {
  final ValueNotifier<String> _inputText = ValueNotifier('');

  final ImagePicker _imagePicker = ImagePicker();

  RecorderController? controller;

  ValueNotifier<bool> isRecording = ValueNotifier(false);

  SendMessageConfiguration? get sendMessageConfig => widget.sendMessageConfig;

  VoiceRecordingConfiguration? get voiceRecordingConfig =>
      widget.sendMessageConfig?.voiceRecordingConfiguration;

  ImagePickerIconsConfiguration? get imagePickerIconsConfig =>
      sendMessageConfig?.imagePickerIconsConfig;

  TextFieldConfiguration? get textFieldConfig =>
      sendMessageConfig?.textFieldConfig;

  CancelRecordConfiguration? get cancelRecordConfiguration =>
      sendMessageConfig?.cancelRecordConfiguration;

  OutlineInputBorder get _outLineBorder => OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: widget.sendMessageConfig?.textFieldConfig?.borderRadius ??
        BorderRadius.circular(textFieldBorderRadius),
  );

  ValueNotifier<TypeWriterStatus> composingStatus =
  ValueNotifier(TypeWriterStatus.typed);

  late Debouncer debouncer;

  bool _hasPhoto = false; // 相册/拍照
  bool _hasEmoji = false; // 表情
  bool _showNoOnlineService = false; // 无在线客服提示

  // 添加录音计时相关变量
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _currentRecordingPath; // 存储当前录音路径

  // 微信风格录音相关变量
  bool _isWeChatRecording = false;
  bool _isCancellingRecord = false;
  double _recordingOffsetY = 0;
  OverlayEntry? _voiceOverlay;

  List<SenceConfigModel> _senseList = [];

  // 添加动画控制器
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  
  // 弹窗动画控制器
  late AnimationController _dialogController;
  late Animation<double> _dialogScaleAnimation;
  late Animation<double> _dialogOpacityAnimation;

  @override
  void initState() {
    attachListeners();
    debouncer = Debouncer(
        sendMessageConfig?.textFieldConfig?.compositionThresholdTime ??
            const Duration(seconds: 1));
    super.initState();

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      controller = RecorderController();
    }
    loadData();

    // 初始化动画控制器
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    );
    
    // 初始化弹窗动画控制器
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _dialogScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutBack,
    ));
    
    _dialogOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOut,
    ));
    
    // 监听无在线客服事件
    CSocketIOManager().eventBus.on<NoOnlineServiceEvent>().listen((event) {
      setState(() {
        _showNoOnlineService = event.showNoService;
      });
    });
  }

  Future<void> loadData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String test = await sharedPreferences.getString("sence_config") ?? "";
    int windowOptionAppwebAgent = sharedPreferences.getInt("windowOptionAppwebAgent") ?? 0;
    var testMap = convert.jsonDecode(test);
    final List<dynamic> sceneJson2 = testMap;
    List<SenceConfigModel> sceneList2 = sceneJson2
        .map((item) => SenceConfigModel.fromJson(item))
        .toList();
    if (windowOptionAppwebAgent== 1) {
      SenceConfigModel senceConfigModel = SenceConfigModel(id: -1, cid: 0, sceneid: 0, name: '转人工', type: 0, value: 0, createTime: DateTime.now(), updateTime: DateTime.now());
      sceneList2.insert(0, senceConfigModel);
    }
    printN("app-sceneList- ${sceneList2.length}");
    setState(() {
      _senseList = sceneList2;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel(); // 确保计时器被取消
    debouncer.dispose();
    composingStatus.dispose();
    isRecording.dispose();
    _inputText.dispose();
    _panelController.dispose(); // 释放动画控制器
    _dialogController.dispose(); // 释放弹窗动画控制器
    _voiceOverlay?.remove(); // 清理弹窗
    super.dispose();
  }

  void stopRecordingIfActive() {
    if (isRecording.value) {
      _cancelRecording();
    }
  }

  void attachListeners() {
    composingStatus.addListener(() {
      widget.sendMessageConfig?.textFieldConfig?.onMessageTyping
          ?.call(composingStatus.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final outlineBorder = _outLineBorder;
    return Column(
      children: [
        Container(
          padding: textFieldConfig?.padding ?? const EdgeInsets.symmetric(horizontal: 6),
          margin: textFieldConfig?.margin,
          decoration: BoxDecoration(
            borderRadius: textFieldConfig?.borderRadius ??
                BorderRadius.circular(textFieldBorderRadius),
            color: const Color(0XFFf4f5f7),
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: isRecording,
            builder: (_, isRecordingValue, child) {
              return Column(
                children: [
                  // 场景按钮列表 - 始终显示
                  if (_senseList.isNotEmpty)
                    SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: Column(
                        children: [
                          if (_showNoOnlineService) // 无在线客服提示
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              alignment: Alignment.center,
                              child: const Text(
                                "无在线客服",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _senseList.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildInfoRow(_senseList[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      if ((sendMessageConfig?.allowRecordingVoice ?? false) &&
                          !kIsWeb && (Platform.isIOS || Platform.isAndroid) && !isRecordingValue)
                        // 恢复原有的录音按钮样式，但添加长按手势
                        GestureDetector(
                          onLongPressStart: (_) => _showWeChatVoiceDialog(),
                          child: IconButton(
                            onPressed: (textFieldConfig?.enabled ?? true)
                                ? _showWeChatVoiceDialog
                                : null,
                            icon: (isRecordingValue
                                ? voiceRecordingConfig?.stopIcon
                                : voiceRecordingConfig?.micIcon) ??
                                Icon(
                                  isRecordingValue ? Icons.stop : Icons.mic,
                                  color:
                                  voiceRecordingConfig?.recorderIconColor,
                                ),
                          ),
                        ),

                      if (isRecordingValue && controller != null && !kIsWeb)
                        Expanded(
                          child: AudioWaveforms(
                            size: const Size(double.maxFinite, 50),
                            recorderController: controller!,
                            margin: voiceRecordingConfig?.margin,
                            padding: voiceRecordingConfig?.padding ??
                                EdgeInsets.symmetric(
                                  horizontal: cancelRecordConfiguration == null ? 8 : 5,
                                ),
                            decoration: voiceRecordingConfig?.decoration ??
                                BoxDecoration(
                                  color: voiceRecordingConfig?.backgroundColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                            waveStyle: voiceRecordingConfig?.waveStyle ??
                                WaveStyle(
                                  extendWaveform: true,
                                  showMiddleLine: false,
                                  waveColor:
                                  voiceRecordingConfig?.waveStyle?.waveColor ??
                                      Colors.black,
                                ),
                          ),
                        )
                      else if (!isRecordingValue)
                        Expanded(
                          child: TextField(
                            focusNode: widget.focusNode,
                            controller: widget.textEditingController,
                            style: const TextStyle(color: Colors.black),
                            maxLines: textFieldConfig?.maxLines ?? 5,
                            minLines: textFieldConfig?.minLines ?? 1,
                            keyboardType: textFieldConfig?.textInputType,
                            inputFormatters: textFieldConfig?.inputFormatters,
                            onChanged: _onChanged,
                            enabled: textFieldConfig?.enabled,
                            textCapitalization: textFieldConfig?.textCapitalization ??
                                TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "输入消息...",
                              fillColor: Colors.white,
                              filled: true,
                              hintStyle: textFieldConfig?.hintStyle ??
                                  TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.25,
                                  ),
                              contentPadding: textFieldConfig?.contentPadding ??
                                  const EdgeInsets.symmetric(horizontal: 6),
                              border: outlineBorder,
                              focusedBorder: outlineBorder,
                              enabledBorder: outlineBorder,
                              disabledBorder: outlineBorder,
                            ),
                          ),
                        ),
                      if (!isRecordingValue)
                        ValueListenableBuilder<String>(
                          valueListenable: _inputText,
                          builder: (_, inputTextValue, child) {
                            if ((inputTextValue.isNotEmpty && !isRecordingValue) ||
                                (_hasEmoji && widget.textEditingController.text.isNotEmpty)) {
                              return Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed: _handleEmojiSend,
                                    icon: Icon(_hasEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color:
                                    voiceRecordingConfig?.recorderIconColor,),
                                  ),
                                  GestureDetector(
                                    onTap: (textFieldConfig?.enabled ?? true)
                                        ? () {
                                      widget.onPressed();
                                      _inputText.value = '';
                                    }
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.green,
                                      ),
                                      padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
                                      child: const Text("发送", style: TextStyle(color: Colors.white)),
                                    ),
                                  )
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  if (!isRecordingValue) ...[
                                    if (!isRecording.value)
                                      IconButton(
                                        onPressed: _handleEmojiSend,
                                        icon: Icon(_hasEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color:
                                        voiceRecordingConfig?.recorderIconColor,),
                                      ),
                                    if (!isRecording.value)
                                      IconButton(
                                        onPressed: _handleAdd,
                                        icon: Icon(Icons.add_circle_outline_rounded, color:
                                        voiceRecordingConfig?.recorderIconColor,),
                                      ),
                                  ],
                                  if (isRecordingValue &&
                                      cancelRecordConfiguration != null)
                                    IconButton(
                                      onPressed: () {
                                        cancelRecordConfiguration?.onCancel?.call();
                                        _cancelRecording();
                                      },
                                      icon: cancelRecordConfiguration?.icon ??
                                          const Icon(Icons.cancel_outlined),
                                      color: cancelRecordConfiguration?.iconColor ??
                                          voiceRecordingConfig?.recorderIconColor,
                                    ),
                                ],
                              );
                            }
                          },
                        ),

                      if ((sendMessageConfig?.allowRecordingVoice ?? false) &&
                          !kIsWeb && (Platform.isIOS || Platform.isAndroid) && isRecordingValue)
                        IconButton(
                          onPressed: (textFieldConfig?.enabled ?? true)
                              ? _recordOrStop
                              : null,
                          icon: (isRecordingValue
                              ? voiceRecordingConfig?.stopIcon
                              : voiceRecordingConfig?.micIcon) ??
                              Icon(
                                isRecordingValue ? Icons.stop : Icons.mic,
                                color:
                                voiceRecordingConfig?.recorderIconColor,
                              ),
                        ),
                    ],
                  ),
                  // 面板展开动画
                  SizeTransition(
                    sizeFactor: _panelAnimation,
                    axisAlignment: -1.0,
                    child: (_hasPhoto || _hasEmoji) && !isRecordingValue && !widget.focusNode.hasFocus
                        ? Container(
                      color: Colors.transparent,
                      height: 200,
                      width: double.infinity,
                      child: Column(
                        children: [
                          // 原有面板内容
                          Expanded(
                            child: _hasPhoto ? _buildMorePanel() : _hasEmoji ? _buildEmojiPanel() : Container(),
                          ),
                        ],
                      ),
                    )
                        : Container(),
                  ),
                ],
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildInfoRow(SenceConfigModel sence) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              printN("people==== ${sence.toJson()}");
              CSocketIOManager().sendChatConfig(sence);
              //CSocketIOManager().sendTextMessage(sence.name);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: textFieldConfig?.margin,
              decoration: BoxDecoration(
                borderRadius: textFieldConfig?.borderRadius ??
                    BorderRadius.circular(textFieldBorderRadius),
                color: Colors.white,
              ),
              child: Text("${sence.name}", style: TextStyle(color: Colors.black,),),
            ),
          )
        ],
      ),
    );
  }

  void _handleEmojiSend() {
    setState(() {
      if (_hasEmoji) {
        // 收起面板
        _hasEmoji = false;
        _panelController.reverse();
        // 延迟一点时间再打开键盘，确保面板完全收起
        Future.delayed(Duration(milliseconds: 50), () {
          FocusScope.of(context).requestFocus(widget.focusNode);
        });
      } else {
        // 打开表情面板
        _hasEmoji = true;
        _hasPhoto = false;
        _panelController.forward();
        _closeKeyboard();
      }
    });
  }

  void _handleAdd() {
    setState(() {
      if (_hasPhoto) {
        _hasPhoto = false;
        _panelController.reverse();
        Future.delayed(const Duration(milliseconds: 50), () {
          FocusScope.of(context).requestFocus(widget.focusNode);
        });
      } else {
        // 打开添加面板
        _hasPhoto = true;
        _hasEmoji = false;
        _panelController.forward();
        _closeKeyboard();
      }
    });
  }

  void _closeKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // 其他方法保持不变...
  FutureOr<void> _cancelRecording() async {
    assert(
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android,
    "Voice messages are only supported with android and ios platform",
    );
    if (!isRecording.value) return;
    final path = await controller?.stop();
    if (path == null) {
      isRecording.value = false;
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print('🗑️ 取消录音，文件已删除: $path');
    }
    isRecording.value = false;
    _currentRecordingPath = null; // 清空当前录音路径
    print('🗑️ 录音已取消，路径已清空');
  }

  Future<void> _recordOrStop() async {
    assert(
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android,
    "Voice messages are only supported with android and ios platform",
    );
    getIt<EventBus>().fire("audio");
    if (!isRecording.value) {
      await controller?.record(
        sampleRate: voiceRecordingConfig?.sampleRate,
        bitRate: voiceRecordingConfig?.bitRate,
        androidEncoder: voiceRecordingConfig?.androidEncoder,
        iosEncoder: voiceRecordingConfig?.iosEncoder,
        androidOutputFormat: voiceRecordingConfig?.androidOutputFormat,
      );
      _recordingSeconds = 0;
      _currentRecordingPath = null;
      isRecording.value = true;
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds = timer.tick;
        });
        if (_recordingSeconds >= 60) {
          _recordOrStop();
        }
      });
    } else {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await controller?.stop();
      isRecording.value = false;
      _currentRecordingPath = path; // 保存录音路径
      if (_recordingSeconds < 3) {
        // 少于3秒，直接丢弃
        if (path != null) {
          _deleteRecordingFile(path);
          _currentRecordingPath = null; // 清空路径
          print('🗑️ 录音时间太短，文件已删除，路径已清空');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音时间太短（最少3秒）')),
        );
      } else {
        // 超过3秒，显示确认对话框
        _showRecordingConfirmation();
      }
    }
  }

  // 显示录音确认弹窗
  void _showRecordingConfirmation() {
    if (_currentRecordingPath == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认发送'),
        content: Text('确定要发送这段$_recordingSeconds秒的录音吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRecordingComplete(_currentRecordingPath);
              _currentRecordingPath = null; // 发送后清空路径
              print('📤 录音已发送，路径已清空');
            },
            child: const Text('发送'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 取消时删除录音文件并清空路径
              _deleteRecordingFile(_currentRecordingPath!);
              _currentRecordingPath = null; // 清空当前录音路径
              print('🗑️ 录音已取消，文件已删除，路径已清空');
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 显示微信风格的全屏录音界面
  void _showWeChatVoiceDialog() {
    if (_voiceOverlay != null) return;
    
    _voiceOverlay = OverlayEntry(
      builder: (context) => _buildWeChatRecordingScreen(),
    );
    
    Overlay.of(context).insert(_voiceOverlay!);
    _dialogController.forward(); // 启动动画
    _startWeChatRecording();
  }

  // 构建微信风格的全屏录音界面
  Widget _buildWeChatRecordingScreen() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _dialogController,
        builder: (context, child) {
          return Container(
            color: Color(0xFF2C2C2C), // 深灰色背景
            child: SafeArea(
              child: Column(
                children: [
                  // 顶部状态栏区域
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '录音中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_recordingSeconds}"',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 中间录音动画区域
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 录音动画圆圈
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.3),
                              border: Border.all(
                                color: Colors.green,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 40),
                          
                          // 录音提示文字
                          Text(
                            '正在录音...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // 简单的波形显示
                          Container(
                            width: 200,
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(10, (index) {
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300 + index * 50),
                                  width: 4,
                                  height: 10 + (index % 3) * 15 + (_recordingSeconds % 4) * 5,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 底部按钮区域
                  Container(
                    height: 120,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 左侧取消按钮
                        GestureDetector(
                          onTap: _cancelVoiceDialog,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '取消',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    
                    // 提示文字（暂不显示手势提示）
                    
                    // 右侧发送按钮
                        GestureDetector(
                          onTap: _sendVoiceDialog,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '发送',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 更新弹窗中的手势位置（保留但简化）
  void _updateVoiceDialogPosition(DragUpdateDetails details) {
    // 在全屏界面中不需要复杂的手势检测
  }

  // 处理弹窗手势结束（保留但简化）
  void _handleVoiceDialogEnd() {
    // 在全屏界面中通过按钮操作，不需要手势结束处理
  }

  // 取消语音录制
  Future<void> _cancelVoiceDialog() async {
    // 标记为取消，避免在停止录音时误发送
    setState(() {
      _isCancellingRecord = true;
    });
    await _stopWeChatRecording();
    _closeVoiceDialog();
  }

  // 发送语音录制
  Future<void> _sendVoiceDialog() async {
    await _stopWeChatRecording();
    _closeVoiceDialog();
  }

  // 关闭语音弹窗
  void _closeVoiceDialog() {
    _dialogController.reverse().then((_) {
      _voiceOverlay?.remove();
      _voiceOverlay = null;
      _dialogController.reset(); // 重置动画状态
    });
    
    setState(() {
      _isCancellingRecord = false;
      _recordingOffsetY = 0;
    });
  }

  // 微信风格录音方法
  Future<void> _startWeChatRecording() async {
    assert(
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android,
      "Voice messages are only supported with android and ios platform",
    );
    
    if (_isWeChatRecording) return;
    
    setState(() {
      _isWeChatRecording = true;
      _isCancellingRecord = false;
      _recordingOffsetY = 0;
    });
    
    getIt<EventBus>().fire("audio");
    
    await controller?.record(
      sampleRate: voiceRecordingConfig?.sampleRate,
      bitRate: voiceRecordingConfig?.bitRate,
      androidEncoder: voiceRecordingConfig?.androidEncoder,
      iosEncoder: voiceRecordingConfig?.iosEncoder,
      androidOutputFormat: voiceRecordingConfig?.androidOutputFormat,
    );
    
    _recordingSeconds = 0;
    _currentRecordingPath = null;
    isRecording.value = true;
    
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds = timer.tick;
      });
      if (_recordingSeconds >= 60) {
        _sendVoiceDialog(); // 自动发送
      }
    });
    
    print('🎤 开始微信风格录音');
  }

  Future<void> _stopWeChatRecording() async {
    if (!_isWeChatRecording) return;
    
    _recordingTimer?.cancel();
    isRecording.value = false;
    
    final path = await controller?.stop();
    
    setState(() {
      _isWeChatRecording = false;
    });
    
    if (path != null) {
      _currentRecordingPath = path;
      
      if (_isCancellingRecord) {
        // 取消录音，删除文件
        await _deleteRecordingFile(path);
        _currentRecordingPath = null;
        print('🗑️ 录音已取消');
      } else if (_recordingSeconds < 1) {
        // 录音时间太短
        await _deleteRecordingFile(path);
        _currentRecordingPath = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音时间太短')),
        );
        print('⚠️ 录音时间太短');

      } else {
        // 改为弹出发送前确认弹窗（>=3秒可发送，否则提示并丢弃）
        if (_recordingSeconds < 3) {
          await _deleteRecordingFile(path);
          _currentRecordingPath = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('录音时间太短（最少3秒）')),
          );
          print('⚠️ 录音时间太短（最少3秒）');
        } else {
          _showRecordingConfirmation();
          print('⏳ 等待用户确认是否发送录音');
        }
      }
    }
    
    setState(() {
      _isCancellingRecord = false;
      _recordingOffsetY = 0;
    });
  }

  // 删除录音文件
  Future<void> _deleteRecordingFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ 录音文件已删除: $path');
      } else {
        print('⚠️ 录音文件不存在: $path');
      }
    } catch (e) {
      printN('删除录音文件失败: $e');
    }
  }

  void _onIconPressed(
      ImageSource imageSource, {
        ImagePickerConfiguration? config,
      }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: imageSource,
        maxHeight: config?.maxHeight,
        maxWidth: config?.maxWidth,
        imageQuality: config?.imageQuality,
        preferredCameraDevice:
        config?.preferredCameraDevice ?? CameraDevice.rear,
      );
      String? imagePath = image?.path;
      if (config?.onImagePicked != null) {
        String? updatedImagePath = await config?.onImagePicked!(imagePath);
        if (updatedImagePath != null) imagePath = updatedImagePath;
      }
      setState(() {
        _hasEmoji = false;
        _hasPhoto = false;
        _panelController.reverse();
      });
      widget.onImageSelected(imagePath ?? '', '');
    } catch (e) {
      widget.onImageSelected('', e.toString());
    }
  }

  void _onChanged(String inputText) {
    debouncer.run(() {
      composingStatus.value = TypeWriterStatus.typed;
    }, () {
      composingStatus.value = TypeWriterStatus.typing;
    });
    _inputText.value = inputText;
  }

  Widget _buildMorePanel() {
    final actions = [
      {
        'icon': Icons.photo,
        'label': '照片',
      },
      {
        'icon': Icons.videocam,
        'label': '视频',
      },
      {
        'icon': Icons.camera_alt,
        'label': '拍照',
      },
      {
        'icon': Icons.video_call,
        'label': '录像',
      },
      {
        'icon': Icons.message,
        'label': '留言',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              var label = actions[index]['label'] as String;
              if (label == "照片") {
                _onIconPressed(
                  ImageSource.gallery,
                  config: sendMessageConfig
                      ?.imagePickerConfiguration,);
              }  else if (label == "视频") {
                _pickVideoFromGallery();
              } else if (label == "拍照") {
                _onIconPressed(
                  ImageSource.camera,
                  config: sendMessageConfig?.imagePickerConfiguration,
                );
              }  else if (label == "录像") {
                _takeVideo();
              } else {
                GoRouter.of(context).push(Routes.ChatMessageRoot,);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    actions[index]['icon'] as IconData,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    actions[index]['label'] as String,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmojiPanel() {
    final emojis = List.generate(50, (index) => String.fromCharCode(0x1F600 + index));

    return Container(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(emojis[index]),
            child: Text(
              emojis[index],
              style: const TextStyle(fontSize: 28),
            ),
          );
        },
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = widget.textEditingController.text;
    final selection = widget.textEditingController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    widget.textEditingController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    setState(() {});
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) return;

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: true,
      );

      if (photo != null) {
        widget.onVideoSelected(photo.path ?? '', '');
        setState(() {
          _hasPhoto = false;
          _panelController.reverse();
        });
      }
    } catch (e) {
      print('拍照失败: $e');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) return;

      final XFile? photo = await _imagePicker.pickVideo(
          source: ImageSource.camera, maxDuration: Duration(seconds: 60));

      if (photo != null) {
        widget.onVideoSelected(photo.path ?? '', '');
        setState(() {
          _hasPhoto = false;
          _panelController.reverse();
        });
      }
    } catch (e) {
      print('录像失败: $e');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      // 检查权限（根据你的需求调整权限检查）
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) {
        return;
      }

      // 使用 file_picker 选择视频文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String videoPath = result.files.single.path!;

        printN("选择的视频路径: $videoPath");

        // 直接传递视频路径
        widget.onVideoSelected(videoPath, '');

        setState(() {
          _hasPhoto = false;
          _panelController.reverse();
        });
      }
    } catch (e) {
      printN('选择视频失败: $e');
      widget.onVideoSelected('', e.toString());
    }
  }

  String? lookupMimeType(String path, {List<int>? headerBytes}) {
    // 首先根据文件扩展名判断
    final extension = _getExtension(path);
    final mimeFromExtension = _mimeTypes[extension];
    if (mimeFromExtension != null) {
      return mimeFromExtension;
    }

    // 如果有提供文件头字节，尝试根据文件头判断
    if (headerBytes != null && headerBytes.length >= 12) {
      return _getMimeTypeFromHeader(headerBytes);
    }

    return null;
  }

  String _getExtension(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1 || index == path.length - 1) {
      return '';
    }
    return path.substring(index + 1).toLowerCase();
  }

  String? _getMimeTypeFromHeader(List<int> headerBytes) {
    // 检查常见的文件类型签名
    if (_isJpeg(headerBytes)) return 'image/jpeg';
    if (_isPng(headerBytes)) return 'image/png';
    if (_isGif(headerBytes)) return 'image/gif';
    if (_isWebp(headerBytes)) return 'image/webp';
    if (_isMp4(headerBytes)) return 'video/mp4';
    if (_isAvi(headerBytes)) return 'video/x-msvideo';
    if (_isMov(headerBytes)) return 'video/quicktime';
    if (_isMkv(headerBytes)) return 'video/x-matroska';
    if (_isFlv(headerBytes)) return 'video/x-flv';
    if (_isWmv(headerBytes)) return 'video/x-ms-wmv';
    if (_is3gp(headerBytes)) return 'video/3gpp';

    return null;
  }

  bool _isJpeg(List<int> bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  bool _isPng(List<int> bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  bool _isGif(List<int> bytes) {
    return bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61;
  }

  bool _isWebp(List<int> bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
  }

  bool _isMp4(List<int> bytes) {
    // MP4文件通常以 'ftyp' 开头
    return bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
  }

  bool _isAvi(List<int> bytes) {
    // AVI文件以 'RIFF' 开头，然后是 'AVI '
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x41 &&
        bytes[9] == 0x56 &&
        bytes[10] == 0x49 &&
        bytes[11] == 0x20;
  }

  bool _isMov(List<int> bytes) {
    // MOV文件也是以 'ftyp' 开头，但可能有不同的品牌
    return bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
  }

  bool _isMkv(List<int> bytes) {
    // Matroska (MKV) 文件以 0x1A45DFA3 开头
    return bytes.length >= 4 &&
        bytes[0] == 0x1A &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xDF &&
        bytes[3] == 0xA3;
  }

  bool _isFlv(List<int> bytes) {
    // FLV文件以 'FLV' 开头
    return bytes.length >= 3 &&
        bytes[0] == 0x46 &&
        bytes[1] == 0x4C &&
        bytes[2] == 0x56;
  }

  bool _isWmv(List<int> bytes) {
    // ASF/WMV文件以 0x30 0x26 0xB2 0x75 0x8E 0x66 0xCF 0x11 开头
    return bytes.length >= 9 &&
        bytes[0] == 0x30 &&
        bytes[1] == 0x26 &&
        bytes[2] == 0xB2 &&
        bytes[3] == 0x75 &&
        bytes[4] == 0x8E &&
        bytes[5] == 0x66 &&
        bytes[6] == 0xCF &&
        bytes[7] == 0x11 &&
        bytes[8] == 0xA6 &&
        bytes[9] == 0xD9;
  }

  bool _is3gp(List<int> bytes) {
    // 3GP文件也是以 'ftyp' 开头
    return bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
  }

// 常见文件扩展名到MIME类型的映射
  final Map<String, String> _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'ico': 'image/x-icon',
    'tiff': 'image/tiff',
    'tif': 'image/tiff',
    'svg': 'image/svg+xml',

    'mp4': 'video/mp4',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'wmv': 'video/x-ms-wmv',
    'flv': 'video/x-flv',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    '3gp': 'video/3gpp',
    '3g2': 'video/3gpp2',
    'mpeg': 'video/mpeg',
    'mpg': 'video/mpeg',

    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'flac': 'audio/flac',
    'aac': 'audio/aac',
    'm4a': 'audio/mp4',

    'pdf': 'application/pdf',
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    '7z': 'application/x-7z-compressed',
    'tar': 'application/x-tar',
    'gz': 'application/gzip',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',

    'txt': 'text/plain',
    'html': 'text/html',
    'htm': 'text/html',
    'css': 'text/css',
    'js': 'application/javascript',
    'json': 'application/json',
    'xml': 'application/xml',
  };

}