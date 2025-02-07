import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoManagerTool {
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
  static filterSamePhotos() async {
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    List<AssetEntity> photoAssets = <AssetEntity>[];
    // 获取所有图片资源对象
    for (var album in assetPaths) {
      final count = await album.assetCountAsync;
      // 计算分页
      const pageSize = 100;
      final totalPage = (count/pageSize).ceil();
      var curentPage = 1;
      while (curentPage < totalPage) {
        final assetItems = await album.getAssetListPaged(page: curentPage, size: pageSize);
        photoAssets.addAll(assetItems);
        curentPage++;
      }
    }
    // 识别相似图片
    List<AssetEntity> sameAssets = <AssetEntity>[];
    int currentIndex = 0;
    int nextIndex = 1;
    while (currentIndex < photoAssets.length-2) {
      final currentAssets = photoAssets[currentIndex];
      final nextAssets = photoAssets[nextIndex];
      if (currentAssets.duration == nextAssets.duration  && 
     currentAssets.orientation == nextAssets.orientation && 
     currentAssets.size.width == nextAssets.size.width && 
     currentAssets.size.height == nextAssets.size.height && 
     currentAssets.createDateTime.millisecondsSinceEpoch == nextAssets.createDateTime.millisecondsSinceEpoch && 
     currentAssets.modifiedDateTime.millisecondsSinceEpoch == nextAssets.modifiedDateTime.millisecondsSinceEpoch
      ) {
        sameAssets.add(currentAssets);
        sameAssets.add(nextAssets);

      }
      currentIndex++;
      nextIndex++;
    }
    print('photoAssets----${photoAssets.length}');
  }

  static Future fetchPhoto(int page, {int pageSize = 100}) async {
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    final allImgs =
        await assetPaths.first.getAssetListPaged(page: page, size: pageSize);
    print('alimage');
  }
}
