import 'dart:async';
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
import 'package:photo_manager/photo_manager.dart';

class SameImagePage extends StatefulWidget {
  const SameImagePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SameImagePageState createState() => _SameImagePageState();
}

class _SameImagePageState extends State<SameImagePage> {
  List<SamePhotoGroup> samePhotos = [];
  List<ImageAsset> selPhotos = [];
  bool isAllSel = false;
  bool isScrolling = false;
  int totalSize = 0;
  Map<String, Uint8List?> thumbnailBytesMap = {};

  /// 最多缓存100张
  int maxCacheCount = 100;

  @override
  void initState() {
    super.initState();
    samePhotos = [...PhotoManagerTool.sameImageEntity];
    totalSize = PhotoManagerTool.samePhotoSize;
    assetSortForGroups();
    allSelectedPhotos(true);
  }

  /// 分组内图片按照大小排序
  void assetSortForGroups() {
    for (var group in samePhotos) {
      group.assets.sort((asset1, asset2) {
        if (asset1.length > asset2.length) {
          return -1;
        } else if (asset1.length < asset2.length) {
          return 1;
        } else {
          return 0;
        }
      });
    }
  }

  allSelectedPhotos(bool isAll) {
    isAllSel = isAll;
    selPhotos = [];
    if (isAllSel) {
      for (var group in samePhotos) {
        for (var asset in group.assets) {
          if (group.assets.indexOf(asset) != 0) {
            asset.selected = true;
            selPhotos.add(asset);
          }
        }
      }
    } else {
      for (var group in samePhotos) {
        for (var asset in group.assets) {
          if (group.assets.indexOf(asset) != 0) {
            asset.selected = false;
          } else {
            if (asset.selected) asset.selected = false;
          }
        }
      }
    }
    if (context.mounted) {
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
                  samePhotos.isNotEmpty
                      ? '${AppUtils.i18Translate('home.samePhoto', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})'
                      : AppUtils.i18Translate('home.samePhoto',
                          context: context),
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Visibility(
                  visible: samePhotos.isNotEmpty,
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
      body: samePhotos.isEmpty
          ? Center(
              child: EmptyWidget(
                title: AppUtils.i18Translate(
                  'common.noFilesClean',
                  context: context,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NotificationListener(
                    onNotification: (Notification notification) {
                      if (notification is ScrollStartNotification) {
                        isScrolling = true;
                      } else if (notification is ScrollEndNotification) {
                        isScrolling = false;
                        setState(() {});
                      }
                      return true;
                    },
                    child: _buildGroupList(context, imgW),
                  ),
                ),
                _buildDelButton(context),
              ],
            ),
    );
  }

  Widget _buildGroupList(BuildContext context, double imgW) {
    return CustomScrollView(
      slivers: [
        SliverList.builder(
            itemCount: samePhotos.length,
            itemBuilder: (context, index) {
              final section = index;
              return Column(
                children: [
                  samePhotos[section].assets.isEmpty
                      ? const SizedBox()
                      : _buildSection(section, context),
                  GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: samePhotos[section].assets.length,
                    itemBuilder: (context, index) {
                      return _buildItem(section, index, imgW);
                    },
                  )
                ],
              );
            })
      ],
    );
  }

