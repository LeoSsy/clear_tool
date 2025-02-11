import 'dart:async';
import 'dart:io';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/big_image/big_image_page.dart';
import 'package:clear_tool/home/screen_shot/screen_shot_page.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

class ClearPage extends StatefulWidget {
  const ClearPage({Key? key}) : super(key: key);

  @override
  _ClearPageState createState() => _ClearPageState();
}

class _ClearPageState extends State<ClearPage> {
  StreamSubscription? streamSubscription;
  List<ImageAsset> bigPhotos = [];
  List<ImageAsset> samePhotos = [];
  List<ImageAsset> screenshotPhotos = [];
  String? _bigPhotoSize;
  String? _samePhotoSize;
  String? _screenshotPhotoSize;
  @override
  void initState() {
    super.initState();
    bigPhotos = PhotoManagerTool.bigImageEntity;
    screenshotPhotos = PhotoManagerTool.screenShotImageEntity;
    _caculateBigPhotoFileSize();
    _caculateScreenshotPhotoFileSize();
    streamSubscription = globalStreamControler.stream.listen((event) {
      if (event is SubBigPhotoEvent) {
        if (mounted) {
          setState(() {
            var newAssets = <ImageAsset>[];
            for (var newAsset in event.assets) {
              final findCaches = bigPhotos
                  .where((oldAsset) =>
                      oldAsset.assetEntity.id == newAsset.assetEntity.id)
                  .toList();
              if (findCaches.isEmpty) {
                newAssets.add(newAsset);
              }
            }
            bigPhotos.addAll(newAssets);
            _bigPhotoSize = AppUtils.fileSizeFormat(event.totalSize);
          });
        }
      } else if (event is SubScreenPhotoEvent) {
        if (mounted) {
          setState(() {
            for (var newAsset in event.assets) {
              final findCaches = screenshotPhotos
                  .where((oldAsset) =>
                      oldAsset.assetEntity.id == newAsset.assetEntity.id)
                  .toList();
              if (findCaches.isEmpty) {
                screenshotPhotos.add(newAsset);
              }
            }
            _screenshotPhotoSize = AppUtils.fileSizeFormat(event.totalSize);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  /// 计算文件大小
  _caculateBigPhotoFileSize() async {
    if (bigPhotos.isEmpty) return;
    int bigPhotoSize = 0;
    for (var asset in bigPhotos) {
      if (asset.length == 0 && asset.originalFilePath != null) {
        int length = await File(asset.originalFilePath!).length();
        bigPhotoSize += length;
      } else {
        bigPhotoSize += asset.length;
      }
    }
    setState(() {
      _bigPhotoSize = AppUtils.fileSizeFormat(bigPhotoSize);
    });
  }

  _caculateScreenshotPhotoFileSize() async {
    int screenPhotoSize = 0;
    for (var asset in screenshotPhotos) {
      if (asset.length == 0 && asset.originalFilePath != null) {
        int length = await File(asset.originalFilePath!).length();
        screenPhotoSize += length;
      } else {
        screenPhotoSize += asset.length;
      }
    }
    setState(() {
      _screenshotPhotoSize = AppUtils.fileSizeFormat(screenPhotoSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Image.asset(
              'assets/images/common/back.png',
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          AppUtils.i18Translate('home.smartClear'),
          style: const TextStyle(fontSize: 15, color: AppColor.textPrimary),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            sliver: SliverList.list(
              children: [
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  height: 48.autoSize,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      Text(
                        '${AppUtils.i18Translate('home.recognition', context: context)}...',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: const SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: 10,
                                    color: AppColor.mainColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '10%',
                              style: TextStyle(
                                fontSize: 7,
                                color: AppColor.textPrimary,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  height: 119.autoSize,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Text(
                            AppUtils.i18Translate('home.samePhoto',
                                context: context),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '（6张图片, 1.234 MB）',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColor.subTitle999,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: 2,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: Image.asset(
                                          'assets/images/common/placeholder.png',
                                          fit: BoxFit.cover,
                                          width: 70.autoSize,
                                          height: 70.autoSize,
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: AppColor.mainColor,
                              ),
                              width: 75.autoSize,
                              height: 26.autoSize,
                              alignment: Alignment.center,
                              child: Text(
                                AppUtils.i18Translate('home.gotoClear'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  height: 119.autoSize,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Text(
                            AppUtils.i18Translate('home.bigPhoto',
                                context: context),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '（${bigPhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}${AppUtils.i18Translate('home.image', context: context)}, ${_bigPhotoSize ?? '0KB'}）',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColor.subTitle999,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: bigPhotos.length > 3
                                      ? 3
                                      : bigPhotos.length,
                                  itemBuilder: (context, index) {
                                    final asset = bigPhotos[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: asset.thumnailBytes != null
                                            ? Image.memory(
                                                asset.thumnailBytes!,
                                                fit: BoxFit.cover,
                                                width: 70.autoSize,
                                                height: 70.autoSize,
                                              )
                                            : Image.asset(
                                                'assets/images/common/placeholder.png',
                                                fit: BoxFit.cover,
                                                width: 70.autoSize,
                                                height: 70.autoSize,
                                              ),
                                      ),
                                    );
                                  }),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const BigImagePage()),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColor.mainColor,
                                ),
                                width: 75.autoSize,
                                height: 26.autoSize,
                                alignment: Alignment.center,
                                child: Text(
                                  AppUtils.i18Translate('home.gotoClear'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  height: 119.autoSize,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Text(
                            AppUtils.i18Translate('home.screenshot',
                                context: context),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '（${screenshotPhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}${AppUtils.i18Translate('home.image', context: context)}, ${_screenshotPhotoSize ?? '0KB'}）',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColor.subTitle999,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: screenshotPhotos.length > 3
                                      ? 3
                                      : screenshotPhotos.length,
                                  itemBuilder: (context, index) {
                                    final asset = screenshotPhotos[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: asset.thumnailBytes != null
                                            ? Image.memory(
                                                asset.thumnailBytes!,
                                                fit: BoxFit.cover,
                                                width: 70.autoSize,
                                                height: 70.autoSize,
                                              )
                                            : Image.asset(
                                                'assets/images/common/placeholder.png',
                                                fit: BoxFit.cover,
                                                width: 70.autoSize,
                                                height: 70.autoSize,
                                              ),
                                      ),
                                    );
                                  }),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ScreenShotPage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppColor.mainColor,
                                ),
                                width: 75.autoSize,
                                height: 26.autoSize,
                                alignment: Alignment.center,
                                child: Text(
                                  AppUtils.i18Translate('home.gotoClear'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
