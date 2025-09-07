import 'dart:async';
import 'dart:convert';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:qychatapp/presentation/constants/assets.dart';
import 'package:qychatapp/presentation/ui/chart/message_event.dart';
import 'package:qychatapp/presentation/ui/chatview/theme.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:qychatapp/presentation/utils/dio/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controller/chat_controller.dart';
import '../../../models/chat_bubble.dart';
import '../../../models/config_models/chat_bubble_configuration.dart';
import '../../../models/config_models/chat_view_states_configuration.dart';
import '../../../models/config_models/feature_active_config.dart';
import '../../../models/config_models/image_message_configuration.dart';
import '../../../models/config_models/link_preview_configuration.dart';
import '../../../models/config_models/message_configuration.dart';
import '../../../models/config_models/message_list_configuration.dart';
import '../../../models/config_models/message_reaction_configuration.dart';
import '../../../models/config_models/profile_circle_configuration.dart';
import '../../../models/config_models/reaction_popup_configuration.dart';
import '../../../models/config_models/receipts_widget_config.dart';
import '../../../models/config_models/replied_message_configuration.dart';
import '../../../models/config_models/replied_msg_auto_scroll_config.dart';
import '../../../models/config_models/reply_popup_configuration.dart';
import '../../../models/config_models/reply_suggestions_config.dart';
import '../../../models/config_models/scroll_to_bottom_button_config.dart';
import '../../../models/config_models/send_message_configuration.dart';
import '../../../models/config_models/suggestion_item_config.dart';
import '../../../models/config_models/swipe_to_reply_configuration.dart';
import '../../../models/config_models/type_indicator_configuration.dart';
import '../../../models/data_models/chat_user.dart';
import '../../../models/data_models/message.dart';
import '../../../models/data_models/reply_message.dart';
import '../../../models/data_models/suggestion_item_data.dart';
import '../../../values/enumeration.dart';
import '../../../widgets/chat_view.dart';
import '../../utils/global_utils.dart';
import '../../utils/service_locator.dart';
import '../../utils/websocket/chat_socket_manager.dart';
import '../model/history_messsage_bean.dart';
import '../model/image_bean.dart';
import 'chat_data.dart';

