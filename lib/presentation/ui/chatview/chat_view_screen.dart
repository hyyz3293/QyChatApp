import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:qychatapp/presentation/constants/assets.dart';
import 'package:qychatapp/presentation/ui/chart/message_event.dart';
import 'package:qychatapp/presentation/ui/chatview/theme.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
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
import '../../utils/service_locator.dart';
import '../../utils/websocket/chat_socket_manager.dart';
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
  String _currentUserId = "";

  StreamSubscription<Message>? _messageSubscription;

  final EventBus eventBus = EventBus();

  late StreamSubscription<ChatUser> _otherSubscription;


  List<ChatUser> otherList = [ChatUser(
    id: '2',
    name: '',
    profilePhoto: "${Assets.appImages}headImg6.png",
    imageType: ImageType.asset,
  ),];

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
      var _msg = msg.copyWith(sentBy: "2");;
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
  }

  @override
  void dispose() {
    // ChatController should be disposed to avoid memory leaks
    _chatController.dispose();
    _messageSubscription?.cancel();
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
      body: SafeArea(child: ChatView(
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
    );
  }

  void _onSendTap(
      String message,
      ReplyMessage replyMessage,
      MessageType messageType,
      ) {
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
      _currentUserId = '${userId}';
    });
  }
}