  Widget _buildSection(int section, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      alignment: Alignment.centerLeft,
      child: samePhotos[section].totalSize > 0
          ? Text(
              '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)},${AppUtils.fileSizeFormat(samePhotos[section].totalSize)}',
              style: const TextStyle(
                color: AppColor.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            )
          : isScrolling
              ? Text(
                  '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)},',
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : FutureBuilder(
                  future: _loadGroupImageSize(samePhotos[section]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Text(
                        '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)},${snapshot.data}',
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else {
                      return Row(
                        children: [
                          Text(
                            '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)}',
                            style: const TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const CupertinoActivityIndicator(radius: 4),
                          Text(
                            '${AppUtils.i18Translate('homde.caculateSize', context: context)}...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.subTitle999,
                            ),
                          )
                        ],
                      );
                    }
                  },
                ),
    );
  }

  _buildItem(int section, int index, double imgW) {
    final assets = samePhotos[section].assets[index];
    return GestureDetector(
      onTap: () {
        AppUtils.showImagePreviewDialog(
            AppUtils.globalContext!, samePhotos[section].assets, index);
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: thumbnailBytesMap[assets.assetEntity.id] != null
                ? ExtendedImage.memory(
                    thumbnailBytesMap[assets.assetEntity.id]!,
                    fit: BoxFit.cover,
                    clearMemoryCacheIfFailed: true,
                    clearMemoryCacheWhenDispose: true,
                    width: imgW,
                    height: imgW,
                  )
                : isScrolling
                    ? ExtendedImage.asset(
                        'assets/images/common/placeholder.png',
                        fit: BoxFit.cover,
                        width: imgW,
                        height: imgW,
                      )
                    : FutureBuilder(
                        future: _loadImage(
                            assets, (imgW * 4).toInt(), (imgW * 4).toInt()),
                        builder: (context, snapshot) {
                          if (snapshot.data != null) {
                            return ExtendedImage.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: imgW,
                              height: imgW,
                              clearMemoryCacheIfFailed: true,
                              clearMemoryCacheWhenDispose: true,
                              loadStateChanged: (state) {
                                if (state.extendedImageLoadState ==
                                    LoadState.loading) {
                                  return Image.asset(
                                    'assets/images/common/placeholder.png',
                                    fit: BoxFit.cover,
                                    width: imgW,
                                    height: imgW,
                                  );
                                }
                                return null;
                              },
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
            left: 0,
            top: 0,
            child: Visibility(
              visible: index == 0,
              child: FittedBox(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColor.mainColor,
                  ),
                  width: 36,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    AppUtils.i18Translate('common.bestImage', context: context),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  assets.selected
                      ? 'assets/images/common/selected_sel.png'
                      : 'assets/images/common/selected_normal.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.all(
                  Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: assets.length == 0
                  ? FutureBuilder(
                      future: _loadImageSize(assets),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.connectionState == ConnectionState.done
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
                      AppUtils.fileSizeFormat(assets.length),
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
  }

  Padding _buildDelButton(BuildContext context) {
    return Padding(
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
          PermissionState state1 = await PhotoManager.requestPermissionExtend();
          if (state1.isAuth) {
            List<String> deleIds = [];
            for (var asset in selPhotos) {
              deleIds.add(asset.assetEntity.id);
            }
            try {
              final result = await PhotoManager.editor.deleteWithIds(deleIds);
              if (result.length == deleIds.length) {
                List<SamePhotoGroup> delGroup = [];
                int deleteTotalSize = 0;
                for (var group in samePhotos) {
                  List<ImageAsset> newAsset = [];
                  for (var asset in group.assets) {
                    if (!deleIds.contains(asset.assetEntity.id)) {
                      newAsset.add(asset);
                    } else {
                      selPhotos.remove(asset);
                      deleteTotalSize += asset.length;
                    }
                  }
                  if (group.assets.isNotEmpty) {
                    group.assets = newAsset;
                  } else {
                    delGroup.add(group);
                  }
                }
                for (var delGroup in delGroup) {
                  samePhotos.remove(delGroup);
                }
                setState(() {});
                globalStreamControler
                    .add(SamePhotoDeleteEvent(deleIds, deleteTotalSize));
                // ignore: use_build_context_synchronously
                ToastUtil.showSuccessInfo(
                    AppUtils.i18Translate('home.deleteOK', context: context));
              }
            } catch (e) {
              // ignore: use_build_context_synchronously
              ToastUtil.showSuccessInfo(
                  AppUtils.i18Translate('home.deleteErr', context: context));
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
    );
  }

  Future<Uint8List?> _loadImage(ImageAsset asset, int imgW, int imgH) async {
    if (thumbnailBytesMap[asset.assetEntity.id] != null) {
      return thumbnailBytesMap[asset.assetEntity.id];
    } else {
      if (thumbnailBytesMap.length >= samePhotoCachesCount) {
        int countToRemove = (samePhotoCachesCount * 0.5).toInt();
        List<String> keys = thumbnailBytesMap.keys.toList();
        for (int i = 0; i < countToRemove && i < keys.length; i++) {
          thumbnailBytesMap.remove(keys[i]);
        }
      }
      final thumbnailData = await asset.assetEntity
          .thumbnailDataWithSize(ThumbnailSize(imgW, imgH));
      if (thumbnailData != null) {
        thumbnailBytesMap[asset.assetEntity.id] = thumbnailData;
        return thumbnailData;
      } else {
        return null;
      }
    }
  }

  Future<String?> _loadGroupImageSize(SamePhotoGroup group) async {
    int totalSize = 0;
    if (group.totalSize > 0) {
      return AppUtils.fileSizeFormat(group.totalSize);
    } else {
      for (var asset in group.assets) {
        final orignalFile = await asset.assetEntity.originFile;
        if (orignalFile != null) {
          final length = await orignalFile.length();
          asset.length = length;
          asset.originalFilePath = orignalFile.path;
          totalSize += length;
        }
      }
      group.totalSize = totalSize;
      return AppUtils.fileSizeFormat(totalSize);
    }
  }

  Future<String?> _loadImageSize(ImageAsset asset) async {
    if (asset.length > 0) {
      return AppUtils.fileSizeFormat(asset.length);
    } else {
      final orignalFile = await asset.assetEntity.originFile;
      if (orignalFile != null) {
        final length = await orignalFile.length();
        asset.length = length;
        asset.originalFilePath = orignalFile.path;
        return AppUtils.fileSizeFormat(length);
      } else {
        return '0B';
      }
    }
  }
}