class ChatViewScreen extends StatefulWidget {
  const ChatViewScreen({Key? key}) : super(key: key);
  @override
  State<ChatViewScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatViewScreen> {
  AppTheme theme = DarkTheme();
  bool isDarkTheme = false;
  late final ChatController _chatController;
  bool _isSound = true;
  final String _currentUserId = "user-id";
  ChatViewState _chatViewState = ChatViewState.noData;

  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Message>? _messageSubscription2;


  final EventBus eventBus = EventBus();

  late StreamSubscription<ChatUser> _otherSubscription;


  List<ChatUser> otherList = [ChatUser(
    id: '2',
    name: '',
    profilePhoto: "${Assets.appImages}headImg6.png",
    imageType: ImageType.asset,
  ),];

  int page = 1;
  var lastTime =0;

  @override
  void initState() {
    super.initState();
    otherList = [];
    _otherSubscription = getIt<EventBus>().on<ChatUser>().listen((event) {
      setState(() {
        // 检查用户是否已存在
        bool userExists = otherList.any((user) => user.id == event.id);

        // 如果用户不存在才添加
        if (!userExists) {
          otherList.add(event);
        }
        //_chatController.otherUsers = otherList;
      });
    });
    // 订阅消息流
    _messageSubscription = CSocketIOManager().messagesStream.listen((msg) {
      print("===>>>> Msg ");
      //msg.sentBy = "2";
      var _msg = msg.copyWith(sentBy: "2");
      _chatController.addMessage(_msg);
      // 更新聊天状态
      setState(() {
        _chatViewState = ChatViewState.hasMessages;
      });
    });
    // 订阅消息流
    _messageSubscription2 = CSocketIOManager().messagesStream2.listen((msg) {
      print("===>>>2222> Msg DATA ${msg.sentBy}");
      //msg.sentBy = "2";
      var _msg = msg.copyWith(sentBy: "${_currentUserId}");
      print("===>>>2222> Msg DATA ${_msg.sentBy}");
      _chatController.addMessage(_msg);
      // 更新聊天状态
      setState(() {
        _chatViewState = ChatViewState.hasMessages;
      });
    });
    _chatController = ChatController(
      initialMessageList: [],
      scrollController: ScrollController(),
      currentUser: ChatUser(
        id: '${_currentUserId}',
        name: '',
        profilePhoto: "${Assets.appImages}pic2.png",
        imageType: ImageType.asset,
      ),
      otherUsers: [ChatUser(
        id: '2',
        name: '',
        profilePhoto: "${Assets.appImages}headImg6.png",
        imageType: ImageType.asset,
      ),],
    );

    loadSound();

    lastTime = DateTime.now().toUtc().millisecondsSinceEpoch;

  }

  @override
  void dispose() {
    // ChatController should be disposed to avoid memory leaks
    _chatController.dispose();
    _messageSubscription?.cancel();
    _messageSubscription2?.cancel();
    _otherSubscription?.cancel();
    CSocketIOManager().dispose();
    super.dispose();
  }

  void _showHideTypingIndicator() {
    _chatController.setTypingIndicator = !_chatController.showTypingIndicator;
  }

  void receiveMessage() async {
    _chatController.addMessage(
      Message(
        id: DateTime.now().toString(),
        message: 'I will schedule the meeting.',
        createdAt: DateTime.now(),
        sentBy:"2"
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _chatController.addReplySuggestions([
      const SuggestionItemData(text: 'Thanks.'),
      const SuggestionItemData(text: 'Thank you very much.'),
      const SuggestionItemData(text: 'Great.')
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('小宇客服', style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '返回',
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0XFFd5d8e4),
                  Color(0XFFb6bfcb)
                ],
              ),
            ),
          ),
          actions: [IconButton(icon: Icon(_isSound ?
          Icons.volume_up :
          Icons.volume_off), onPressed: _toggleSound,
            tooltip: _isSound ? '打开声音' : '关闭声音', color: Colors.grey,)],
        ),
        body: SafeArea(child:
            Stack(
              alignment: Alignment.topCenter,
              children: [
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: ChatView(
                    loadMoreData: loadData,
                    loadingWidget: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.outgoingChatBubbleColor ?? Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '加载更多消息...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    chatController: _chatController,
                    onSendTap: _onSendTap,
                    featureActiveConfig: const FeatureActiveConfig(
                      lastSeenAgoBuilderVisibility: true,
                      receiptsBuilderVisibility: true,
                      enableScrollToBottomButton: true,
                      enablePagination: true,
                    ),
                    scrollToBottomButtonConfig: ScrollToBottomButtonConfig(
                      backgroundColor: theme.textFieldBackgroundColor,
                      border: Border.all(
                        color: isDarkTheme ? Colors.transparent : Colors.grey,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        weight: 10,
                        size: 30,
                      ),
                    ),
                    chatViewState: _chatViewState,
                    chatViewStateConfig: ChatViewStateConfiguration(
                      loadingWidgetConfig: ChatViewStateWidgetConfiguration(
                        loadingIndicatorColor: theme.outgoingChatBubbleColor,
                      ),
                      onReloadButtonTap: () {
                        loadData();
                      },
                    ),
                    typeIndicatorConfig: TypeIndicatorConfiguration(
                      flashingCircleBrightColor: theme.flashingCircleBrightColor,
                      flashingCircleDarkColor: theme.flashingCircleDarkColor,
                    ),
                    chatBackgroundConfig: ChatBackgroundConfiguration(
                      messageTimeIconColor: theme.messageTimeIconColor,
                      messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
                      defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
                        textStyle: TextStyle(
                          color: theme.chatHeaderColor,
                          fontSize: 17,
                        ),
                      ),
                      backgroundColor: Color(0XFFf4f5f7),
                    ),
                    sendMessageConfig: SendMessageConfiguration(
                      imagePickerIconsConfig: ImagePickerIconsConfiguration(
                        cameraIconColor: theme.cameraIconColor,
                        galleryIconColor: theme.galleryIconColor,
                      ),
                      replyMessageColor: theme.replyMessageColor,
                      defaultSendButtonColor: theme.sendButtonColor,
                      replyDialogColor: theme.replyDialogColor,
                      replyTitleColor: theme.replyTitleColor,
                      textFieldBackgroundColor: theme.textFieldBackgroundColor,
                      closeIconColor: theme.closeIconColor,
                      textFieldConfig: TextFieldConfiguration(
                        onMessageTyping: (status) {
                          /// Do with status
                          debugPrint(status.toString());
                        },
                        compositionThresholdTime: const Duration(seconds: 1),
                        textStyle: TextStyle(color: theme.textFieldTextColor),
                      ),
                      micIconColor: theme.replyMicIconColor,
                      voiceRecordingConfiguration: VoiceRecordingConfiguration(
                        backgroundColor: theme.waveformBackgroundColor,
                        recorderIconColor: theme.recordIconColor,
                        waveStyle: WaveStyle(
                          showMiddleLine: false,
                          waveColor: theme.waveColor ?? Colors.white,
                          extendWaveform: true,
                        ),
                      ),
                    ),
                    chatBubbleConfig: ChatBubbleConfiguration(
                      outgoingChatBubbleConfig: ChatBubble(
                        linkPreviewConfig: LinkPreviewConfiguration(
                          backgroundColor: theme.linkPreviewOutgoingChatColor,
                          bodyStyle: theme.outgoingChatLinkBodyStyle,
                          titleStyle: theme.outgoingChatLinkTitleStyle,
                        ),
                        receiptsWidgetConfig:
                        const ReceiptsWidgetConfig(showReceiptsIn: ShowReceiptsIn.all),
                        color:  const Color(0xffb9cfe3),
                      ),
                      inComingChatBubbleConfig: ChatBubble(
                        linkPreviewConfig: LinkPreviewConfiguration(
                          linkStyle: TextStyle(
                            color: theme.inComingChatBubbleTextColor,
                            decoration: TextDecoration.underline,
                          ),
                          backgroundColor: theme.linkPreviewIncomingChatColor,
                          bodyStyle: theme.incomingChatLinkBodyStyle,
                          titleStyle: theme.incomingChatLinkTitleStyle,
                        ),
                        textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
                        onMessageRead: (message) {
                          /// send your message reciepts to the other client
                          debugPrint('Message Read');
                        },
                        senderNameTextStyle: const TextStyle(color: Colors.black),
                        color: Colors.white,
                      ),
                    ),
                    replyPopupConfig: ReplyPopupConfiguration(
                      backgroundColor: theme.replyPopupColor,
                      buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
                      topBorderColor: theme.replyPopupTopBorderColor,
                    ),
                    reactionPopupConfig: ReactionPopupConfiguration(
                      shadow: BoxShadow(
                        color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
                        blurRadius: 20,
                      ),
                      backgroundColor: theme.reactionPopupColor,
                    ),
                    messageConfig: MessageConfiguration(
                      messageReactionConfig: MessageReactionConfiguration(
                        borderColor: theme.messageReactionBackGroundColor,
                        reactedUserCountTextStyle:
                        TextStyle(color: theme.inComingChatBubbleTextColor),
                        reactionCountTextStyle:
                        TextStyle(color: theme.inComingChatBubbleTextColor),
                        reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
                          backgroundColor: theme.backgroundColor,
                          reactedUserTextStyle: TextStyle(
                            color: theme.inComingChatBubbleTextColor,
                          ),
                          reactionWidgetDecoration: BoxDecoration(
                            color: theme.inComingChatBubbleColor,
                            boxShadow: [
                              BoxShadow(
                                color: isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                                offset: const Offset(0, 20),
                                blurRadius: 40,
                              )
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      imageMessageConfig: ImageMessageConfiguration(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        shareIconConfig: ShareIconConfiguration(
                          defaultIconBackgroundColor: theme.shareIconBackgroundColor,
                          defaultIconColor: theme.shareIconColor,
                        ),
                      ),
                    ),
                    profileCircleConfig: const ProfileCircleConfiguration(
                      profileImageUrl: Data.profileImage,
                    ),
                    repliedMessageConfig: RepliedMessageConfiguration(
                      verticalBarColor: theme.verticalBarColor,
                      repliedMsgAutoScrollConfig:   RepliedMsgAutoScrollConfig(
                        enableHighlightRepliedMsg: true,
                        highlightColor: Colors.pinkAccent.shade100,
                        highlightScale: 1.1,
                      ),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.25,
                      ),
                      replyTitleTextStyle: TextStyle(color: theme.repliedTitleTextColor),
                    ),
                    swipeToReplyConfig: SwipeToReplyConfiguration(
                      replyIconColor: theme.swipeToReplyIconColor,
                    ),
                    replySuggestionsConfig: ReplySuggestionsConfig(
                      itemConfig: SuggestionItemConfig(
                        decoration: BoxDecoration(
                          color: theme.textFieldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.outgoingChatBubbleColor ?? Colors.white,
                          ),
                        ),
                        textStyle: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: (item) =>
                          _onSendTap(item.text, const ReplyMessage(), MessageType.text),
                    ),
                  )
                ),
                const Text("下拉可查看历史消息", style: TextStyle(color: Colors.grey, fontSize: 12),)
              ],
            )
        )
    );
  }

  void _onSendTap(
      String message,
      ReplyMessage replyMessage,
      MessageType messageType,
      ) {
    print("===>>>2222> Msg ${_chatController.currentUser.id}");
    final messageObj = Message(
      id: DateTime.now().toString(),
      createdAt: DateTime.now(),
      message: message,
      sentBy: _chatController.currentUser.id,
      replyMessage: replyMessage,
      messageType: messageType,
    );

    CSocketIOManager().sendMessage(message, replyMessage, messageType);

    _chatController.addMessage(
      messageObj,
    );
    
    // 更新聊天状态
    setState(() {
      _chatViewState = ChatViewState.hasMessages;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      final index = _chatController.initialMessageList.indexOf(messageObj);
      _chatController.initialMessageList[index].setStatus =
          MessageStatus.undelivered;
    });
    Future.delayed(const Duration(seconds: 1), () {
      final index = _chatController.initialMessageList.indexOf(messageObj);
      _chatController.initialMessageList[index].setStatus = MessageStatus.read;
    });
  }

  void _onThemeIconTap() {
    setState(() {
      if (isDarkTheme) {
        theme = LightTheme();
        isDarkTheme = false;
      } else {
        theme = DarkTheme();
        isDarkTheme = true;
      }
    });
  }

  Future<void> _toggleSound() async {
    setState(() {
      _isSound = !_isSound;
    });
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setBool("sound", _isSound);
  }

  Future<void> loadSound() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var isOpenSound = await sharedPreferences.getBool("sound") ?? true;
    var userId = sharedPreferences.getInt("userId") ?? 0;
    setState(() {
      _isSound = isOpenSound;
      //_currentUserId = '${userId}';
    });
  }

  Future<void> loadData() async {
    try {
      var map = await DioClient().getHistoryList(page, lastTime);
      MessagePageResponse response = MessagePageResponse.fromJson(map);

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var evaluationFlag = sharedPreferences.getInt("sharedPreferences");
      var serviceEvaluateTxt = sharedPreferences.getString("serviceEvaluateTxt");

      if (response.page!.total! >= 30) {
        page++;
      }

      printN("history==loadData=number=____________${response.page!.records!.length}__________");

      if (response.page!.records!.isNotEmpty) {
        // 创建历史消息列表
        List<Message> historyMessages = [];
        
        for (int i = 0; i < response.page!.records!.length; i++) {
          printN("history====${response.page!.records![i].toJson()}");
          
          var dateTime = DateTime.now();
          var msgBean = response.page!.records![i];
          var messJson = response.page!.records![i].messJson;

          // 检查messJson是否为null
          if (messJson == null) {
            printN("messJson is null for record $i, skipping...");
            continue;
          }

          String? enumType = messJson.enumType;
          if (enumType == null || enumType == "") {
            enumType = response.page!.records![i].messEnumType;
          }
          
          int? userId = msgBean.messJson!.msgSendId ?? 0;
          String? sendName = msgBean.sendName;
          String? sendAvatar = msgBean.sendAvatar;
          var userIdMy = sharedPreferences.getInt("userId") ?? 0;
          String sentBy = "2";

          print("======================start");
          print("======================userId=${userId}======userIdMy=${userIdMy}");

          print("======================end");
          if (userIdMy == userId) {
            sentBy = "user-id";
          }


          print("userId===================${userId}");

          if (enumType != null && enumType != "") {
            // 创建历史消息对象
            Message? historyMessage = _createMessageFromHistoryData(
              enumType: enumType,
              dateTime: dateTime,
              sharedPreferences: sharedPreferences,
              evaluationFlag: evaluationFlag,
              serviceEvaluateTxt: serviceEvaluateTxt,
              userId: userId,
              sendName: sendName,
              sendAvatar: sendAvatar,
              messJson: messJson,
              msgBean: msgBean,
              sentBy: sentBy
            );



            if (historyMessage != null) {
              historyMessages.add(historyMessage);
            }
          }
        }
        
        // 倒序展示历史消息
        historyMessages = historyMessages.reversed.toList();
        
        // 批量添加历史消息到聊天控制器（使用loadMoreData确保历史消息在前面）
        _chatController.loadMoreData(historyMessages);
        
        // 更新聊天状态
        setState(() {
          _chatViewState = _chatController.initialMessageList.isEmpty 
              ? ChatViewState.noData 
              : ChatViewState.hasMessages;
        });
      } else {
        // // 如果没有数据，确保状态为noData
        // setState(() {
        //   _chatViewState = ChatViewState.noData;
        // });
      }
    } catch (e) {
      printN("loadData error: $e");
      // 发生错误时设置为错误状态
      setState(() {
        _chatViewState = ChatViewState.error;
      });
    }
  }

  // 从历史数据创建Message对象的方法
  Message? _createMessageFromHistoryData({
    required String enumType,
    required DateTime dateTime,
    required SharedPreferences sharedPreferences,
    int? evaluationFlag,
    String? serviceEvaluateTxt,
    int? userId,
    String? sendName,
    String? sendAvatar,
    required MessJson messJson,
    required MessageRecord msgBean,
    required String sentBy
  }) {
    print("____________________---------start---------------------------------------------start");
    print("__________________enumType  ==__${enumType}");


    print("____________________---------end---------------------------------------------end");

    switch (enumType) {
      case "imQueueNotice":
        return Message(
          createdAt: dateTime,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy
        );

      case "imInvitationEvaluate":
        if (evaluationFlag == 1) {
          return Message(
            createdAt: dateTime,
            status: MessageStatus.delivered,
            message: serviceEvaluateTxt ?? '',
            sentBy:sentBy
          );
        }
        break;

      case "complex":
        return Message(
          createdAt: dateTime,
          messageType: MessageType.complex,
          status: MessageStatus.delivered,
          message: messJson.digest ?? '',
          sentBy:sentBy,
          complex: messJson.complex
        );

      case "navigation":
        return Message(
          createdAt: dateTime,
          messageType: MessageType.navigation,
          status: MessageStatus.delivered,
          message: messJson.title ?? '',
          sentBy:sentBy,
          navigationList: messJson.navigationList
        );

      case "knowGraphicText":
        return Message(
          createdAt: dateTime,
          messageType: MessageType.knowGraphicText,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy,
          imgs: messJson.imgs,
            link: messJson.link
        );

      case "welcomeSpeech":
        return Message(
          createdAt: dateTime,
          status: MessageStatus.delivered,
          message: messJson.welcomeSpeech!.welcomeSpeech ?? '',
          sentBy:sentBy
        );

      case "link":
        return Message(
          createdAt: dateTime,
          messageType: MessageType.links,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy,
          links: messJson.links
        );

      case "graphicText":
        return Message(
          createdAt: dateTime,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy
        );

      // case "imClick":
      //   return Message(
      //     createdAt: dateTime,
      //     status: MessageStatus.delivered,
      //     message: messJson.content ?? '',
      //     sentBy:sentBy
      //   );

      case "text":
        return Message(
          createdAt: dateTime,
          messageType: MessageType.text,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy
        );

      case "media":
        var url = '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${messJson.code}';
        printN("url=media==${url}");
        return Message(
          createdAt: dateTime,
          messageType: MessageType.video,
          status: MessageStatus.delivered,
          message: '${url}',
          sentBy:sentBy
        );

      case "video":
        var url1 = '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${messJson.conversationCode}';
        var url2 = '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${messJson.code}';
        printN("url=video=1=${url1}");
        printN("url=video=2=${url2}");
        return Message(
          createdAt: dateTime,
          messageType: MessageType.video,
          status: MessageStatus.delivered,
          message: url2,
          sentBy:sentBy
        );

      case "voiceRecord":
      case "voice":
        var url = '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${messJson.code}';
        return Message(
          createdAt: dateTime,
          messageType: MessageType.voice,
          status: MessageStatus.delivered,
          message: url,
          sentBy:sentBy
        );

      case "image":
      case "img":
        if (messJson.imgs?.isNotEmpty ?? false) {
          return Message(
            createdAt: dateTime,
            messageType: MessageType.image,
            status: MessageStatus.delivered,
            message: '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${messJson.imgs![0].code}',
            sentBy:sentBy,
            imgs: messJson.imgs
          );
        }
        break;

      case "attachment":
        if (messJson.attachment?.isNotEmpty ?? false) {
          var attachment = messJson.attachment!;
          for (int i = 0; i < attachment.length; i++) {
            var url = '${Endpoints.baseUrl}${'/api/fileservice/file/preview/'}${attachment[i].code}';
            bool isAudio = _isAudioFile(attachment[i].fileName);
            return Message(
              createdAt: dateTime,
              messageType: isAudio ? MessageType.voice : MessageType.file,
              status: MessageStatus.delivered,
              message: url,
              sentBy:sentBy
            );
          }
        }
        break;

      case "imSeatReturnResult":
        return Message(
          createdAt: dateTime,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy
        );

      case "imCustomerOverChat":
        return Message(
          createdAt: dateTime,
          status: MessageStatus.delivered,
          message: messJson.content ?? '',
          sentBy:sentBy
        );
    }
    print("null------------------------------${enumType}");
    return null;
  }

  // 检查文件是否为音频文件
  bool _isAudioFile(String? fileName) {
    if (fileName == null) return false;
    final audioExtensions = ['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'];
    return audioExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

}