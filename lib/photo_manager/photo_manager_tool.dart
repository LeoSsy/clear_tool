import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/main.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_compare_2/image_compare_2.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

class PhotoManagerTool {
  /// 保存已加载的大图
  static List<AssetEntity> bigImageEntity = [];

  /// 保存相似图片
  static List<IsolateAssetMessage> sameImageEntity = [];

  /// 获取所有图片数量
  static Future<int> getPhotoCount() async {
    final List<AssetPathEntity> assets =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    int totalCount = 0;
    for (final album in assets) {
      totalCount += await album.assetCountAsync;
    }
    return totalCount;
  }

  /// 过滤相似图片
  // static filterSamePhotos() async {
  //   final assetPaths =
  //       await PhotoManager.getAssetPathList(type: RequestType.image);
  //   List<AssetEntity> photoAssets = <AssetEntity>[];
  //   List<AssetEntity> sameAssets = <AssetEntity>[];

  //   /// 所有图片路径
  //   List<File> photosFiles = <File>[];
  //   // 获取所有图片资源对象
  //   for (var album in assetPaths) {
  //     final assetList = await album.getAssetListRange(start: 0, end: 100000);
  //     for (var asset in assetList) {
  //       final file = await asset.file;
  //       photosFiles.add(file!);
  //     }
  //     photoAssets.addAll(assetList);
  //   }

  //   /// 两两比较
  //   for (var i = 0; i < photoAssets.length; i++) {
  //     for (var j = 0; j < photoAssets.length; j++) {
  //       final asset1 = await photoAssets[i].file;
  //       final asset2 = await photoAssets[j].file;
  //       try {
  //         if (asset1 != null && asset2 != null) {
  //           final result = await compareImages(src1: asset1, src2: asset2);
  //           if (result * 100 < 2) {
  //             sameAssets.add(photoAssets[i]);
  //             sameAssets.add(photoAssets[j]);
  //             // 发送消息通知首页更新数据
  //             globalStreamControler.add(SamePhotoEvent(sameAssets));
  //           }
  //           print('result-----$result');
  //         }
  //       } catch (e) {
  //         print('识别异常 ${e.toString()}');
  //       }
  //     }
  //   }
  //   return [];
  // }

  /// screen shot
  static FutureOr<List<AssetEntity>> fetchScreenShots() async {
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    List<AssetEntity> photoAssets = <AssetEntity>[];
    // 获取所有图片资源对象
    for (var album in assetPaths) {
      if (album.name == 'Screenshots') {
        final screenshotAssets =
            await album.getAssetListRange(start: 0, end: 100000);
        photoAssets.addAll(screenshotAssets);
        break;
      }
    }
    return photoAssets;
  }

  /// load big
  static fetchBigImages() async {
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    List<AssetEntity> photoAssets = <AssetEntity>[];
    List<AssetEntity> bigssets = <AssetEntity>[];
    // 获取所有图片资源对象
    for (var album in assetPaths) {
      final assetItems = await album.getAssetListRange(start: 0, end: 100000);
      photoAssets.addAll(assetItems);
      // final count = await album.assetCountAsync;
      // 计算分页
      // const pageSize = 1000;
      // final totalPage = (count / pageSize).ceil();
      // var curentPage = 1;
      // while (curentPage < totalPage) {
      //   final assetItems =
      //       await album.getAssetListPaged(page: curentPage, size: pageSize);
      //   photoAssets.addAll(assetItems);
      //   curentPage++;
      // }
    }
    // for (var asset in photoAssets) {
    //   final file = await asset.file;
    //   if (file != null) {
    //     final length = await file.length();
    //     if (length / 1024 / 1024 > maxImageMB) {
    //       bigssets.add(asset);
    //     }
    //   }
    // }
    // if (bigImageEntity.isEmpty) {
    //   bigImageEntity.addAll(bigssets);
    // } else {
    //   final loadedIds = bigImageEntity.map((e) => e.id).toList();
    //   for (var asset in bigssets) {
    //     if (!loadedIds.contains(asset.id)) {
    //       bigImageEntity.add(asset);
    //     }
    //   }
    // }
    for (var asset in photoAssets) {
      final file = await asset.file;
      if (file != null) {
        final length = await file.length();
        if (length / 1024 / 1024 > maxImageMB) {
          if (bigImageEntity.isEmpty) {
            bigImageEntity.add(asset);
          } else {
            final loadedIds = bigImageEntity.map((e) => e.id).toList();
            for (var asset in bigssets) {
              if (!loadedIds.contains(asset.id)) {
                bigImageEntity.add(asset);
              }
            }
          }
        }
      }
    }
    return bigImageEntity;
  }
}
