class ChannelConfigModel {
  final AccessParams accessParams;
  final EvaluateParams evaluateParams;
  final DialogueParams dialogueParams;
  final InviteParams inviteParams;

  ChannelConfigModel({
    required this.accessParams,
    required this.evaluateParams,
    required this.dialogueParams,
    required this.inviteParams,
  });

  factory ChannelConfigModel.fromJson(Map<String, dynamic> json) {
    return ChannelConfigModel(
      accessParams: AccessParams.fromJson(json['accessParams'] as Map<String, dynamic>),
      evaluateParams: EvaluateParams.fromJson(json['evaluateParams'] as Map<String, dynamic>),
      dialogueParams: DialogueParams.fromJson(json['dialogueParams'] as Map<String, dynamic>),
      inviteParams: InviteParams.fromJson(json['inviteParams'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessParams': accessParams.toJson(),
      'evaluateParams': evaluateParams.toJson(),
      'dialogueParams': dialogueParams.toJson(),
      'inviteParams': inviteParams.toJson(),
    };
  }
}

class AccessParams {
  final String? mobileButtonText;
  final dynamic mobileButtonTextColor;
  final dynamic adaptHttp;
  final int channelType;
  final int mobileOpenWindowModel;
  final int mobileButtonType;
  final int buttonTypeImgHeight;
  final int buttonTypeImgWidth;
  final String buttonTypeImg;
  final String windowName;
  final int id;
  final int windowOptionAppwebAgent;
  final String buttonText;
  final int buttonMarginTop;
  final int windowOptionAppwebMsg;
  final String mobileButtonColor;
  final dynamic adaptAuto;
  final int buttonMarginLeft;
  final String windowThemeColor;
  final int buttonMarginRight;
  final String windowLogo;
  final int cid;
  final String buttonColor;
  final int mobileButtonLocation;
  final String windowTitle;
  final String openWindowWidth;
  final int windowOptionFace;
  final int buttonMarginBottom;
  final int button;
  final dynamic adaptHttps;
  final String buttonType;
  final int openWindowModel;
  final int buttonLocation;
  final int windowOptionMsg;
  final String buttonTextColor;
  final int windowOptionAppwebPhoto;
  final String mobileOpenWindowWidth;
  final int mobileButtonMarginLeft;
  final int windowOptionFile;
  final String updateTime;
  final int mobileButtonMarginBottom;
  final int windowOptionDownrecrod;
  final int mobileButtonMarginTop;
  final String createTime;
  final int windowOptionAgent;
  final int windowOptionAppwebShoot;
  final String channelName;
  final int mobileButtonMarginRight;
  final int channelid;

  AccessParams({
    this.mobileButtonText,
    this.mobileButtonTextColor,
    this.adaptHttp,
    required this.channelType,
    required this.mobileOpenWindowModel,
    required this.mobileButtonType,
    required this.buttonTypeImgHeight,
    required this.buttonTypeImgWidth,
    required this.buttonTypeImg,
    required this.windowName,
    required this.id,
    required this.windowOptionAppwebAgent,
    required this.buttonText,
    required this.buttonMarginTop,
    required this.windowOptionAppwebMsg,
    required this.mobileButtonColor,
    this.adaptAuto,
    required this.buttonMarginLeft,
    required this.windowThemeColor,
    required this.buttonMarginRight,
    required this.windowLogo,
    required this.cid,
    required this.buttonColor,
    required this.mobileButtonLocation,
    required this.windowTitle,
    required this.openWindowWidth,
    required this.windowOptionFace,
    required this.buttonMarginBottom,
    required this.button,
    this.adaptHttps,
    required this.buttonType,
    required this.openWindowModel,
    required this.buttonLocation,
    required this.windowOptionMsg,
    required this.buttonTextColor,
    required this.windowOptionAppwebPhoto,
    required this.mobileOpenWindowWidth,
    required this.mobileButtonMarginLeft,
    required this.windowOptionFile,
    required this.updateTime,
    required this.mobileButtonMarginBottom,
    required this.windowOptionDownrecrod,
    required this.mobileButtonMarginTop,
    required this.createTime,
    required this.windowOptionAgent,
    required this.windowOptionAppwebShoot,
    required this.channelName,
    required this.mobileButtonMarginRight,
    required this.channelid,
  });

  factory AccessParams.fromJson(Map<String, dynamic> json) {
    return AccessParams(
      mobileButtonText: json['mobileButtonText'] as String?,
      mobileButtonTextColor: json['mobileButtonTextColor'],
      adaptHttp: json['adaptHttp'],
      channelType: json['channelType'] as int,
      mobileOpenWindowModel: json['mobileOpenWindowModel'] as int,
      mobileButtonType: json['mobileButtonType'] as int,
      buttonTypeImgHeight: json['buttonTypeImgHeight'] as int,
      buttonTypeImgWidth: json['buttonTypeImgWidth'] as int,
      buttonTypeImg: json['buttonTypeImg'] as String,
      windowName: json['windowName'] as String,
      id: json['id'] as int,
      windowOptionAppwebAgent: json['windowOptionAppwebAgent'] as int,
      buttonText: json['buttonText'] as String,
      buttonMarginTop: json['buttonMarginTop'] as int,
      windowOptionAppwebMsg: json['windowOptionAppwebMsg'] as int,
      mobileButtonColor: json['mobileButtonColor'] as String,
      adaptAuto: json['adaptAuto'],
      buttonMarginLeft: json['buttonMarginLeft'] as int,
      windowThemeColor: json['windowThemeColor'] as String,
      buttonMarginRight: json['buttonMarginRight'] as int,
      windowLogo: json['windowLogo'] as String,
      cid: json['cid'] as int,
      buttonColor: json['buttonColor'] as String,
      mobileButtonLocation: json['mobileButtonLocation'] as int,
      windowTitle: json['windowTitle'] as String,
      openWindowWidth: json['openWindowWidth'] as String,
      windowOptionFace: json['windowOptionFace'] as int,
      buttonMarginBottom: json['buttonMarginBottom'] as int,
      button: json['button'] as int,
      adaptHttps: json['adaptHttps'],
      buttonType: json['buttonType'] as String,
      openWindowModel: json['openWindowModel'] as int,
      buttonLocation: json['buttonLocation'] as int,
      windowOptionMsg: json['windowOptionMsg'] as int,
      buttonTextColor: json['buttonTextColor'] as String,
      windowOptionAppwebPhoto: json['windowOptionAppwebPhoto'] as int,
      mobileOpenWindowWidth: json['mobileOpenWindowWidth'] as String,
      mobileButtonMarginLeft: json['mobileButtonMarginLeft'] as int,
      windowOptionFile: json['windowOptionFile'] as int,
      updateTime: json['updateTime'] as String,
      mobileButtonMarginBottom: json['mobileButtonMarginBottom'] as int,
      windowOptionDownrecrod: json['windowOptionDownrecrod'] as int,
      mobileButtonMarginTop: json['mobileButtonMarginTop'] as int,
      createTime: json['createTime'] as String,
      windowOptionAgent: json['windowOptionAgent'] as int,
      windowOptionAppwebShoot: json['windowOptionAppwebShoot'] as int,
      channelName: json['channelName'] as String,
      mobileButtonMarginRight: json['mobileButtonMarginRight'] as int,
      channelid: json['channelid'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobileButtonText': mobileButtonText,
      'mobileButtonTextColor': mobileButtonTextColor,
      'adaptHttp': adaptHttp,
      'channelType': channelType,
      'mobileOpenWindowModel': mobileOpenWindowModel,
      'mobileButtonType': mobileButtonType,
      'buttonTypeImgHeight': buttonTypeImgHeight,
      'buttonTypeImgWidth': buttonTypeImgWidth,
      'buttonTypeImg': buttonTypeImg,
      'windowName': windowName,
      'id': id,
      'windowOptionAppwebAgent': windowOptionAppwebAgent,
      'buttonText': buttonText,
      'buttonMarginTop': buttonMarginTop,
      'windowOptionAppwebMsg': windowOptionAppwebMsg,
      'mobileButtonColor': mobileButtonColor,
      'adaptAuto': adaptAuto,
      'buttonMarginLeft': buttonMarginLeft,
      'windowThemeColor': windowThemeColor,
      'buttonMarginRight': buttonMarginRight,
      'windowLogo': windowLogo,
      'cid': cid,
      'buttonColor': buttonColor,
      'mobileButtonLocation': mobileButtonLocation,
      'windowTitle': windowTitle,
      'openWindowWidth': openWindowWidth,
      'windowOptionFace': windowOptionFace,
      'buttonMarginBottom': buttonMarginBottom,
      'button': button,
      'adaptHttps': adaptHttps,
      'buttonType': buttonType,
      'openWindowModel': openWindowModel,
      'buttonLocation': buttonLocation,
      'windowOptionMsg': windowOptionMsg,
      'buttonTextColor': buttonTextColor,
      'windowOptionAppwebPhoto': windowOptionAppwebPhoto,
      'mobileOpenWindowWidth': mobileOpenWindowWidth,
      'mobileButtonMarginLeft': mobileButtonMarginLeft,
      'windowOptionFile': windowOptionFile,
      'updateTime': updateTime,
      'mobileButtonMarginBottom': mobileButtonMarginBottom,
      'windowOptionDownrecrod': windowOptionDownrecrod,
      'mobileButtonMarginTop': mobileButtonMarginTop,
      'createTime': createTime,
      'windowOptionAgent': windowOptionAgent,
      'windowOptionAppwebShoot': windowOptionAppwebShoot,
      'channelName': channelName,
      'mobileButtonMarginRight': mobileButtonMarginRight,
      'channelid': channelid,
    };
  }
}

class EvaluateParams {
  final int id;
  final String serviceEvaluateTxt;
  final int evaluationFlag;
  final List<ImEvaluationDefine> imEvaluationDefineList;

  EvaluateParams({
    required this.id,
    required this.serviceEvaluateTxt,
    required this.evaluationFlag,
    required this.imEvaluationDefineList,
  });

  factory EvaluateParams.fromJson(Map<String, dynamic> json) {
    var list = json['imEvaluationDefineList'] as List;
    List<ImEvaluationDefine> defineList = list
        .map((e) => ImEvaluationDefine.fromJson(e as Map<String, dynamic>))
        .toList();

    return EvaluateParams(
      id: json['id'] as int,
      serviceEvaluateTxt: json['serviceEvaluateTxt'] as String,
      evaluationFlag: json['evaluationFlag'] as int,
      imEvaluationDefineList: defineList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceEvaluateTxt': serviceEvaluateTxt,
      'evaluationFlag': evaluationFlag,
      'imEvaluationDefineList': imEvaluationDefineList.map((e) => e.toJson()).toList(),
    };
  }
}

class ImEvaluationDefine {
  final int id;
  final int cid;
  final String pressKey;
  final String pressValue;
  final String createTime;
  final String updateTime;

  ImEvaluationDefine({
    required this.id,
    required this.cid,
    required this.pressKey,
    required this.pressValue,
    required this.createTime,
    required this.updateTime,
  });

  factory ImEvaluationDefine.fromJson(Map<String, dynamic> json) {
    return ImEvaluationDefine(
      id: json['id'] as int,
      cid: json['cid'] as int,
      pressKey: json['pressKey'] as String,
      pressValue: json['pressValue'] as String,
      createTime: json['createTime'] as String,
      updateTime: json['updateTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cid': cid,
      'pressKey': pressKey,
      'pressValue': pressValue,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }
}

class DialogueParams {
  final int id;
  final int timeoutReply;
  final int timeoutEnd;
  final String timeoutReplyMsg;
  final int timeoutReplyTime;
  final int timeoutReplyNum;
  final String personTimeids;
  final int transferHistoryEmp;
  final int transferHistoryBusy;
  final int robotPriority;
  final dynamic defaultRobot;
  final String personWelcomeSpeech;
  final String personTimeOutMsg;
  final String personOutMsg;
  final dynamic endMsg;
  final int busyReply;
  final String busyReplyMsg;
  final int busyReplyTime;
  final int busyReplyNum;
  final int prologue;
  final dynamic prologueQuestion;
  final String unrecognizedReplyMsg;
  final String dialogNickname;

  DialogueParams({
    required this.id,
    required this.timeoutReply,
    required this.timeoutEnd,
    required this.timeoutReplyMsg,
    required this.timeoutReplyTime,
    required this.timeoutReplyNum,
    required this.personTimeids,
    required this.transferHistoryEmp,
    required this.transferHistoryBusy,
    required this.robotPriority,
    this.defaultRobot,
    required this.personWelcomeSpeech,
    required this.personTimeOutMsg,
    required this.personOutMsg,
    this.endMsg,
    required this.busyReply,
    required this.busyReplyMsg,
    required this.busyReplyTime,
    required this.busyReplyNum,
    required this.prologue,
    this.prologueQuestion,
    required this.unrecognizedReplyMsg,
    required this.dialogNickname,
  });

  factory DialogueParams.fromJson(Map<String, dynamic> json) {
    return DialogueParams(
      id: json['id'] as int,
      timeoutReply: json['timeoutReply'] as int,
      timeoutEnd: json['timeoutEnd'] as int,
      timeoutReplyMsg: json['timeoutReplyMsg'] as String,
      timeoutReplyTime: json['timeoutReplyTime'] as int,
      timeoutReplyNum: json['timeoutReplyNum'] as int,
      personTimeids: json['personTimeids'] as String,
      transferHistoryEmp: json['transferHistoryEmp'] as int,
      transferHistoryBusy: json['transferHistoryBusy'] as int,
      robotPriority: json['robotPriority'] as int,
      defaultRobot: json['defaultRobot'],
      personWelcomeSpeech: json['personWelcomeSpeech'] as String,
      personTimeOutMsg: json['personTimeOutMsg'] as String,
      personOutMsg: json['personOutMsg'] as String,
      endMsg: json['endMsg'],
      busyReply: json['busyReply'] as int,
      busyReplyMsg: json['busyReplyMsg'] as String,
      busyReplyTime: json['busyReplyTime'] as int,
      busyReplyNum: json['busyReplyNum'] as int,
      prologue: json['prologue'] as int,
      prologueQuestion: json['prologueQuestion'],
      unrecognizedReplyMsg: json['unrecognizedReplyMsg'] as String,
      dialogNickname: json['dialogNickname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeoutReply': timeoutReply,
      'timeoutEnd': timeoutEnd,
      'timeoutReplyMsg': timeoutReplyMsg,
      'timeoutReplyTime': timeoutReplyTime,
      'timeoutReplyNum': timeoutReplyNum,
      'personTimeids': personTimeids,
      'transferHistoryEmp': transferHistoryEmp,
      'transferHistoryBusy': transferHistoryBusy,
      'robotPriority': robotPriority,
      'defaultRobot': defaultRobot,
      'personWelcomeSpeech': personWelcomeSpeech,
      'personTimeOutMsg': personTimeOutMsg,
      'personOutMsg': personOutMsg,
      'endMsg': endMsg,
      'busyReply': busyReply,
      'busyReplyMsg': busyReplyMsg,
      'busyReplyTime': busyReplyTime,
      'busyReplyNum': busyReplyNum,
      'prologue': prologue,
      'prologueQuestion': prologueQuestion,
      'unrecognizedReplyMsg': unrecognizedReplyMsg,
      'dialogNickname': dialogNickname,
    };
  }
}

class InviteParams {
  final int id;
  final int inviteFlag;
  final int inviteModel;
  final String inviteTitle;
  final String inviteInfo;
  final int inviteTime;
  final int inviteRefuseTime;
  final int inviteRefuseType;
  final int inviteRefuseCount;
  final int inviteAutoAnswer;
  final int inviteAutoTime;
  final String inviteTextColor;
  final String inviteWindowColor;
  final String inviteBottenColor;

  InviteParams({
    required this.id,
    required this.inviteFlag,
    required this.inviteModel,
    required this.inviteTitle,
    required this.inviteInfo,
    required this.inviteTime,
    required this.inviteRefuseTime,
    required this.inviteRefuseType,
    required this.inviteRefuseCount,
    required this.inviteAutoAnswer,
    required this.inviteAutoTime,
    required this.inviteTextColor,
    required this.inviteWindowColor,
    required this.inviteBottenColor,
  });

  factory InviteParams.fromJson(Map<String, dynamic> json) {
    return InviteParams(
      id: json['id'] as int,
      inviteFlag: json['inviteFlag'] as int,
      inviteModel: json['inviteModel'] as int,
      inviteTitle: json['inviteTitle'] as String,
      inviteInfo: json['inviteInfo'] as String,
      inviteTime: json['inviteTime'] as int,
      inviteRefuseTime: json['inviteRefuseTime'] as int,
      inviteRefuseType: json['inviteRefuseType'] as int,
      inviteRefuseCount: json['inviteRefuseCount'] as int,
      inviteAutoAnswer: json['inviteAutoAnswer'] as int,
      inviteAutoTime: json['inviteAutoTime'] as int,
      inviteTextColor: json['inviteTextColor'] as String,
      inviteWindowColor: json['inviteWindowColor'] as String,
      inviteBottenColor: json['inviteBottenColor'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviteFlag': inviteFlag,
      'inviteModel': inviteModel,
      'inviteTitle': inviteTitle,
      'inviteInfo': inviteInfo,
      'inviteTime': inviteTime,
      'inviteRefuseTime': inviteRefuseTime,
      'inviteRefuseType': inviteRefuseType,
      'inviteRefuseCount': inviteRefuseCount,
      'inviteAutoAnswer': inviteAutoAnswer,
      'inviteAutoTime': inviteAutoTime,
      'inviteTextColor': inviteTextColor,
      'inviteWindowColor': inviteWindowColor,
      'inviteBottenColor': inviteBottenColor,
    };
  }
}