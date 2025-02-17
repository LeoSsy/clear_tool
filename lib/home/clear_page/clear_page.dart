import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/big_image/big_image_page.dart';
import 'package:clear_tool/home/same_image/same_image_page.dart';
import 'package:clear_tool/home/screen_shot/screen_shot_page.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/state/app_state.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class ClearPage extends HookWidget {
  const ClearPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  height: 54.autoSize,
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 11),
                      Text(
                        PhotoManagerTool.progress < 98
                            ? '${AppUtils.i18Translate('home.recognition', context: context)}...'
                            : AppUtils.i18Translate('home.recognitionOK',
                                context: context),
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
                                child: SizedBox(
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: (PhotoManagerTool.progress >= 98 ? 100 : PhotoManagerTool.progress) / 100,
                                    color: AppColor.mainColor,
                                    backgroundColor: AppColor.D7D7D7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${PhotoManagerTool.progress >= 98 ? 100 : PhotoManagerTool.progress.toStringAsFixed(0)}%',
                              style: const TextStyle(
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
                          Text(
                            '（${appState.samePhotos?.length ?? 0} ${AppUtils.i18Translate('home.aImage', context: context)}, ${AppUtils.fileSizeFormat(appState.samePhotoSize)}）',
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: appState.samePhotos == null
                              ? [
                                  const CupertinoActivityIndicator(
                                    color: AppColor.mainColor,
                                    radius: 16,
                                  )
                                ]
                              : [
                                  Expanded(
                                    child: appState.samePhotos!.isEmpty
                                        ? ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: 3,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: Image.asset(
                                                    'assets/images/common/placeholder.png',
                                                    fit: BoxFit.cover,
                                                    width: 70.autoSize,
                                                    height: 70.autoSize,
                                                  ),
                                                ),
                                              );
                                            })
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount:
                                                appState.samePhotos!.length > 3
                                                    ? 3
                                                    : appState
                                                        .samePhotos!.length,
                                            itemBuilder: (context, index) {
                                              final asset =
                                                  appState.samePhotos![index];
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: asset.thumnailBytes !=
                                                          null
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
                                                const SameImagePage()),
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
                            AppUtils.i18Translate('home.bigPhoto',
                                context: context),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '（${appState.bigPhotos?.length ?? 0} ${AppUtils.i18Translate('home.aImage', context: context)}, ${AppUtils.fileSizeFormat(appState.bigPhotoSize)}）',
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: appState.bigPhotos == null
                              ? [
                                  const CupertinoActivityIndicator(
                                    color: AppColor.mainColor,
                                    radius: 16,
                                  )
                                ]
                              : [
                                  Expanded(
                                    child: appState.bigPhotos!.isEmpty
                                        ? ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: 3,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: Image.asset(
                                                    'assets/images/common/placeholder.png',
                                                    fit: BoxFit.cover,
                                                    width: 70.autoSize,
                                                    height: 70.autoSize,
                                                  ),
                                                ),
                                              );
                                            })
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount:
                                                appState.bigPhotos!.length > 3
                                                    ? 3
                                                    : appState
                                                        .bigPhotos!.length,
                                            itemBuilder: (context, index) {
                                              final asset =
                                                  appState.bigPhotos![index];
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: asset.thumnailBytes !=
                                                          null
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
                            '（${appState.screenPhotos?.length ?? 0} ${AppUtils.i18Translate('home.aImage', context: context)}, ${AppUtils.fileSizeFormat(appState.screenPhotoSize)}）',
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: appState.screenPhotos == null
                              ? [
                                  const CupertinoActivityIndicator(
                                    color: AppColor.mainColor,
                                    radius: 16,
                                  )
                                ]
                              : [
                                  Expanded(
                                    child: appState.screenPhotos!.isEmpty
                                        ? ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: 3,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: Image.asset(
                                                    'assets/images/common/placeholder.png',
                                                    fit: BoxFit.cover,
                                                    width: 70.autoSize,
                                                    height: 70.autoSize,
                                                  ),
                                                ),
                                              );
                                            })
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: appState
                                                        .screenPhotos!.length >
                                                    3
                                                ? 3
                                                : appState.screenPhotos!.length,
                                            itemBuilder: (context, index) {
                                              final asset =
                                                  appState.screenPhotos![index];
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 5),
                                                  child: asset.thumnailBytes !=
                                                          null
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
