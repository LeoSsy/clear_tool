import 'dart:async';
import 'dart:io';

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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  StreamSubscription? streamSubscription;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    screenshots = PhotoManagerTool.screenShotImageEntity;
    streamSubscription = globalStreamControler.stream.listen((event) {
      if (event is ScreenPhotoEvent) {
        if (mounted && !isScrolling) {
          setState(() {
            for (var newAsset in PhotoManagerTool.screenShotImageEntity) {
              final findCaches = screenshots
                  .where((oldAsset) =>
                      oldAsset.assetEntity.id == newAsset.assetEntity.id)
                  .toList();
              if (findCaches.isEmpty) {
                screenshots.add(newAsset);
              }
            }
          });
        }
      } else if (event is RefreshEvent) {
        if (mounted) setState(() {});
      }
    });
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
    streamSubscription?.cancel();
    allSelectedPhotos(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
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
        title: Text(
          screenshots.isNotEmpty
              ? '${AppUtils.i18Translate('home.screenshot', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})'
              : AppUtils.i18Translate('home.screenshot', context: context),
          style: const TextStyle(
            fontSize: 15,
            color: AppColor.textPrimary,
          ),
        ),
        elevation: 0,
        actions: [
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
                    fontSize: 11.autoSize,
                    color: AppColor.mainColor,
                  ),
                )),
          )
        ],
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
                                onTap: () {
                                  AppUtils.showImagePreviewDialog(
                                      context,
                                      screenshots
                                          .map((e) => e.originalFilePath!)
                                          .toList(),
                                      index);
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: assets.thumnailBytes != null
                                          ? Image.memory(
                                              assets.thumnailBytes!,
                                              width: imgW,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/common/placeholder.png',
                                              width: imgW,
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Image.asset(
                                            assets.selected
                                                ? 'assets/images/common/selected_sel.png'
                                                : 'assets/images/common/selected_normal.png',
                                          ),
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
                    borderRadius: BorderRadius.circular(4),
                    color: AppColor.mainColor,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Text(
                    '${AppUtils.i18Translate('home.delete', context: context)} ${selPhotos.length} ${AppUtils.i18Translate('home.aImage', context: context)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
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
