// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:oktoast/oktoast.dart';
// import 'package:photo_manager/photo_manager.dart';
//
// import '../../constants/assets.dart';
// import '../../constants/colors.dart';
// import '../../utils/global_utils.dart';
//
// class MeImageScreen extends StatefulWidget {
//   final int type;
//
//   MeImageScreen({Key? key, required this.type}) : super(key: key);
//
//   @override
//   State<MeImageScreen> createState() => _MeScreenState();
// }
//
// class _MeScreenState extends State<MeImageScreen> with WidgetsBindingObserver {
//   //stores:---------------------------------------------------------------------
//
//   // final LanguageStore _languageStore = getIt<LanguageStore>();
//
//   //List<String> list = [];
//
//   List<AssetEntity> list = [];
//
//   var select2_3 = true;
//
//   ////List<XFile> list = [];
//
//   late VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//
//     //list.add("value");
//
//     _fetchAllImages();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       print("home app 从后台到前台");
//       _fetchAllImages();
//     }
//   }
//
//   void _fetchAllImages() async {
//     // 请求权限
//     final PermissionState permission =
//         await PhotoManager.requestPermissionExtend();
//     if (permission.isAuth) {
//       loadImageList();
//     } else if (permission.hasAccess) {
//       loadImageList();
//     } else {
//       PhotoManager.openSetting();
//       // 权限申请被拒绘
//       // 处理没有权限的情况
//     }
//   }
//
//   Future<void> loadImageList() async {
//     // 获取所有相册（相簿）
//     List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
//       filterOption: FilterOptionGroup(
//         imageOption: FilterOption(),
//         videoOption: FilterOption(needTitle: false),
//       ),
//     );
//     if (albums.isNotEmpty) {
//       // 当我们只关心所有图片的时候，我们通常访问第一个相册
//       final AssetPathEntity recentAlbum = albums.first;
//       // 获取相册内的所有AssetEntity(图片)
//       final List<AssetEntity> recentAssets =
//           await recentAlbum.getAssetListPaged(page: 0, size: 1000);
//       final List<AssetEntity> recentImages = recentAssets
//           .where((asset) => widget.type == 0
//               ? asset.type == AssetType.image
//               : asset.type == AssetType.video)
//           .toList();
//       // 存放所有视频
//       // List<AssetEntity> allVideos = [];
//       //  if (widget.type == 1) {
//       //    List<AssetPathEntity> albums = await PhotoManager.get(
//       //
//       //    );
//       //    // 遍历每个相册并获取视频
//       //    for (var album in albums) {
//       //      final List<AssetEntity> assets = await album.getAssetListPaged(page: 0, size: 1000);
//       //      allVideos.addAll(assets.where((asset) => asset.type == AssetType.video));
//       //    }
//       //  }
//
//       setState(() {
//         list = recentImages;
//         if (widget.type == 1) {
//           //list = allVideos;
//         }
//         list.insert(0, AssetEntity(id: "-a", typeInt: 1, width: 1, height: 1));
//       });
//     } else {
//       setState(() {
//         list = [];
//         list.insert(0, AssetEntity(id: "-a", typeInt: 1, width: 1, height: 1));
//       });
//     }
//   }
//
//   void _pickPhoto() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? photo = await picker.pickImage(source: ImageSource.camera);
//     if (photo != null) {
//       // nativePath = photo.path;
//       // setState(() {
//       //   nativePath;
//       // });
//       //GoRouter.of(context).push('${Routes.MeCropRoot}', extra: photo.path);
//       openAlbum(photo.path);
//     }
//   }
//
//   void _pickVideo() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? photo = await picker.pickVideo(
//         source: ImageSource.camera, maxDuration: Duration(seconds: 60));
//     if (photo != null) {
//       printN("video-path: ${photo.path}");
//       if (Platform.isAndroid) {
//         //FlutterNativeBridge.copyVideoPhoto(photo.path);
//       }
//       openAlbumVideo(photo.path);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: _buildBody(),
//     );
//   }
//
//   // app bar methods:-----------------------------------------------------------
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Color(0xFF101010),
//       elevation: 0,
//       // leading: IconButton(
//       //   icon: Image.asset('${Assets.appChart}navigation-back.png'),
//       //   iconSize: 24,
//       //   padding: EdgeInsets.all(12),
//       //   onPressed: () {
//       //     context.pop();
//       //   },
//       // ),
//       title: Column(
//         children: [
//           Text('Image Gallery',
//               style: TextStyle(
//                 color: Color(0xFFFFFFFF),
//                 fontSize: 18.0,
//                 fontWeight: FontWeight.bold,
//               )),
//         ],
//       ),
//       centerTitle: true,
//     );
//   }
//
//   Widget _buildBody() {
//     return Container(
//       alignment: Alignment.center,
//       margin: EdgeInsets.only(left: 16, right: 16),
//       child: Column(children: [
//         Container(
//           margin: EdgeInsets.only(left: 4, top: 16, right: 4),
//           alignment: Alignment.center,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Choose a picture to make a chat',
//                 style: TextStyle(
//                   color: Colors.white60,
//                   fontSize: 13,
//                 ),
//               ),
//               Container()
//               // Row(
//               //   children: [
//               //     GestureDetector(
//               //       onTap: () {
//               //         select2_3 = !select2_3;
//               //         setState(() {
//               //           select2_3;
//               //         });
//               //       },
//               //       child: Container(
//               //         width: 24,
//               //         height: 24,
//               //         child: Image.asset(
//               //           select2_3
//               //               ? '${Assets.appMe}ic_img_s2.png'
//               //               : '${Assets.appMe}ic_img_s2_un.png',
//               //         ),
//               //       ),
//               //     ),
//               //     SizedBox(
//               //       width: 16,
//               //     ),
//               //     GestureDetector(
//               //       onTap: () {
//               //         select2_3 = !select2_3;
//               //         setState(() {
//               //           select2_3;
//               //         });
//               //       },
//               //       child: Container(
//               //         width: 24,
//               //         height: 24,
//               //         child: Image.asset(
//               //           !select2_3
//               //               ? '${Assets.appMe}ic_img_s3.png'
//               //               : '${Assets.appMe}ic_img_s3_un.png',
//               //           // fit: BoxFit.cover, // 填充整个容器
//               //         ),
//               //       ),
//               //     )
//               //   ],
//               // ),
//             ],
//           ),
//         ),
//         SizedBox(
//           height: 20,
//         ),
//         Expanded(
//           child: GridView.builder(
//             shrinkWrap: true,
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: select2_3 ? 2 : 3, //每行三列
//               mainAxisSpacing: 16.0, //主轴方向的间距
//               crossAxisSpacing: 16.0, //横轴方向子元素的间距
//               childAspectRatio: 1, //子组件宽高长度比例
//             ),
//             itemCount: list.length,
//             itemBuilder: (BuildContext context, int index) {
//               return _buildListItem(context, index);
//             },
//           ),
//         )
//       ]),
//     );
//   }
//
//   Widget _buildListItem(BuildContext context, int index) {
//     var item = list[index];
//     return index == 0
//         ? GestureDetector(
//             onTap: () {
//               if (widget.type == 0)
//                 _pickPhoto();
//               else if (widget.type == 1) {
//                 _pickVideo();
//               }
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 color: AppColors.me_btn_bg1e,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Container(
//                 child: Container(
//                     alignment: Alignment.center,
//                     width: select2_3 ? 64 : 32,
//                     height: select2_3 ? 64 : 32,
//                     child: Center(
//                       child: Icon(Icons.photo),
//                       // child: Image.asset(
//                       //   width: select2_3 ? 64 : 32,
//                       //   height: select2_3 ? 64 : 32,
//                       //   '${Assets.appMe}ic_photo.png',
//                       //   // fit: BoxFit.cover, // 填充整个容器
//                       // ),
//                     )),
//               ),
//             ),
//           ) //: Container();
//         : GestureDetector(
//             onTap: () {
//               item.originFile.then((value) {
//                 printN("originFile-->" + value!.path);
//                 //GoRouter.of(context).push('${Routes.MeCropRoot}', extra: value.path);
//                 if (item.type == AssetType.video) {
//                   printN("originFile-->" + value.path);
//                   openAlbumVideo(value.path);
//                 } else {
//                   openAlbum(value.path);
//                 }
//               });
//             },
//             child: FutureBuilder<Uint8List?>(
//               future: item.thumbnailData,
//               builder: (_, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.done &&
//                     snapshot.data != null) {
//                   return Container(
//                     decoration: BoxDecoration(
//                       color: AppColors.me_btn_bg1e,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Stack(
//                       children: [
//                         AspectRatio(
//                           aspectRatio: 1.0,
//                           child: ClipRRect(
//                               borderRadius: BorderRadius.circular(20.0),
//                               child: Image.memory(
//                                 snapshot.data!,
//                                 fit: BoxFit.cover,
//                               )),
//                         ),
//                         item.type == AssetType.video
//                             ? Align(
//                                 alignment: Alignment.center, // 居中对齐
//                                 child: Icon(Icons.video_chat),
//                                 // child: Image.asset(
//                                 //   '${Assets.appMe}ic_video_play.png',
//                                 //   width: select2_3 ? 48 : 32, // 图像宽度
//                                 //   height: select2_3 ? 48 : 32, // 图像高度
//                                 // ),
//                               )
//                             : Container(),
//                       ],
//                     ),
//                   );
//                 }
//                 return ClipRRect(
//                   borderRadius: BorderRadius.circular(20.0),
//                   child: Container(
//                     child: Center(child: CircularProgressIndicator()),
//                   ),
//                 );
//               },
//             ),
//           );
//   }
//
//   void openAlbum(String path) {
//     GoRouter.of(context).push('${Routes.MeCropRoot}', extra: path);
//   }
//
//   void openAlbumVideo(String path) {
//     //GoRouter.of(context).push('${Routes.MeCropVideoRoot}', extra: path);
//     _controller = VideoPlayerController.file(File(path))
//       ..initialize().then((_) {
//         // 确保初始化完成后，更新状态
//         setState(() {
//           // 获取视频时长并转换为字符串格式
//           final duration = _controller.value.duration;
//           var durations = duration.inSeconds;
//           if (durations > 60) {
//             showToast(
//                 "The video length exceeds 60 seconds, please trim it and try again.");
//           } else {
//             ThemeModel themeMode = ThemeModel();
//             themeMode.themeImgUrl = path;
//             themeMode.templateId = duration.inSeconds;
//             GoRouter.of(context)
//                 .push('${Routes.ThemeVideoDetail}', extra: themeMode);
//           }
//         });
//         _controller.dispose();
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
