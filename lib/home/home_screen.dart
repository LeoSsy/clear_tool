import 'dart:math';
import 'package:circle_progress_bar/circle_progress_bar.dart' as cp;
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/big_image/big_image_page.dart';
import 'package:clear_tool/home/clear_page/clear_page.dart';
import 'package:clear_tool/home/same_image/same_image_page.dart';
import 'package:clear_tool/home/screen_shot/screen_shot_page.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/state/app_state.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key});
  // void changeLanguage() async {
  //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
  //     final currentLang = FlutterI18n.currentLocale(context)!;
  //     final nextLang = currentLang.languageCode == 'zh'
  //         ? const Locale('zh')
  //         : const Locale('en');
  //     await FlutterI18n.refresh(context, nextLang);
  //     setState(() {});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    useListenable(appState);
    AppUtils.globalContext = context;
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverList.list(
            children: [
              _buildCircleProgressBar(context),
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
        ],
      ),
    );
  }

  Widget _buidManualItem(BuildContext context) {
    final appState = Provider.of<AppState>(context);
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
                                '${appState.sameCount()}${AppUtils.i18Translate('home.sheet', context: context)}',
                                style: TextStyle(
                                  fontSize: 8.autoSize,
                                  color: const Color(0xff5E1FB2),
                                ),
                              ),
                              Text(
                                appState.samePhotoSize > 0
                                    ? AppUtils.fileSizeFormat(appState.samePhotoSize)
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
                                appState.bigPhotoSize > 0 ? AppUtils.fileSizeFormat(appState.bigPhotoSize) : '0KB',
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
                                '${appState.screenPhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}',
                                style: TextStyle(
                                  fontSize: 8.autoSize!,
                                  color: const Color(0xff1B5FC4),
                                ),
                              ),
                              Text(
                                appState.screenPhotoSize > 0
                                    ? AppUtils.fileSizeFormat(appState.screenPhotoSize)
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

  Container _buildCircleProgressBar(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final circleSize = 250.autoSize!;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 12,
        right: 12,
      ),
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
            '${appState.deviceName}${AppUtils.i18Translate("home.diskSpace")}',
            style: const TextStyle(
              fontSize: 17.5,
              color: AppColor.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                '${AppUtils.i18Translate("home.useSpace")}${appState.useSize},',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.textSecondary,
                ),
              ),
              Text(
                '${AppUtils.i18Translate("home.totalSpace")}${appState.totalSize}',
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
                    appState.progressBgImage,
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
                        foregroundColor: appState.color,
                        backgroundColor: Colors.white,
                        strokeWidth: 14,
                        value: appState.circleProgress / 100,
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
                              appState.circleProgress.toStringAsFixed(0),
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
