import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/big_image/big_image_page.dart';
import 'package:clear_tool/home/same_image/same_image_page.dart';
import 'package:clear_tool/home/screen_shot/screen_shot_page.dart';
import 'package:clear_tool/home/widget/circle_progress.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:image_compare_2/image_compare_2.dart';
import 'package:images_picker/images_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:system_device_info/system_device_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ValueNotifier<double> valueNotifier = ValueNotifier(0);

  String totalSize = '';
  String useSize = '';
  String deviceName = '';

  List<AssetEntity> screenshots = [];
  // List<AssetEntity> samePhotos = [];

  /// 相似照片集合
  List<IsolateAssetMessage> samePhotos = [];

  /// 相似照片容量
  String samePhotoSize = '';

  Color color = Colors.red;
  // late Worker worker;
  late StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    // worker = Worker();
    changeLanguage();
    getDiskInfo();
    getScreenshots();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  void getScreenshots() async {
    _streamSubscription = globalStreamControler.stream.listen((event) async {
      if (event is SamePhotoEvent) {
        int sumSize = 0;
        for (var map in event.assets) {
          // 查找是否存在重复的图片
          final findElements = samePhotos
              .where(
                  (element) => element.id != null && element.id! == map['id'])
              .toList();
          if (findElements.isNotEmpty) continue;
          final asset = IsolateAssetMessage.fromJson(map);
          if (asset.orignalFilePath != null) {
            final length = await File(asset.orignalFilePath!).length();
            sumSize += length;
          }
          samePhotos.add(IsolateAssetMessage.fromJson(map));
        }
        PhotoManagerTool.sameImageEntity = samePhotos;
        samePhotoSize = formatData(sumSize);
        setState(() {});
      }
    });
    // FlutterIsolate.spawn<Map<String, dynamic>>(
    //     _HomeScreenState.backgroundFetchSamePhotos, {});

    // samePhotos = await PhotoManagerTool.filterSamePhotos();
    // setState(() {});
    // final number = await PhotoManager.getAssetCount();
    // screenshots = await PhotoManagerTool.fetchScreenShots();
    // setState(() {});
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
      totalSize = formatData(tz);
    }
    final fz = await SystemDeviceInfo.freeSize();
    if (fz != null) {
      useSize = formatData(tz! - fz);
      final value = ((tz - fz) / tz) * 100;
      valueNotifier.value = value;
      if (value > 90) {
        color = AppColor.red;
      } else if (value > 70) {
        color = Colors.orange;
      } else if (value > 30) {
        color = AppColor.yellow;
      } else {
        color = AppColor.mainColor;
      }
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

  String formatData(int size) {
    final unit = ['B', 'KB', 'MB', 'GB'];
    final tp = (log(size) / log(1024)).floor();
    return '${(size / pow(1024, tp)).toStringAsFixed(2)}${unit[tp.toInt()]}';
  }

  @override
  Widget build(BuildContext context) {
    AppUtils.context = context;
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),
      body: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, left: 12, right: 12),
        child: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                _buildCircleProgressBar(),
                Text(
                  AppUtils.i18Translate("home.manualClear"),
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buidManualItem(context),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _loadImage(AssetEntity asset) async {
    final imgW = AppUtils.screenW / 2;
    return await asset.originBytes;
  }

  Row _buidManualItem(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SameImagePage()),
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
                      AppUtils.i18Translate("home.samePhoto"),
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
                              '${samePhotos.length}${AppUtils.i18Translate('home.sheet')}',
                              style: TextStyle(
                                fontSize: 8.autoSize,
                                color: const Color(0xff5E1FB2),
                              ),
                            ),
                            Text(
                              samePhotoSize,
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
                      AppUtils.i18Translate("home.bigPhoto"),
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
                              '0${AppUtils.i18Translate('home.sheet')}',
                              style: TextStyle(
                                fontSize: 8.autoSize!,
                                color: const Color(0xff1C6EAA),
                              ),
                            ),
                            Text(
                              '0.00KB',
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
                MaterialPageRoute(builder: (context) => const ScreenShotPage()),
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
                      AppUtils.i18Translate("home.screenshot"),
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
                              '0${AppUtils.i18Translate('home.sheet')}',
                              style: TextStyle(
                                fontSize: 8.autoSize!,
                                color: const Color(0xff1B5FC4),
                              ),
                            ),
                            Text(
                              '0.00KB',
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
    );
  }

  Container _buildCircleProgressBar() {
    return Container(
      height: 369.autoSize,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xffECFBFF),
            Color(0xffF9F9F9),
          ],
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
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
            child: Container(
              child: CircleProgressBar(
                valueNotifier: valueNotifier,
                color: color,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () async {
                getScreenshots();
                // final number = await PhotoManagerTool.getPhotoCount();
                // PhotoManagerTool.fetchPhoto(1);
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
