import 'dart:async';

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
  String _currentUserId = "user-id";

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
    });
    // 订阅消息流
    _messageSubscription2 = CSocketIOManager().messagesStream2.listen((msg) {
      print("===>>>2222> Msg DATA ${msg.sentBy}");
      //msg.sentBy = "2";
      var _msg = msg.copyWith(sentBy: "${_currentUserId}");
      _chatController.addMessage(_msg);
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
        sentBy: '2',
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
      //resizeToAvoidBottomInset: true,
      body: SafeArea(child:
        RefreshIndicator( // <-- 使用 RefreshIndicator 包裹 ChatView
        onRefresh: () async {
          // 这里是你的刷新逻辑，通常是从服务器重新加载消息
          print("开始刷新");
          // 模拟一个网络请求延迟
          loadData();
          //await Future.delayed(Duration(seconds: 2));
          // TODO: 替换为你的实际数据刷新逻辑，例如：
          // await _yourDataRefreshFunction();
          // 刷新完成后，RefreshIndicator 会自动隐藏
          setState(() {
            // 如果刷新逻辑涉及更新状态，可以在这里调用 setState
          });
    },
    color: theme.outgoingChatBubbleColor, // 可选项：设置指示器颜色以匹配主题
    backgroundColor: theme.backgroundColor, // 可选项：设置背景颜色以匹配主题
    child:
      ChatView(
        chatController: _chatController,
        onSendTap: _onSendTap,
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
          enableScrollToBottomButton: true,
        ),
        scrollToBottomButtonConfig: ScrollToBottomButtonConfig(
          backgroundColor: theme.textFieldBackgroundColor,
          border: Border.all(
            color: isDarkTheme ? Colors.transparent : Colors.grey,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.themeIconColor,
            weight: 10,
            size: 30,
          ),
        ),
        chatViewState: ChatViewState.hasMessages,
        chatViewStateConfig: ChatViewStateConfiguration(
          loadingWidgetConfig: ChatViewStateWidgetConfiguration(
            loadingIndicatorColor: theme.outgoingChatBubbleColor,
          ),
          onReloadButtonTap: () {},
        ),
        typeIndicatorConfig: TypeIndicatorConfiguration(
          flashingCircleBrightColor: theme.flashingCircleBrightColor,
          flashingCircleDarkColor: theme.flashingCircleDarkColor,
        ),
        appBar: AppBar(
          title: Text('小宇客服'),
          centerTitle: true,
          actions: [IconButton(icon: Icon(_isSound ?
          Icons.volume_up :
          Icons.volume_off), onPressed: _toggleSound,
              tooltip: _isSound ? '打开声音' : '关闭声音')],
        ),
        // ChatViewAppBar(
        //   elevation: theme.elevation,
        //   backGroundColor: theme.appBarColor,
        //   profilePicture: Data.profileImage,
        //   backArrowColor: theme.backArrowColor,
        //   chatTitle: "Chat view",
        //
        //   chatTitleTextStyle: TextStyle(
        //     color: theme.appBarTitleTextStyle,
        //     fontWeight: FontWeight.bold,
        //     fontSize: 18,
        //     letterSpacing: 0.25,
        //   ),
        //   userStatus: "online",
        //   userStatusTextStyle: const TextStyle(color: Colors.grey),
        //   actions: [
        //     IconButton(
        //       onPressed: _onThemeIconTap,
        //       icon: Icon(
        //         isDarkTheme
        //             ? Icons.brightness_4_outlined
        //             : Icons.dark_mode_outlined,
        //         color: theme.themeIconColor,
        //       ),
        //     ),
        //     IconButton(
        //       tooltip: 'Toggle TypingIndicator',
        //       onPressed: _showHideTypingIndicator,
        //       icon: Icon(
        //         Icons.keyboard,
        //         color: theme.themeIconColor,
        //       ),
        //     ),
        //     IconButton(
        //       tooltip: 'Simulate Message receive',
        //       onPressed: receiveMessage,
        //       icon: Icon(
        //         Icons.supervised_user_circle,
        //         color: theme.themeIconColor,
        //       ),
        //     ),
        //   ],
        // ),
        chatBackgroundConfig: ChatBackgroundConfiguration(
          messageTimeIconColor: theme.messageTimeIconColor,
          messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
          defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
            textStyle: TextStyle(
              color: theme.chatHeaderColor,
              fontSize: 17,
            ),
          ),
          backgroundColor: theme.backgroundColor,
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
            color: theme.outgoingChatBubbleColor,
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
            senderNameTextStyle:
            TextStyle(color: theme.inComingChatBubbleTextColor),
            color: theme.inComingChatBubbleColor,
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
            backgroundColor: theme.messageReactionBackGroundColor,
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
        profileCircleConfig: ProfileCircleConfiguration(

          profileImageUrl: Data.profileImage,
        ),
        repliedMessageConfig: RepliedMessageConfiguration(
          backgroundColor: theme.repliedMessageColor,
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
      )),
    ));
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
    //lastTime = DateTime.now().toUtc().millisecondsSinceEpoch;

    var map = await DioClient().getHistoryList(page,lastTime);
    MessagePageResponse response = MessagePageResponse.fromJson(map);




    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var evaluationFlag = sharedPreferences.getInt("sharedPreferences");
    var serviceEvaluateTxt = sharedPreferences.getString("serviceEvaluateTxt");

    if (response.page!.total! >= 30) {
      page++;
    }
    if (response.page!.records!.isNotEmpty) {
      for(int i = 0; i < response.page!.records!.length; i++) {
        printN("history====${response.page!.records![i].toJson()}");
        var dateTime = DateTime.now();
        //printN("_handleSocketIm  enumType= $enumType");
        var msgBean = response.page!.records![i];

        var messJson = response.page!.records![i].messJson;

        String? enumType = messJson!.enumType;
        String? type = messJson!.type;
        int? userId = msgBean.msgSendId ?? 0;
        String? sendName = msgBean.sendName;
        String? sendAvatar = msgBean.sendAvatar;

        if (enumType != "") {
          // 调用提取的方法
          await CSocketIOManager().handleEnumType(
              enumType: enumType,
              dateTime: dateTime,
              sharedPreferences: sharedPreferences,
              evaluationFlag: evaluationFlag,
              serviceEvaluateTxt: serviceEvaluateTxt,

              // -------------------------- 从 msgBean 提取的所有非必传字段 --------------------------
              type: messJson.type,                  // 消息类型（如 "notice"）
              msg: messJson.content,                    // 原始消息内容
              msgId: msgBean.messId,                // 消息ID（msgBean 原有字段）
              messId: msgBean.messId,              // 消息ID（msgBean 原有字段，与 msgId 区分）
              msgSendId: msgBean.msgSendId,        // 消息发送者ID
              serviceId: messJson.serviceId,        // 服务ID（评价相关）
              complex: messJson.complex,            // 复杂消息数据（ComplexData 类型）
              navigationList: messJson.navigationList, // 导航菜单列表（ChatMenuItem 类型）
              title: messJson.title,                // 导航/消息标题
              welcomeSpeech: messJson.welcomeSpeech, // 欢迎语数据（WelcomeSpeechData 类型）
              links: messJson.links,                // 链接列表（ChatLinkItem 类型）
              content: messJson.content,            // 文本/媒体内容
              conversationCode: messJson.conversationCode, // 会话编码（媒体预览用）
              url: messJson.url,                    // 媒体URL（视频/语音）
              imgs: messJson.imgs,                  // 图片列表（ImageData 类型）
              attachment: messJson.attachment,      // 附件列表（AttachmentData 类型）
              digest: messJson.digest               // 复杂消息摘要
          );
        }
      }
    }
  }

}