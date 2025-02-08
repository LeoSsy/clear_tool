import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clear_tool/const/const.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

class PhotoManagerTool {
  /// 保存已加载的大图
  static List<AssetEntity> bigImageEntity = [];

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
      final totalPage = (count / pageSize).ceil();
      var curentPage = 1;
      while (curentPage < totalPage) {
        final assetItems =
            await album.getAssetListPaged(page: curentPage, size: pageSize);
        photoAssets.addAll(assetItems);
        curentPage++;
      }
    }
    // 识别相似图片
    List<AssetEntity> sameAssets = <AssetEntity>[];
    int currentIndex = 0;
    int nextIndex = 1;
    int benginT = DateTime.now().millisecondsSinceEpoch;
    print("begin----------${DateTime.now().millisecondsSinceEpoch}");
    while (currentIndex < photoAssets.length - 2) {
      final currentAssets = photoAssets[currentIndex];
      final nextAssets = photoAssets[nextIndex];
      // if (currentAssets.size.width != nextAssets.size.width &&
      //     currentAssets.size.height != nextAssets.size.height) {
      //   continue;
      // }

      // final currentHash = await _computePHash(currentAssets);
      // final nextHash = await _computePHash(nextAssets);
      // if (currentHash == nextHash) {
      //   sameAssets.add(currentAssets);
      //   sameAssets.add(nextAssets);
      // } else {
      //   if (currentHash != null && nextHash != null) {
      //     final hmDis = _hammingDistance(currentHash, nextHash);
      //     if (hmDis < 10) {
      //       sameAssets.add(currentAssets);
      //       sameAssets.add(nextAssets);
      //     }
      //   }
      // }
      // print("currentIndex-----${currentHash}");
      // print("nextIndex-----${nextHash}");
      final currentFile = await currentAssets.file;
      final nextFile = await currentAssets.file;
      if (currentFile != null && nextFile != null) {
        final same = await _checkSimilarity(currentFile, nextFile);
        if (same) {
          sameAssets.add(currentAssets);
          sameAssets.add(nextAssets);
        }
      }
      currentIndex++;
      nextIndex++;
    }
    double endT = (DateTime.now().millisecondsSinceEpoch - benginT) / 1000.0;
    print("end----------$endT");
    print('photoAssets----${photoAssets.length}');
  }

  /// 颜色直方图比较 ====================
  // Future<List<double>> _computeColorHistogram(AssetEntity asset) async {
  //   final File? file = await asset.file;
  //   if (file == null) return [];
  //   final image = img.decodeImage(await file.readAsBytes())!;
  //   final resized = img.copyResize(image, width: 64, height: 64); // 缩小加快计算
  //   // 将RGB颜色空间划分为16x16x16的立方体
  //   final histogram = List<double>.filled(16 * 16 * 16, 0);
  //   // 获取红色通道
  //   int getRed(int pixel) => (pixel >> 16) & 0xFF;
  //   // 获取绿色通道
  //   int getGreen(int pixel) => (pixel >> 8) & 0xFF;
  //   // 获取蓝色通道
  //   int getBlue(int pixel) => pixel & 0xFF;

  //   for (final pixel in resized.data!) {
  //     final int pixel1 = image.getPixel(pixel.x, pixel.y) as int;
  //     final r = getRed(pixel1) ~/ 16;
  //     final g = getGreen(pixel1) ~/ 16;
  //     final b = getBlue(pixel1) ~/ 16;
  //     histogram[r * 256 + g * 16 + b]++;
  //   }

  //   /// 直方图对比 阈值示例：相似度≥0.9为相似
  //   double _cosineSimilarity(List<double> a, List<double> b) {
  //     double dot = 0, magA = 0, magB = 0;
  //     for (int i = 0; i < a.length; i++) {
  //       dot += a[i] * b[i];
  //       magA += a[i] * a[i];
  //       magB += b[i] * b[i];
  //     }
  //     return dot / (sqrt(magA) * sqrt(magB));
  //   }

  //   /// =================================

  //   // 归一化
  //   final sum = histogram.reduce((a, b) => a + b);
  //   return histogram.map((v) => v / sum).toList();
  // }

  /// 感知hash =================
  static Future<String?> _computePHash(AssetEntity asset) async {
    final File? file = await asset.file;
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    img.Image image = img.decodeImage(bytes)!;

    // 处理EXIF旋转
    final exifData = await readExifFromBytes(bytes);
    if (exifData == null) return null;
    // 过滤掉 null 键
    Map<String, IfdTag> nonNullableKeyMap = {};
    exifData.forEach((key, value) {
      if (key != null) {
        nonNullableKeyMap[key] = value;
      }
    });
    image = await _applyExifRotation(image, nonNullableKeyMap);

    // 缩放为32x32并灰度化
    image = img.copyResize(image, width: 32, height: 32);
    image = img.grayscale(image);

    // 获取红色通道
    int getRed(int pixel) => (pixel >> 16) & 0xFF;

    // 计算所有像素的平均值
    int sum = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        sum += getRed(image.getPixel(x, y));
      }
    }
    double average = sum / (image.width * image.height);

    // 生成哈希值
    String hash = '';
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixelValue = getRed(image.getPixel(x, y));
        if (pixelValue > average) {
          hash += '1';
        } else {
          hash += '0';
        }
      }
    }
    return hash;
  }

  // 根据EXIF旋转图片
  static Future<img.Image> _applyExifRotation(
      img.Image image, Map<String, IfdTag> exif) async {
    if (!exif.containsKey('Image Orientation')) return image;
    final orientation = exif['Image Orientation']!.printable;
    switch (orientation) {
      case 'Rotated 90 CW':
        return img.copyRotate(image, 90);
      case 'Rotated 180':
        return img.copyRotate(image, 180);
      case 'Rotated 270 CW':
        return img.copyRotate(image, 270);
      default:
        return image;
    }
  }

  /// ============================

  /// 检查相似
  static Future<bool> _checkSimilarity(File image1, File image2) async {
    // final image1Bytes = await _compressImage(image1);
    // final image2Bytes = await _compressImage(image2);
    final image1Bytes = await image1.readAsBytes();
    final image2Bytes = await image2.readAsBytes();
    final isSimilar = _areImagesSimilar(image1Bytes, image2Bytes);
    return isSimilar;
  }

  /// 压缩图片
  static Future<Uint8List> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 100,
      minHeight: 100,
      quality: 76,
    );
    return result!;
  }

  /// 计算图片的平均哈希值
  static Future<String?> _calculateAverageHash(Uint8List imageBytes) async {
    img.Image image = img.decodeImage(imageBytes)!;

    // 处理EXIF旋转
    final exifData = await readExifFromBytes(imageBytes);
    if (exifData == null) return null;
    // 过滤掉 null 键
    Map<String, IfdTag> nonNullableKeyMap = {};
    exifData.forEach((key, value) {
      if (key != null) {
        nonNullableKeyMap[key] = value;
      }
    });
    image = await _applyExifRotation(image, nonNullableKeyMap);

    // 缩放为32x32并灰度化
    image = img.copyResize(image, width: 32, height: 32);
    image = img.grayscale(image);

    // 获取红色通道
    // int getRed(int pixel) => (pixel >> 16) & 0xFF;

    // 计算所有像素的平均值
    int sum = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        sum += img.getRed(image.getPixel(x, y));
      }
    }
    double average = sum / (image.width * image.height);

    // 生成哈希值
    String hash = '';
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixelValue = img.getRed(image.getPixel(x, y));
        if (pixelValue > average) {
          hash += '1';
        } else {
          hash += '0';
        }
      }
    }
    return hash;
  }

  /// 计算两个哈希值的汉明距离
  static int _hammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) return -1;
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) distance++;
    }
    return distance;
  }

  /// 判断两张图片是否相似（汉明距离小于阈值）
  static Future<bool> _areImagesSimilar(
      Uint8List image1Bytes, Uint8List image2Bytes) async {
    final hash1 = await _calculateAverageHash(image1Bytes);
    final hash2 = await _calculateAverageHash(image2Bytes);
    if (hash1 != null && hash2 != null) {
      final distance = _hammingDistance(hash1, hash2);
      return distance < 10; // 调整阈值（通常 5-10 为相似）
    } else {
      return false;
    }
  }

  static Future fetchPhoto(int page, {int pageSize = 100}) async {
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    final allImgs =
        await assetPaths.first.getAssetListPaged(page: page, size: pageSize);
    print('alimage');
  }

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
