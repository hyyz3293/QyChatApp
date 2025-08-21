import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' show File, Platform;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:qychatapp/presentation/ui/model/sence_config_model.dart';
import 'package:qychatapp/utils/constants/constants.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  State<ChatUITextField> createState() => _ChatUITextFieldState();
}

class _ChatUITextFieldState extends State<ChatUITextField> {
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

  // 添加录音计时相关变量
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _currentRecordingPath; // 存储当前录音路径

  List<SenceConfigModel> _senseList = [];

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
    super.dispose();
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
          height: 60,
          width: double.infinity,
          child: ListView.builder(
            itemCount: _senseList.length,
              scrollDirection: Axis.horizontal,
            itemBuilder:
              (BuildContext context, int index) {
                return _buildInfoRow(_senseList[index]);
              },
          ),
        ),
        Container(
          padding: textFieldConfig?.padding ?? const EdgeInsets.symmetric(horizontal: 6),
          margin: textFieldConfig?.margin,
          decoration: BoxDecoration(
            borderRadius: textFieldConfig?.borderRadius ??
                BorderRadius.circular(textFieldBorderRadius),
            color: sendMessageConfig?.textFieldBackgroundColor ?? Colors.white,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: isRecording,
            builder: (_, isRecordingValue, child) {
              return Column(
                children: [
                  Row(
                    children: [

                      if ((sendMessageConfig?.allowRecordingVoice ?? false) &&
                          !kIsWeb && (Platform.isIOS || Platform.isAndroid) && !isRecordingValue)
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
                      else
                        Expanded(
                          child: TextField(
                            focusNode: widget.focusNode,
                            controller: widget.textEditingController,
                            style: textFieldConfig?.textStyle ??
                                const TextStyle(color: Colors.white),
                            maxLines: textFieldConfig?.maxLines ?? 5,
                            minLines: textFieldConfig?.minLines ?? 1,
                            keyboardType: textFieldConfig?.textInputType,
                            inputFormatters: textFieldConfig?.inputFormatters,
                            onChanged: _onChanged,
                            enabled: textFieldConfig?.enabled,
                            textCapitalization: textFieldConfig?.textCapitalization ??
                                TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText:
                              textFieldConfig?.hintText ?? PackageStrings.message,
                              fillColor: sendMessageConfig?.textFieldBackgroundColor ??
                                  Colors.white,
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
                                    icon: Icon(Icons.emoji_emotions_outlined, color:
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
                                        icon: Icon(Icons.emoji_emotions_outlined, color:
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

                  (_hasPhoto || _hasEmoji) && !isRecordingValue && !widget.focusNode.hasFocus ? Container(
                    color: Colors.transparent,
                    height: 150,
                    width: double.infinity,
                    child: _hasPhoto ? _buildMorePanel() : _hasEmoji ? _buildEmojiPanel() : Container(),
                  ) : Container()
                ],
              );
            },
          ),
        )
      ],
    );
  }

  // 构建信息行
  Widget _buildInfoRow(SenceConfigModel sence) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              print("people==== ${sence.toJson()}");
              //widget.onTopSelected("people", "");

              CSocketIOManager().sendChatConfig(sence);


            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: textFieldConfig?.margin,
              decoration: BoxDecoration(
                borderRadius: textFieldConfig?.borderRadius ??
                    BorderRadius.circular(textFieldBorderRadius),
                color: sendMessageConfig?.textFieldBackgroundColor ?? Colors.white,
              ),
              child: Text("${sence.name}", style: TextStyle(color: voiceRecordingConfig?.recorderIconColor,),),
            ),
          )
        ],
      ),
    );
  }


  void _handleEmojiSend() {
    setState(() {
      if (_hasEmoji) {
        // 第二次点击同一个按钮 - 收起面板并打开键盘
        _hasEmoji = false;
        // 延迟一点时间再打开键盘，确保面板完全收起
        Future.delayed(Duration(milliseconds: 50), () {
          FocusScope.of(context).requestFocus(widget.focusNode);
        });
      } else {
        // 第一次点击 - 打开表情面板
        _hasEmoji = true;
        _hasPhoto = false;
        _closeKeyboard();
      }
    });
  }

  void _handleAdd() {
    setState(() {
      if (_hasPhoto) {
        // 第二次点击同一个按钮 - 收起面板并打开键盘
        _hasPhoto = false;
        // 延迟一点时间再打开键盘，确保面板完全收起
        Future.delayed(Duration(milliseconds: 50), () {
          FocusScope.of(context).requestFocus(widget.focusNode);
        });
      } else {
        // 第一次点击 - 打开添加面板
        _hasPhoto = true;
        _hasEmoji = false;
        _closeKeyboard();
      }
    });
  }

  void _closeKeyboard() {
    // 只关闭键盘，不改变面板状态
    FocusScope.of(context).unfocus();
  }

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
    }

    isRecording.value = false;
  }

  Future<void> _recordOrStop() async {
    assert(
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android,
    "Voice messages are only supported with android and ios platform",
    );

    getIt<EventBus>().fire("audio");

    if (!isRecording.value) {
      // 开始录音
      await controller?.record(
        sampleRate: voiceRecordingConfig?.sampleRate,
        bitRate: voiceRecordingConfig?.bitRate,
        androidEncoder: voiceRecordingConfig?.androidEncoder,
        iosEncoder: voiceRecordingConfig?.iosEncoder,
        androidOutputFormat: voiceRecordingConfig?.androidOutputFormat,
      );

      // 重置计时器
      _recordingSeconds = 0;
      _currentRecordingPath = null;
      isRecording.value = true;

      // 启动计时器
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds = timer.tick;
        });

        // 达到60秒自动停止
        if (_recordingSeconds >= 60) {
          _recordOrStop();
        }
      });
    } else {
      // 停止录音
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await controller?.stop();
      isRecording.value = false;
      _currentRecordingPath = path; // 保存录音路径

      // 处理录音结果
      if (_recordingSeconds < 3) {
        // 少于3秒，直接丢弃
        if (path != null) {
          _deleteRecordingFile(path);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音时间太短（最少3秒）')),
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
        title: Text('确认发送'),
        content: Text('确定要发送这段${_recordingSeconds}秒的录音吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecordingFile(_currentRecordingPath!);
            },
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRecordingComplete(_currentRecordingPath);
            },
            child: Text('发送'),
          ),
        ],
      ),
    );
  }

  // 删除录音文件
  Future<void> _deleteRecordingFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('删除录音文件失败: $e');
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
                  config: sendMessageConfig
                      ?.imagePickerConfiguration,
                );
              }  else {
                _takeVideo();
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
                    style: TextStyle(
                      color: Colors.black,
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
        setState(() => _hasPhoto = false);
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
        setState(() => _hasPhoto = false);
      }
    } catch (e) {
      print('录像失败: $e');
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (permission.isAuth || permission.hasAccess) {
        final XFile? image = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );

        if (image != null) {
          widget.onVideoSelected(image.path ?? '', '');
          setState(() => _hasPhoto = false);
        }
      }
    } catch (e) {
      print('选择视频失败: $e');
    }
  }
}