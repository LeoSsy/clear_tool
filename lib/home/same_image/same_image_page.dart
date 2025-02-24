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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:group_grid_view/group_grid_view.dart';
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
  StreamSubscription? streamSubscription;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    samePhotos = [...PhotoManagerTool.sameImageEntity];
    assetSortForGroups();
    allSelectedPhotos(true);
    streamSubscription = globalStreamControler.stream.listen((event) {
      if (event is SamePhotoEvent) {
        if (mounted && !isScrolling) {
          setState(() {
            for (var newAsset in PhotoManagerTool.sameImageEntity) {
              final findCaches = samePhotos
                  .where((oldAsset) => oldAsset.id == newAsset.id)
                  .toList();
              if (findCaches.isEmpty) {
                samePhotos.add(newAsset);
              }
            }
            assetSortForGroups();
            allSelectedPhotos(true);
          });
        }
      } else if (event is RefreshEvent) {
        setState(() {});
      }
    });
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
    return Scaffold(
      appBar: AppBar(
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
        centerTitle: true,
        title: Text(
          samePhotos.isNotEmpty
              ? '${AppUtils.i18Translate('home.samePhoto', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})'
              : AppUtils.i18Translate('home.samePhoto', context: context),
          style: const TextStyle(
              fontSize: 17,
              color: AppColor.textPrimary,
              fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton(
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
              ))
        ],
      ),
      body: samePhotos.isEmpty
          ? const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    color: AppColor.mainColor,
                    radius: 10,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '检测中，请稍等...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColor.textPrimary,
                    ),
                  )
                ],
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
                    child: GroupGridView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 7,
                        crossAxisSpacing: 7,
                      ),
                      sectionCount: samePhotos.length,
                      headerForSection: (section) => samePhotos[section]
                              .assets
                              .isEmpty
                          ? const SizedBox()
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: samePhotos[section].totalSize > 0
                                  ? Text(
                                      '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)},${AppUtils.fileSizeFormat(samePhotos[section].totalSize)}',
                                      style: const TextStyle(
                                        color: AppColor.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : FutureBuilder(
                                      future: _loadGroupImageSize(
                                          samePhotos[section]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          return Text(
                                            '${samePhotos[section].assets.length} ${AppUtils.i18Translate('home.aImage', context: context)},${snapshot.data}',
                                            style: const TextStyle(
                                              color: AppColor.textPrimary,
                                              fontSize: 12,
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
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const CupertinoActivityIndicator(
                                                  radius: 4),
                                              Text(
                                                '${AppUtils.i18Translate('homde.caculateSize', context: context)}...',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: AppColor.subTitle999,
                                                ),
                                              )
                                            ],
                                          );
                                        }
                                      }),
                            ),
                      itemInSectionBuilder: (_, indexPath) {
                        final assets = samePhotos[indexPath.section]
                            .assets[indexPath.index];
                        return GestureDetector(
                          onTap: () {
                            AppUtils.showImagePreviewDialog(
                                AppUtils.globalContext!,
                                samePhotos[indexPath.section].assets,
                                indexPath.index);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: assets.thumnailBytes != null
                                    ? Image.memory(
                                        assets.thumnailBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : FutureBuilder(
                                        future: _loadImage(assets),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            return snapshot.data != null
                                                ? Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.asset(
                                                    'assets/images/common/placeholder.png',
                                                    fit: BoxFit.cover,
                                                  );
                                          } else {
                                            return Image.asset(
                                              'assets/images/common/placeholder.png',
                                              fit: BoxFit.cover,
                                            );
                                          }
                                        },
                                      ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Visibility(
                                  visible: indexPath.index == 0,
                                  child: FittedBox(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: AppColor.mainColor,
                                      ),
                                      width: 24,
                                      height: 13,
                                      alignment: Alignment.center,
                                      child: Text(
                                        AppUtils.i18Translate(
                                            'common.bestImage',
                                            context: context),
                                        style: const TextStyle(
                                          fontSize: 9,
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
                                right: 0,
                                bottom: 0,
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
                      itemInSectionCount: (section) =>
                          samePhotos[section].assets.length,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: AppUtils.safeAreapadding.bottom + 12),
                  child: GestureDetector(
                    onTap: () async {
                      if (selPhotos.isEmpty) {
                        ToastUtil.showFailMsg(AppUtils.i18Translate(
                            'home.selImg',
                            context: context));
                        return;
                      }
                      PermissionState state1 =
                          await PhotoManager.requestPermissionExtend();
                      if (state1.isAuth) {
                        List<String> deleIds = [];
                        for (var asset in selPhotos) {
                          deleIds.add(asset.assetEntity.id);
                        }
                        try {
                          final result =
                              await PhotoManager.editor.deleteWithIds(deleIds);
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
                            globalStreamControler.add(
                                SamePhotoDeleteEvent(deleIds, deleteTotalSize));
                            // ignore: use_build_context_synchronously
                            ToastUtil.showSuccessInfo(AppUtils.i18Translate(
                                'home.deleteOK',
                                context: context));
                          }
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ToastUtil.showSuccessInfo(AppUtils.i18Translate(
                              'home.deleteErr',
                              context: context));
                        }
                      } else {
                        final res = await AppDialog.showConfirmDialog(
                          AppUtils.globalContext!,
                          desc: AppUtils.i18Translate(
                              'home.deniedPhotoPermission'),
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
              ],
            ),
    );
  }

  Future<Uint8List?> _loadImage(ImageAsset asset) async {
    final thumbnailData = await asset.assetEntity.thumbnailData;
    if (thumbnailData != null) {
      asset.thumnailBytes = thumbnailData;
      return thumbnailData;
    } else {
      return null;
    }
  }

  Future<String?> _loadGroupImageSize(SamePhotoGroup group) async {
    int totalSize = 0;
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

  Future<String?> _loadImageSize(ImageAsset asset) async {
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
