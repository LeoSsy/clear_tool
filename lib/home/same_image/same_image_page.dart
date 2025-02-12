import 'dart:async';
import 'dart:io';
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
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:photo_manager/photo_manager.dart';

class SameImagePage extends StatefulWidget {
  const SameImagePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SameImagePageState createState() => _SameImagePageState();
}

class _SameImagePageState extends State<SameImagePage> {
  List<SamePhotoGroup> samePhotos = [];
  List<SamePhotoGroup> selPhotos = [];
  bool isAllSel = false;
  StreamSubscription? streamSubscription;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    samePhotos = PhotoManagerTool.sameImageEntity;
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
          });
        }
      } else if (event is RefreshEvent) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
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
          '${AppUtils.i18Translate('home.oversizedImage', context: context)} (${AppUtils.i18Translate('home.selected', context: context)}${selPhotos.length})',
          style: const TextStyle(fontSize: 15, color: AppColor.textPrimary),
        ),
        elevation: 0,
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  isAllSel = !isAllSel;
                  if (isAllSel) {
                    selPhotos = samePhotos.map((e) {
                      e.selected = true;
                      return e;
                    }).toList();
                  } else {
                    samePhotos.map((e) {
                      e.selected = false;
                      return e;
                    }).toList();
                    selPhotos = [];
                  }
                });
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(9),
            child: Text(
              '${samePhotos.length}${AppUtils.i18Translate('home.aImage', context: context)},${AppUtils.fileSizeFormat(PhotoManagerTool.bigSumSize)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColor.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
              child: CustomScrollView(
                slivers: [
                  SliverList.separated(
                    itemCount: samePhotos.length,
                    itemBuilder: (context, index) {
                      final groups = samePhotos[index];
                      return SizedBox(
                        height: 90,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: groups.assets.length,
                            itemBuilder: (context, index) {
                              final asset = groups.assets[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: FutureBuilder(
                                  future: _loadImage(asset),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return snapshot.data != null
                                          ? Image.memory(
                                              snapshot.data!,
                                              width: imgW,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/common/placeholder.png',
                                              fit: BoxFit.cover,
                                              width: imgW,
                                            );
                                    } else {
                                      return Image.asset(
                                        'assets/images/common/placeholder.png',
                                        fit: BoxFit.cover,
                                        width: imgW,
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Text(
                        '${samePhotos[index].assets.length}张图片',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                  // SliverPadding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 9),
                  //   sliver: SliverGrid.builder(
                  //     gridDelegate:
                  //         const SliverGridDelegateWithFixedCrossAxisCount(
                  //       crossAxisCount: 4,
                  //       mainAxisSpacing: 5,
                  //       crossAxisSpacing: 5,
                  //     ),
                  //     itemCount: samePhotos.first.assets.length,
                  //     itemBuilder: (context, index) {
                  //       final assets = samePhotos.first.assets[index];
                  //       return GestureDetector(
                  //         onTap: () {
                  //           // AppUtils.showImagePreviewDialog(
                  //           //     AppUtils.globalContext!,
                  //           //     samePhotos
                  //           //         .map((e) => e.originalFilePath!)
                  //           //         .toList(),
                  //           //     index);
                  //         },
                  //         child: Stack(
                  //           children: [
                  //             ClipRRect(
                  //               borderRadius: BorderRadius.circular(4),
                  //               child: assets.thumnailBytes != null
                  //                   ? Image.memory(
                  //                       assets.thumnailBytes!,
                  //                       width: imgW,
                  //                       fit: BoxFit.cover,
                  //                     )
                  //                   : FutureBuilder(
                  //                       future: _loadImage(assets),
                  //                       builder: (context, snapshot) {
                  //                         if (snapshot.connectionState ==
                  //                             ConnectionState.done) {
                  //                           return snapshot.data != null
                  //                               ? Image.memory(
                  //                                   snapshot.data!,
                  //                                   width: imgW,
                  //                                   fit: BoxFit.cover,
                  //                                 )
                  //                               : Image.asset(
                  //                                   'assets/images/common/placeholder.png',
                  //                                   fit: BoxFit.cover,
                  //                                   width: imgW,
                  //                                 );
                  //                         } else {
                  //                           return Image.asset(
                  //                             'assets/images/common/placeholder.png',
                  //                             fit: BoxFit.cover,
                  //                             width: imgW,
                  //                           );
                  //                         }
                  //                       },
                  //                     ),
                  //             ),
                  //             Positioned(
                  //               right: 0,
                  //               top: 0,
                  //               child: GestureDetector(
                  //                 onTap: () {
                  //                   // setState(() {
                  //                   //   assets.selected = !assets.selected;
                  //                   //   if (assets.selected) {
                  //                   //     selPhotos.add(assets);
                  //                   //   } else {
                  //                   //     selPhotos.remove(assets);
                  //                   //   }
                  //                   // });
                  //                 },
                  //                 child: Padding(
                  //                   padding: const EdgeInsets.all(5),
                  //                   child: Image.asset(
                  //                     assets.selected
                  //                         ? 'assets/images/common/selected_sel.png'
                  //                         : 'assets/images/common/selected_normal.png',
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //             Positioned(
                  //               right: 2,
                  //               bottom: 2,
                  //               child: Container(
                  //                 decoration: const BoxDecoration(
                  //                   color: Colors.black,
                  //                   borderRadius: BorderRadius.all(
                  //                     Radius.circular(4),
                  //                   ),
                  //                 ),
                  //                 padding: const EdgeInsets.symmetric(
                  //                     horizontal: 3, vertical: 2),
                  //                 child: assets.length == 0
                  //                     ? FutureBuilder(
                  //                         future: _loadImageSize(assets),
                  //                         builder: (context, snapshot) {
                  //                           return Text(
                  //                             snapshot.connectionState ==
                  //                                     ConnectionState.done
                  //                                 ? '${snapshot.data}'
                  //                                 : '0B',
                  //                             style: const TextStyle(
                  //                               fontSize: 9,
                  //                               color: Colors.white,
                  //                             ),
                  //                           );
                  //                         },
                  //                       )
                  //                     : Text(
                  //                         AppUtils.fileSizeFormat(
                  //                             assets.length),
                  //                         style: const TextStyle(
                  //                           fontSize: 9,
                  //                           color: Colors.white,
                  //                         ),
                  //                       ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.only(
          //       left: 12,
          //       right: 12,
          //       top: 12,
          //       bottom: AppUtils.safeAreapadding.bottom + 12),
          //   child: GestureDetector(
          //     onTap: () async {
          //       // final state = await PermissionUtils.checkPhotosWritePermisson();
          //       PermissionState state1 =
          //           await PhotoManager.requestPermissionExtend();
          //       if (state1.hasAccess) {
          //         List<String> deleIds = [];
          //         for (var asset in selPhotos) {
          //           final file = await asset.assetEntity.originFile;
          //           if (file != null) {
          //             final dirName = file.parent.path;
          //             final fileName = file.uri.pathSegments.last;
          //             final newFileName =
          //                 '$dirName${Platform.pathSeparator}${fileName.split('.').first}_cmps.${fileName.split('.').last}';
          //             try {
          //               final cmpFileBytes =
          //                   await FlutterImageCompress.compressWithFile(
          //                 file.path,
          //                 quality: 80,
          //               );
          //               if (cmpFileBytes != null) {
          //                 await PhotoManager.editor.saveImage(
          //                   cmpFileBytes,
          //                   filename:
          //                       '${fileName.split('.').first}_cmps.${fileName.split('.').last}',
          //                   orientation: asset.assetEntity.orientation,
          //                   relativePath: asset.assetEntity.relativePath,
          //                   title: asset.assetEntity.title,
          //                 );
          //                 deleIds.add(asset.assetEntity.id);
          //               }
          //             } catch (e) {}
          //           }
          //         }
          //         try {
          //           final result =
          //               await PhotoManager.editor.deleteWithIds(deleIds);
          //           // 通知界面刷新重新加载数据
          //           //TODO 通知其他页面刷新数据
          //           // 关闭大图检查线程 重写开启新线程
          //           bigPhotoIsolate?.kill();
          //           bigPhotoIsolate = await FlutterIsolate.spawn(
          //               spawnBigPhotosIsolate, globalPort.sendPort);
          //           for (var id in deleIds) {
          //             PhotoManagerTool.allPhotoAssetsIdMaps.remove(id);
          //             PhotoManagerTool.bigImageEntity = PhotoManagerTool
          //                 .bigImageEntity
          //                 .where((el) => el.assetEntity.id != id)
          //                 .toList();
          //           }
          //           var newList = <ImageAsset>[];
          //           for (var bigAsset in samePhotos) {
          //             if (!deleIds.contains(bigAsset.assetEntity.id)) {
          //               newList.add(bigAsset);
          //             }
          //           }
          //           setState(() {
          //             samePhotos = newList;
          //           });
          //           ToastUtil.showSuccessInfo(
          //               AppUtils.i18Translate('home.zipOk'));
          //           print('-----压缩完成--$result');
          //         } catch (e) {
          //           ToastUtil.showSuccessInfo(
          //               AppUtils.i18Translate('home.zipErr'));
          //           print('-----压缩失败 $e');
          //         }
          //       } else {
          //         final res = await AppDialog.showConfirmDialog(
          //           AppUtils.globalContext!,
          //           desc: AppUtils.i18Translate('home.deniedPhotoPermission'),
          //         );
          //         if (res) {
          //           AppSettings.openAppSettings();
          //         }
          //       }
          //     },
          //     child: Container(
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(4),
          //         color: AppColor.mainColor,
          //       ),
          //       width: double.infinity,
          //       padding: const EdgeInsets.symmetric(vertical: 10),
          //       alignment: Alignment.center,
          //       child: Text(
          //         '${AppUtils.i18Translate('home.zip', context: context)}${selPhotos.length}${AppUtils.i18Translate('home.sheet', context: context)}${AppUtils.i18Translate('home.image', context: context)}',
          //         style: const TextStyle(
          //           fontSize: 13,
          //           color: Colors.white,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
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
