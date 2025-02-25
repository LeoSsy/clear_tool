import 'dart:async';
import 'dart:convert';
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
import 'package:clear_tool/utils/toast_utils.dart';
import 'package:clear_tool/widget/empty_widget.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mmkv/mmkv.dart';
import 'package:photo_manager/photo_manager.dart';

class BigImagePage extends StatefulWidget {
  const BigImagePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BigImagePageState createState() => _BigImagePageState();
}

class _BigImagePageState extends State<BigImagePage> {
  List<ImageAsset> bigPhotos = [];
  List<ImageAsset> selPhotos = [];
  bool isAllSel = false;
  bool isScrolling = false;

  int totalSize = 0;

  @override
  void initState() {
    super.initState();
    bigPhotos = [...PhotoManagerTool.bigImageEntity];
    totalSize = PhotoManagerTool.bigSumSize;
  }

  allSelectedPhotos(bool isAllSel) {
    if (isAllSel) {
      selPhotos = bigPhotos.map((e) {
        e.selected = true;
        return e;
      }).toList();
    } else {
      bigPhotos.map((e) {
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
                Text(
                  bigPhotos.isNotEmpty
                      ? '${AppUtils.i18Translate('home.oversizedImage', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})'
                      : AppUtils.i18Translate('home.oversizedImage',
                          context: context),
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Visibility(
                  visible: bigPhotos.isNotEmpty,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: bigPhotos.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                '${bigPhotos.length} ${AppUtils.i18Translate('home.aImage', context: context)},${AppUtils.fileSizeFormat(totalSize)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: bigPhotos.isEmpty
                ? Center(
                    child: EmptyWidget(
                      title: AppUtils.i18Translate(
                        'common.noFilesClean',
                        context: context,
                      ),
                    ),
                  )
                : NotificationListener(
                    onNotification: (Notification notification) {
                      if (notification is ScrollStartNotification) {
                        isScrolling = true;
                      } else if (notification is ScrollEndNotification) {
                        isScrolling = false;
                        setState(() {});
                      }
                      return true;
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                            ),
                            itemCount: bigPhotos.length,
                            itemBuilder: (context, index) {
                              final assets = bigPhotos[index];
                              return GestureDetector(
                                onTap: () async {
                                  AppUtils.showImagePreviewDialog(
                                    context,
                                    bigPhotos,
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
                                        child: assets.length == 0
                                            ? FutureBuilder(
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
                                              )
                                            : Text(
                                                AppUtils.fileSizeFormat(
                                                    assets.length),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Visibility(
            visible: bigPhotos.isNotEmpty,
            child: Padding(
              padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: AppUtils.safeAreapadding.bottom + 12),
              child: GestureDetector(
                onTap: () async {
                  if (selPhotos.isEmpty) {
                    ToastUtil.showFailMsg(
                        AppUtils.i18Translate('home.selImg', context: context));
                    return;
                  }
                  PermissionState state1 =
                      await PhotoManager.requestPermissionExtend();
                  if (state1.hasAccess) {
                    List<String> deleIds = [];
                    int delTotalSize = 0;
                    for (var asset in selPhotos) {
                      final file = await asset.assetEntity.file;
                      delTotalSize += asset.length;
                      if (file != null) {
                        final fileName = file.uri.pathSegments.last;
                        try {
                          final cmpFileBytes =
                              await FlutterImageCompress.compressWithFile(
                            file.path,
                            quality: 80,
                          );
                          if (cmpFileBytes != null) {
                            await PhotoManager.editor.saveImage(
                              cmpFileBytes,
                              filename:
                                  '${fileName.split('.').first}_cmps.${fileName.split('.').last}',
                              orientation: asset.assetEntity.orientation,
                              relativePath: asset.assetEntity.relativePath,
                              title: asset.assetEntity.title,
                            );
                            deleIds.add(asset.assetEntity.id);
                          }
                        } catch (e) {
                          print('err--$e');
                        }
                      }
                    }
                    try {
                      final mmkv = MMKV.defaultMMKV();
                      final cache = mmkv.decodeString(imageCompressedCacheKey);
                      await PhotoManager.editor.deleteWithIds(deleIds);
                      List<String> needZipList = [];
                      // 通知界面刷新重新加载数据
                      for (var id in deleIds) {
                        PhotoManagerTool.bigImageEntity
                            .removeWhere((el) => el.assetEntity.id == id);
                        bigPhotos.removeWhere((el) => el.assetEntity.id == id);
                        if (cache != null) {
                          final cacheList = jsonDecode(cache);
                          if (!cacheList.contains(id)) {
                            needZipList.add(id);
                          }
                        } else {
                          needZipList.add(id);
                        }
                      }
                      // 缓存已压缩图
                      if (needZipList.isNotEmpty) {
                        if (cache != null) {
                          final cacheList = jsonDecode(cache);
                          cacheList.addAll(needZipList);
                          final jsonData = jsonEncode(cacheList);
                          mmkv.encodeString(imageCompressedCacheKey, jsonData);
                        }
                      }
                      ToastUtil.showSuccessInfo(
                          AppUtils.i18Translate('home.zipOk'));
                      // 发送删除事件
                      globalStreamControler
                          .add(BigPhotoDeleteEvent(deleIds, delTotalSize));
                      setState(() {});
                    } catch (e) {
                      ToastUtil.showSuccessInfo(
                          AppUtils.i18Translate('home.zipErr'));
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
                    '${AppUtils.i18Translate('home.zip', context: context)} ${selPhotos.length} ${AppUtils.i18Translate('home.aImage', context: context)}',
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
    final orignalFile = await asset.assetEntity.originFile;
    if (orignalFile != null) {
      final length = await orignalFile.length();
      asset.length = length;
      asset.originalFilePath = orignalFile.path;
      return AppUtils.fileSizeFormat(length);
    } else {
      return '0KB';
    }
  }
}
