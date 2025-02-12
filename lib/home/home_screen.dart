import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/big_image/big_image_page.dart';
import 'package:clear_tool/home/clear_page/clear_page.dart';
import 'package:clear_tool/home/same_image/same_image_page.dart';
import 'package:clear_tool/home/screen_shot/screen_shot_page.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/permission_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:system_device_info/system_device_info.dart';
import 'package:circle_progress_bar/circle_progress_bar.dart' as cp;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<double> valueNotifier = ValueNotifier(0);

  String totalSize = '';
  String useSize = '';
  String deviceName = '';

  List<AssetEntity> screenshots = [];
  // List<AssetEntity> samePhotos = [];

  /// 相似照片集合
  List<SamePhotoGroup> samePhotos = [];

  /// 相似照片容量
  int samePhotoSize = 0;

  /// 屏幕截图合集
  List<ImageAsset> screenPhotos = [];

  /// 屏幕截图照片容量
  String screenPhotoSize = '';

  /// 大图合集
  List<ImageAsset> bigPhotos = [];

  /// 处理大图标记
  bool isBigProcessing = false;

  /// 大图照片容量
  String bigPhotoSize = '';

  /// 进度圆颜色
  Color color = Colors.white;

  /// 进度圆背景图片
  String progressBgImage = 'assets/images/home/blue_progress_bg.png';

  /// 订阅事件
  late StreamSubscription _streamSubscription;

  /// 开启定时器 检查存储空间
  late Timer diskTimer;

  @override
  void initState() {
    super.initState();
    valueNotifier.addListener(() {
      setState(() {});
    });
    changeLanguage();
    getDiskInfo();
    getScreenshots();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    diskTimer.cancel();
    valueNotifier.removeListener(() {});
    super.dispose();
  }

  void getScreenshots() async {
    _streamSubscription = globalStreamControler.stream.listen((event) async {
      if (event is AllPhotoLoadFinishEvent) {
        // 开启子线程检测数据
        FlutterIsolate.spawn(spawnSamePhotosIsolate, globalPort.sendPort);
        screenshotPhotoIsolate = await FlutterIsolate.spawn(
            spawnScreenshotIsolate, globalPort.sendPort);
        bigPhotoIsolate = await FlutterIsolate.spawn(
            spawnBigPhotosIsolate, globalPort.sendPort);
      } else if (event is SamePhotoEvent) {
        final group = event.group;
        // 获取所有图片id集合
        final newAssetList = <SamePhotoGroup>[];
        if (group.ids != null) {
          int sumSize = 0;
          for (var assetId in group.ids!) {
            if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(assetId)) {
              final assetEntity =
                  PhotoManagerTool.allPhotoAssetsIdMaps[assetId]!;
              final file = await assetEntity.originFile;
              if (file != null) {
                final length = await file.length();
                final thumbnailData = await assetEntity.thumbnailData;
                group.assets.add(ImageAsset(assetEntity)
                  ..originalFilePath = file.path
                  ..thumnailBytes = thumbnailData
                  ..length = length
                  );
                newAssetList.add(group);
                sumSize+=length;
              }
            }
          }
          setState(() {
            samePhotos.addAll(newAssetList);
          });
          samePhotoSize+=sumSize;
        }
        PhotoManagerTool.sameImageEntity = samePhotos;
        setState(() {});
      } else if (event is ScreenPhotoEvent) {
        // 获取所有图片id集合
        final newAssetList = <ImageAsset>[];
        if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(event.id)) {
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailData;
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        } else {
          PhotoManagerTool.allPhotoAssetsIdMaps[event.id] = PhotoManagerTool
              .allPhotoAssets
              .where((el) => el.id == event.id)
              .toList()
              .first;
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailData;
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        }
        screenPhotos.addAll(newAssetList);
        PhotoManagerTool.screenShotImageEntity = screenPhotos;
        setState(() {
          screenPhotoSize = AppUtils.fileSizeFormat(event.totalSize);
        });

        /// 发送二级页面事件
        globalStreamControler
            .add(SubScreenPhotoEvent(screenPhotos, event.totalSize));
      } else if (event is BigPhotoEvent) {
        // 获取所有图片id集合
        final newAssetList = <ImageAsset>[];
        if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(event.id)) {
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailData;
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        } else {
          PhotoManagerTool.allPhotoAssetsIdMaps[event.id] = PhotoManagerTool
              .allPhotoAssets
              .where((el) => el.id == event.id)
              .toList()
              .first;
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailData;
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        }
        int sumSize = 0;
        for (var asset in newAssetList) {
          final originalFilePath = asset.originalFilePath;
          if (originalFilePath != null) {
            final length = await File(originalFilePath).length();
            sumSize += length;
          }
        }
        PhotoManagerTool.bigImageEntity.addAll(newAssetList);
        bigPhotos = PhotoManagerTool.bigImageEntity;
        setState(() {
          PhotoManagerTool.bigSumSize += sumSize;
          bigPhotoSize = AppUtils.fileSizeFormat(PhotoManagerTool.bigSumSize);
        });

        /// 发送二级页面事件
        globalStreamControler.add(SubBigPhotoEvent(bigPhotos, sumSize));
      } else if (event is RefreshEvent) {
        setState(() {});
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () async {
      // 检查权限
      final havePermission = await PermissionUtils.checkPhotosPermisson(
          permisinUsingInfo: AppUtils.i18Translate(
              'common.dialog.use_info_photo',
              context: AppUtils.globalContext));
      if (havePermission) {
        PhotoManagerTool.allPhotoAssets = [];
        final assetPaths =
            await PhotoManager.getAssetPathList(type: RequestType.image);
        // 获取所有图片资源对象
        for (var album in assetPaths) {
          final count = await album.assetCountAsync;
          if (count > 0) {
            final assetItems =
                await album.getAssetListRange(start: 0, end: count);
            PhotoManagerTool.allPhotoAssets.addAll(assetItems);
            // id 映射
            for (var asset in assetItems) {
              if (!PhotoManagerTool.allPhotoAssetsIdMaps
                  .containsKey(asset.id)) {
                PhotoManagerTool.allPhotoAssetsIdMaps[asset.id] = asset;
              }
            }
          }
        }
        // 所有图片加载完成 发送通知
        globalStreamControler.add(AllPhotoLoadFinishEvent());
      }
    });
  }

  void changeLanguage() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final currentLang = FlutterI18n.currentLocale(context)!;
      final nextLang = currentLang.languageCode == 'zh'
          ? const Locale('zh')
          : const Locale('en');
      await FlutterI18n.refresh(context, nextLang);
      setState(() {});
    });
  }

  void getDiskInfo() async {
    final tz = await SystemDeviceInfo.totalSize();
    if (tz != null) {
      totalSize = AppUtils.fileSizeFormat(tz);
    }
    final fz = await SystemDeviceInfo.freeSize();
    if (fz != null) {
      useSize = AppUtils.fileSizeFormat(tz! - fz);
      final value = ((tz - fz) / tz) * 100;
      if (value > 90) {
        color = const Color(0xffEC5C0C);
        progressBgImage = 'assets/images/home/red_progress_bg.png';
      } else if (value > 70) {
        color = const Color(0xffE7950C);
        progressBgImage = 'assets/images/home/orange_progress_bg.png';
      } else if (value > 30) {
        color = const Color(0xffDAD31B);
        progressBgImage = 'assets/images/home/yellow_progress_bg.png';
      } else {
        color = AppColor.mainColor;
        progressBgImage = 'assets/images/home/blue_progress_bg.png';
      }
      valueNotifier.value = value;
      setState(() {});
    }

    if (Platform.isAndroid) {
      final anInfo = await DeviceInfoPlugin().androidInfo;
      deviceName = anInfo.model;
    } else {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceName = iosInfo.name ?? '';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppUtils.globalContext = context;
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverList.list(
            children: [
              _buildCircleProgressBar(),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  AppUtils.i18Translate("home.manualClear", context: context),
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buidManualItem(context),
            ],
          ),
          // SliverPadding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   sliver: SliverGrid.builder(
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 4,
          //       mainAxisSpacing: 5,
          //       crossAxisSpacing: 5,
          //     ),
          //     itemCount: hashs.keys.toList().length,
          //     itemBuilder: (context, index) {
          //       final assets = hashs.values.toList()[index];
          //       return Stack(
          //         children: [
          //           ClipRRect(
          //               borderRadius: BorderRadius.circular(4),
          //               child: Image.file(
          //                 File(assets),
          //                 fit: BoxFit.cover,
          //               )),
          //         ],
          //       );
          //     },
          //   ),
          // )
        ],
      ),
    );
  }

  Widget _buidManualItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const SameImagePage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 5.5,
                      color: const Color(0xffD6D6D6).withOpacity(0.5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 14.autoSize),
                    Image.asset('assets/images/home/same_icon.png'),
                    Padding(
                      padding: EdgeInsets.all(8.autoSize!),
                      child: Text(
                        AppUtils.i18Translate("home.samePhoto",
                            context: context),
                        style: TextStyle(
                          fontSize: 13.autoSize,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 7.autoSize),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xffDAE8FD),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.autoSize!,
                        vertical: 2.autoSize!,
                      ),
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 9.autoSize!),
                      height: 27.autoSize,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${samePhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}',
                                style: TextStyle(
                                  fontSize: 8.autoSize,
                                  color: const Color(0xff5E1FB2),
                                ),
                              ),
                              Text(
                                samePhotoSize > 0
                                    ? AppUtils.fileSizeFormat(samePhotoSize)
                                    : '0KB',
                                style: TextStyle(
                                  fontSize: 8.autoSize,
                                  color: const Color(0xff5E1FB2),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 6.autoSize,
                            color: const Color(0xff5E1FB2),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 9.autoSize),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BigImagePage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 5.5,
                      color: const Color(0xffD6D6D6).withOpacity(0.5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 14.autoSize),
                    Image.asset('assets/images/home/big_icon.png'),
                    Padding(
                      padding: EdgeInsets.all(8.autoSize!),
                      child: Text(
                        AppUtils.i18Translate("home.bigPhoto",
                            context: context),
                        style: TextStyle(
                          fontSize: 13.autoSize,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 7.autoSize),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xffE0F4FD),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.autoSize!,
                        vertical: 2.autoSize!,
                      ),
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 9.autoSize!),
                      height: 27.autoSize,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${PhotoManagerTool.bigImageEntity.length}${AppUtils.i18Translate('home.sheet', context: context)}',
                                style: TextStyle(
                                  fontSize: 8.autoSize!,
                                  color: const Color(0xff1C6EAA),
                                ),
                              ),
                              Text(
                                bigPhotoSize.isNotEmpty ? bigPhotoSize : '0KB',
                                style: TextStyle(
                                  fontSize: 8.autoSize!,
                                  color: const Color(0xff1C6EAA),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 6.autoSize,
                            color: const Color(0xff1C6EAA),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 9.autoSize),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ScreenShotPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 5.5,
                      color: const Color(0xffD6D6D6).withOpacity(0.5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 14.autoSize),
                    Image.asset('assets/images/home/screenshot_icon.png'),
                    Padding(
                      padding: EdgeInsets.all(8.autoSize!),
                      child: Text(
                        AppUtils.i18Translate("home.screenshot",
                            context: context),
                        style: TextStyle(
                          fontSize: 13.autoSize,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 7.autoSize),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xffDAE8FD),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.autoSize!,
                        vertical: 2.autoSize!,
                      ),
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 9.autoSize!),
                      height: 27.autoSize,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${screenPhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}',
                                style: TextStyle(
                                  fontSize: 8.autoSize!,
                                  color: const Color(0xff1B5FC4),
                                ),
                              ),
                              Text(
                                screenPhotoSize.isNotEmpty
                                    ? screenPhotoSize
                                    : '0KB',
                                style: TextStyle(
                                  fontSize: 8.autoSize!,
                                  color: const Color(0xff1B5FC4),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 6.autoSize,
                            color: const Color(0xff1B5FC4),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 9.autoSize),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildCircleProgressBar() {
    AppUtils.screenW = MediaQuery.of(context).size.width;
    final circleSize = 250.autoSize!;
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top, left: 12, right: 12),
      height: 369.autoSize,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffECFBFF),
            Color(0xffF9F9F9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$deviceName${AppUtils.i18Translate("home.diskSpace")}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColor.textPrimary,
            ),
          ),
          Row(
            children: [
              Text(
                '${AppUtils.i18Translate("home.useSpace")}$useSize,',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                '${AppUtils.i18Translate("home.totalSpace")}$totalSize',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    progressBgImage,
                    width: 260.autoSize!,
                    height: 260.autoSize!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(circleSize * 0.6 / 2),
                      color: Colors.white,
                    ),
                    width: circleSize * 0.6,
                    height: circleSize * 0.6,
                  ),
                  SizedBox(
                    width: circleSize * 0.6,
                    height: circleSize * 0.6,
                    child: Transform.rotate(
                      angle: 90 * pi / 180,
                      child: cp.CircleProgressBar(
                        foregroundColor: color,
                        backgroundColor: Colors.white,
                        strokeWidth: 14,
                        value: valueNotifier.value / 100,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppUtils.i18Translate('home.useSpace'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text.rich(
                        TextSpan(children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.bottom,
                            child: Text(
                              valueNotifier.value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 43,
                                color: AppColor.textPrimary,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                          const WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ClearPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.autoSize!),
                  color: const Color(0xff247AF2),
                ),
                width: 176.autoSize,
                height: 40.autoSize,
                margin: const EdgeInsets.only(bottom: 10),
                alignment: Alignment.center,
                child: Text(
                  AppUtils.i18Translate('home.smartClear'),
                  style: TextStyle(
                    fontSize: 15.autoSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
