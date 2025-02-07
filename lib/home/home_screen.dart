import 'dart:io';
import 'dart:math';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/home/widget/circle_progress.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:path_provider/path_provider.dart';
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

  @override
  void initState() {
    super.initState();
    changeLanguage();
    getDiskInfo();
    getPhotos();
  }

  void getPhotos()async{
       await compute(PhotoManagerTool.filterSamePhotos(), null);

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
      valueNotifier.value = ((tz - fz) / tz) * 100;
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
    final tp = (log(size) / log(1000)).floor();
    return '${(size / pow(1000, tp)).toStringAsFixed(2)}${unit[tp.toInt()]}';
  }

  @override
  Widget build(BuildContext context) {
    AppUtils.context = context;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, left: 12, right: 12),
        child: CustomScrollView(
          slivers: [
            SliverList.list(
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
                _buildCircleProgressBar(),
                Text(
                  AppUtils.i18Translate("home.manualClear"),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColor.textPrimary, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppUtils.i18Translate("home.samePhoto"),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColor.textSecondary,
                              ),
                              width: 90,
                              height: 90,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xff2D74C7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Column(
                                children: [
                                  Text(
                                    '0${AppUtils.i18Translate('home.sheet')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    '0.00KB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColor.textPrimary, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppUtils.i18Translate("home.bigPhoto"),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColor.textSecondary,
                              ),
                              width: 90,
                              height: 90,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xff2D74C7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Column(
                                children: [
                                  Text(
                                    '0${AppUtils.i18Translate('home.sheet')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    '0.00KB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColor.textPrimary, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                AppUtils.i18Translate("home.screenshot"),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColor.textSecondary,
                              ),
                              width: 90,
                              height: 90,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xff2D74C7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              child: Column(
                                children: [
                                  Text(
                                    '0${AppUtils.i18Translate('home.sheet')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    '0.00KB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Container _buildCircleProgressBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.f2f2,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: CircleProgressBar(
              valueNotifier: valueNotifier,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () async {
                getPhotos();
                // final number = await PhotoManagerTool.getPhotoCount();
                // PhotoManagerTool.fetchPhoto(1);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColor.textPrimary, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: Text(
                  AppUtils.i18Translate('home.smartClear'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColor.textPrimary,
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
