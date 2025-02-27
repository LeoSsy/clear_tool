import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:app_settings/app_settings.dart';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/dialog/dialog.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/permission_utils.dart';
import 'package:clear_tool/utils/toast_utils.dart';
import 'package:clear_tool/widget/empty_widget.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';

class ScreenShotPage extends StatefulWidget {
  const ScreenShotPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ScreenShotPageState createState() => _ScreenShotPageState();
}

class _ScreenShotPageState extends State<ScreenShotPage> {
  List<ImageAsset> screenshots = [];
  List<ImageAsset> selPhotos = [];
  bool isAllSel = false;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    screenshots = PhotoManagerTool.screenShotImageEntity;
  }

  allSelectedPhotos(bool isAllSel) {
    if (isAllSel) {
      selPhotos = screenshots.map((e) {
        e.selected = true;
        return e;
      }).toList();
    } else {
      screenshots.map((e) {
        e.selected = false;
        return e;
      }).toList();
      selPhotos = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    allSelectedPhotos(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0, 50),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Image.asset(
                      'assets/images/common/back.png',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    screenshots.isNotEmpty
                        ? '${AppUtils.i18Translate('home.screenshot', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})'
                        : AppUtils.i18Translate('home.screenshot',
                            context: context),
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColor.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Visibility(
                  visible: screenshots.isNotEmpty,
                  child: TextButton(
                      onPressed: () {
                        isAllSel = !isAllSel;
                        allSelectedPhotos(isAllSel);
                      },
                      child: Text(
                        isAllSel
                            ? AppUtils.i18Translate('home.unSelectedAll',
                                context: context)
                            : AppUtils.i18Translate('home.selectedAll',
                                context: context),
                        style: TextStyle(
                          fontSize: 14.autoSize,
                          color: AppColor.mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: screenshots.isEmpty
                ? Center(
                    child: EmptyWidget(
                      title: AppUtils.i18Translate('common.noFilesClean',
                          context: context),
                    ),
                  )
                : NotificationListener(
                    onNotification: (Notification notification) {
                      if (notification is ScrollStartNotification) {
                        isScrolling = true;
                      } else if (notification is ScrollEndNotification) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          isScrolling = false;
                          setState(() {});
                        });
                      }
                      return true;
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                            ),
                            itemCount: screenshots.length,
                            itemBuilder: (context, index) {
                              final assets = screenshots[index];
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  // 截取前后100张图片
                                  // final id = assets.assetEntity.id;
                                  // final start = max(index - 100, 0);
                                  // final end =
                                  //     min(index + 100, screenshots.length);
                                  // final tempList =
                                  //     screenshots.sublist(start, end);
                                  // var preIndex = 0;
                                  // for (var i = 0; i < tempList.length; i++) {
                                  //   if (tempList[i].assetEntity.id == id) {
                                  //     preIndex = i;
                                  //     break;
                                  //   }
                                  // }
                                  AppUtils.showImagePreviewDialog(
                                    context,
                                    screenshots,
                                    index,
                                  );
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: assets.thumnailBytes != null
                                          ? ExtendedImage.memory(
                                              assets.thumnailBytes!,
                                              fit: BoxFit.cover,
                                              width: imgW,
                                              height: imgW,
                                            )
                                          : FutureBuilder(
                                              future: _loadImage(
                                                  assets,
                                                  imgW.toInt() * 5,
                                                  imgW.toInt() * 5),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.done) {
                                                  return snapshot.data != null
                                                      ? ExtendedImage.memory(
                                                          assets.thumnailBytes!,
                                                          fit: BoxFit.cover,
                                                          width: imgW,
                                                          height: imgW,
                                                        )
                                                      : Image.asset(
                                                          'assets/images/common/placeholder.png',
                                                          fit: BoxFit.cover,
                                                          width: imgW,
                                                          height: imgW,
                                                        );
                                                } else {
                                                  return Image.asset(
                                                    'assets/images/common/placeholder.png',
                                                    fit: BoxFit.cover,
                                                    width: imgW,
                                                    height: imgW,
                                                  );
                                                }
                                              },
                                            ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            assets.selected = !assets.selected;
                                            if (assets.selected) {
                                              selPhotos.add(assets);
                                            } else {
                                              selPhotos.remove(assets);
                                            }
                                          });
                                        },
                                        child: Image.asset(
                                          assets.selected
                                              ? 'assets/images/common/selected_sel.png'
                                              : 'assets/images/common/selected_normal.png',
                                              width: 30,
                                              height: 30,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3, vertical: 2),
                                        child: assets.length > 0
                                            ? Text(
                                                AppUtils.fileSizeFormat(
                                                    assets.length),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : FutureBuilder(
                                                future: _loadImageSize(assets),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.connectionState ==
                                                            ConnectionState.done
                                                        ? '${snapshot.data}'
                                                        : '0KB',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: AppUtils.safeAreapadding.bottom + 12,
            ),
            child: Visibility(
              visible: screenshots.isNotEmpty,
              child: GestureDetector(
                onTap: () async {
                  if (selPhotos.isEmpty) {
                    ToastUtil.showFailMsg(
                        AppUtils.i18Translate('home.selImg', context: context));
                    return;
                  }
                  final state = await PermissionUtils.checkPhotosPermisson();
                  if (state) {
                    final deleList = await PhotoManager.editor.deleteWithIds(
                        selPhotos.map((e) => e.assetEntity.id).toList());
                    if (deleList.isNotEmpty) {
                      int totalDelSize = 0;
                      setState(() {
                        for (var asset in selPhotos) {
                          totalDelSize += asset.length;
                          PhotoManagerTool.screenShotImageEntity.removeWhere(
                              (el) =>
                                  el.assetEntity.id == asset.assetEntity.id);
                          screenshots.removeWhere((el) =>
                              el.assetEntity.id == asset.assetEntity.id);
                        }
                      });
                      ToastUtil.showSuccessInfo(
                          AppUtils.i18Translate('home.deleteOK'));
                      // 发送删除事件
                      globalStreamControler
                          .add(ScreenPhotoDeleteEvent(deleList, totalDelSize));
                    }
                  } else {
                    final res = await AppDialog.showConfirmDialog(
                      AppUtils.globalContext!,
                      desc: AppUtils.i18Translate('home.deniedPhotoPermission'),
                    );
                    if (res) {
                      AppSettings.openAppSettings();
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColor.mainColor,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    '${AppUtils.i18Translate('home.delete', context: context)} ${selPhotos.length} ${AppUtils.i18Translate('home.aImage', context: context)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadImage(ImageAsset asset, int imgW, int imgH) async {
    final thumbnailData = await asset.assetEntity
        .thumbnailDataWithSize(ThumbnailSize(imgW, imgH));
    if (thumbnailData != null) {
      asset.thumnailBytes = thumbnailData;
      return thumbnailData;
    } else {
      return null;
    }
  }

  Future<String?> _loadImageSize(ImageAsset asset) async {
    final originFile = await asset.assetEntity.originFile;
    if (originFile != null) {
      asset.length = await originFile.length();
      return AppUtils.fileSizeFormat(asset.length);
    } else {
      return '0KB';
    }
  }
}
