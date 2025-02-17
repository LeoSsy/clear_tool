import 'dart:async';
import 'package:clear_tool/const/const.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoManagerTool {

  /// 保存所有图片资源对象
  static List<AssetEntity> allPhotoAssets = <AssetEntity>[];
  /// id 映射到图片资源对象
  static Map<String,AssetEntity> allPhotoAssetsIdMaps = {};

  /// 保存已加载的大图
  static List<ImageAsset> bigImageEntity = [];
  /// 保存大图容量
  static int bigSumSize = 0;

  /// 保存相似图片
  static List<SamePhotoGroup> sameImageEntity = [];
  /// 相似照片容量
  static int samePhotoSize = 0;

  /// 保存屏幕截图图片
  static List<ImageAsset> screenShotImageEntity = [];

  /// 是否加载相似图片中
  static bool isLoadingSamePhotos = true;

  /// 任务进度
 static double progress = 0.0;

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
}
