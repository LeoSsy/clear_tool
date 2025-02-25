import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/permission_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:mmkv/mmkv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:system_device_info/system_device_info.dart';

class AppState extends ChangeNotifier {
  String totalSize = '';
  String useSize = '';
  String deviceName = '';

  /// 使用进度
  double circleProgress = 0;

  /// 相似照片组集合
  List<SamePhotoGroup> sameGroupPhotos = [];
  List<ImageAsset>? samePhotos;

  /// 相似照片容量
  int samePhotoSize = 0;

  /// 屏幕截图合集
  List<ImageAsset>? screenPhotos;

  /// 屏幕截图照片容量
  int screenPhotoSize = 0;

  /// 大图合集
  List<ImageAsset>? bigPhotos;

  /// 处理大图标记
  bool isBigProcessing = false;

  /// 大图照片容量
  int bigPhotoSize = 0;

  /// 进度圆颜色
  Color color = Colors.white;

  /// 进度圆背景图片
  String progressBgImage = 'assets/images/home/blue_progress_bg.png';

  /// 订阅事件
  late StreamSubscription _streamSubscription;

  double bigPhotoProgress = 0;
  double screenshotPhotoProgress = 0;
  double samePhotoProgress = 0;

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
  }

  AppState() {
    getDiskInfo();
    _streamSubscription = globalStreamControler.stream.listen((event) async {
      if (event is AllPhotoLoadFinishEvent) {
        // 开启子线程检测数据
        FlutterIsolate.spawn(spawnSamePhotosIsolate, globalPort.sendPort);
        screenshotPhotoIsolate = await FlutterIsolate.spawn(
            spawnScreenshotIsolate, globalPort.sendPort);
        bigPhotoIsolate = await FlutterIsolate.spawn(
            spawnBigPhotosIsolate, globalPort.sendPort);
      } else if (event is SamePhotoDeleteEvent) {
        for (var id in event.ids) {
          for (var group in sameGroupPhotos) {
            group.assets.removeWhere((el) => el.assetEntity.id == id);
          }
        }
        samePhotoSize = max(samePhotoSize -= event.deleteTotalSize, 0);
        notifyListeners();
        getDiskInfo();
      } else if (event is SamePhotoEvent) {
        if (event.group == null) {
          samePhotos = [];
          notifyListeners();
          return;
        }
        samePhotos ??= [];
        final group = event.group;
        // 获取所有图片id集合
        final newAssetList = <SamePhotoGroup>[];
        if (group!.ids != null) {
          for (var assetId in group.ids!) {
            if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(assetId)) {
              final assetEntity =
                  PhotoManagerTool.allPhotoAssetsIdMaps[assetId]!;
              final file = await assetEntity.originFile;
              if (file != null) {
                final length = await file.length();
                final thumbnailData = await assetEntity.thumbnailDataWithSize(
                    ThumbnailSize(
                        AppUtils.screenW.toInt(), AppUtils.screenW.toInt()));
                group.assets.add(ImageAsset(assetEntity)
                  ..originalFilePath = file.path
                  ..thumnailBytes = thumbnailData
                  ..length = length);
                newAssetList.add(group);
              }
            }
          }
          for (var newAsset in newAssetList) {
            final sameCache =
                sameGroupPhotos.where((el) => el.id == newAsset.id).toList();
            if (sameCache.isEmpty) {
              samePhotos?.addAll(newAsset.assets);
              sameGroupPhotos.add(newAsset);
            }
          }
          int sumSize = 0;
          for (var group in sameGroupPhotos) {
            for (var asset in group.assets) {
              sumSize += asset.length;
            }
          }
          samePhotoSize = sumSize;
          PhotoManagerTool.sameImageEntity = sameGroupPhotos;
          PhotoManagerTool.samePhotoSize = samePhotoSize;

          notifyListeners();
        }
      } else if (event is ScreenPhotoDeleteEvent) {
        for (var id in event.ids) {
          screenPhotos?.removeWhere((el) => el.assetEntity.id == id);
        }
        screenPhotoSize = max(screenPhotoSize -= event.deleteTotalSize, 0);
        notifyListeners();
        getDiskInfo();
      } else if (event is ScreenPhotoEvent) {
        if (event.id == null) {
          screenPhotos = [];
          notifyListeners();
          return;
        }
        screenPhotos ??= [];
        // 获取所有图片id集合
        final newAssetList = <ImageAsset>[];
        if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(event.id)) {
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailDataWithSize(
                ThumbnailSize(
                    AppUtils.screenW.toInt(), AppUtils.screenW.toInt()));
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        } else {
          PhotoManagerTool.allPhotoAssetsIdMaps[event.id!] = PhotoManagerTool
              .allPhotoAssets
              .where((el) => el.id == event.id)
              .toList()
              .first;
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailDataWithSize(
                ThumbnailSize(
                    AppUtils.screenW.toInt(), AppUtils.screenW.toInt()));
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        }
        screenPhotos?.addAll(newAssetList);
        PhotoManagerTool.screenShotImageEntity = screenPhotos ?? [];
        screenPhotoSize = event.totalSize;
        notifyListeners();
      } else if (event is BigPhotoDeleteEvent) {
        for (var id in event.ids) {
          bigPhotos?.removeWhere((el) => el.assetEntity.id == id);
        }
        bigPhotoSize = max(bigPhotoSize -= event.deleteTotalSize, 0);
        notifyListeners();
        getDiskInfo();
      } else if (event is BigPhotoEvent) {
        if (event.id == null) {
          bigPhotos = [];
          notifyListeners();
          return;
        }
        bigPhotos ??= [];
        // 获取所有图片id集合
        final newAssetList = <ImageAsset>[];
        if (PhotoManagerTool.allPhotoAssetsIdMaps.keys.contains(event.id)) {
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailDataWithSize(
                ThumbnailSize(
                    AppUtils.screenW.toInt(), AppUtils.screenW.toInt()));
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        } else {
          PhotoManagerTool.allPhotoAssetsIdMaps[event.id!] = PhotoManagerTool
              .allPhotoAssets
              .where((el) => el.id == event.id)
              .toList()
              .first;
          final assetEntity = PhotoManagerTool.allPhotoAssetsIdMaps[event.id]!;
          final file = await assetEntity.originFile;
          if (file != null) {
            final thumbnailData = await assetEntity.thumbnailDataWithSize(
                ThumbnailSize(
                    AppUtils.screenW.toInt(), AppUtils.screenW.toInt()));
            newAssetList.add(ImageAsset(assetEntity)
              ..originalFilePath = file.path
              ..thumnailBytes = thumbnailData);
          }
        }
        int sumSize = 0;
        for (var asset in newAssetList) {
          final originalFilePath = asset.originalFilePath;
          if (originalFilePath != null) {
            final length = await File(originalFilePath).length();
            sumSize += length;
          }
        }

        final mmkv = MMKV.defaultMMKV();
        final cache = mmkv.decodeString(imageCompressedCacheKey);
        if (cache != null) {
          final cacheList = jsonDecode(cache);
          newAssetList
              .removeWhere((el) => cacheList.contains(el.assetEntity.id));
        }
        PhotoManagerTool.bigImageEntity.addAll(newAssetList);
        bigPhotos = PhotoManagerTool.bigImageEntity;
        if (bigPhotos!.isNotEmpty) {
          PhotoManagerTool.bigSumSize += sumSize;
          bigPhotoSize = PhotoManagerTool.bigSumSize;
          notifyListeners();
        }
      } else if (event is RefreshEvent) {
        notifyListeners();
      }
      if (event is TaskProgressEvent) {
        if (event.type == "bigPhoto") {
          bigPhotoProgress = event.progress;
        } else if (event.type == "screenshotPhoto") {
          screenshotPhotoProgress = event.progress;
        } else if (event.type == "samePhoto") {
          samePhotoProgress = event.progress;
        }
        PhotoManagerTool.progress =
            bigPhotoProgress + screenshotPhotoProgress + samePhotoProgress;
        notifyListeners();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () async {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        // 检查权限
        final havePermission = await PermissionUtils.checkPhotosPermisson(
            permisinUsingInfo: AppUtils.i18Translate(
                'common.dialog.use_info_photo',
                context: AppUtils.globalContext));
        if (havePermission) {
          PhotoManagerTool.allPhotoAssets = [];
          final assetPaths =
              await PhotoManager.getAssetPathList(type: RequestType.image);
          // 获取所有图片资源对象
          for (var album in assetPaths) {
            final count = await album.assetCountAsync;
            if (count > 0) {
              final assetItems =
                  await album.getAssetListRange(start: 0, end: count);
              PhotoManagerTool.allPhotoAssets.addAll(assetItems);
              // id 映射
              for (var asset in assetItems) {
                if (!PhotoManagerTool.allPhotoAssetsIdMaps
                    .containsKey(asset.id)) {
                  PhotoManagerTool.allPhotoAssetsIdMaps[asset.id] = asset;
                }
              }
            }
          }
          // 所有图片加载完成 发送通知
          globalStreamControler.add(AllPhotoLoadFinishEvent());
        }
      });
    });
  }

  int sameCount() {
    int count = 0;
    for (var group in sameGroupPhotos) {
      count += group.assets.length;
    }
    return count;
  }

  void getDiskInfo() async {
    final tz = await SystemDeviceInfo.totalSize();
    if (tz != null) {
      totalSize = AppUtils.fileSizeFormat(tz);
    }
    final fz = await SystemDeviceInfo.freeSize();
    if (fz != null) {
      useSize = AppUtils.fileSizeFormat(tz! - fz);
      final value = ((tz - fz) / tz) * 100;
      if (value > 90) {
        color = const Color(0xffEC5C0C);
        progressBgImage = 'assets/images/home/red_progress_bg.png';
      } else if (value > 70) {
        color = const Color(0xffE7950C);
        progressBgImage = 'assets/images/home/orange_progress_bg.png';
      } else if (value > 30) {
        color = const Color(0xffDAD31B);
        progressBgImage = 'assets/images/home/yellow_progress_bg.png';
      } else {
        color = AppColor.mainColor;
        progressBgImage = 'assets/images/home/blue_progress_bg.png';
      }
      circleProgress = value;
    }

    if (Platform.isAndroid) {
      final anInfo = await DeviceInfoPlugin().androidInfo;
      deviceName = anInfo.model;
    } else {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      deviceName = iosInfo.name ?? '';
    }
    notifyListeners();
  }
}
