import 'dart:io';
import 'dart:math';

import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/widget/image_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:photo_manager/photo_manager.dart';

class AppUtils {
  /// context
  static BuildContext? globalContext;

  /// 屏幕逻辑像素比
  static double pixelRatio = 2;

  /// 屏幕宽度
  static double screenW = 0;

  /// 屏幕高度
  static double screenH = 0;

  /// 距离上下左右的 安全区域 距离
  static EdgeInsets safeAreapadding = EdgeInsets.zero;

  /// i18转换
  static String i18Translate(String key, {BuildContext? context}) {
    if (context != null) {
      return FlutterI18n.translate(context, key);
    } else {
      if (globalContext == null || !globalContext!.mounted) {
        return '';
      }
      return FlutterI18n.translate(globalContext!, key);
    }
  }

  /// 文件大小格式化
  static String fileSizeFormat(int size, {int toFixed = 2}) {
    try {
      final unit = ['B', 'KB', 'MB', 'GB'];
      final tp = (log(size) / log(imgUnitOfAccount)).floor();
      return '${(size / pow(imgUnitOfAccount, tp)).ceil().toStringAsFixed(toFixed)}${unit[tp.toInt()]}';
    } catch (e) {
      return '0KB';
    }
  }

  /// 预览图片
  /// [images]  图片数组 可以传入类型如下：List<ImageAsset>
  ///  图片数组内部元素可以是： 网络地址、本地文件地址、本地项目图片资源地址
  static Future showImagePreviewDialog(
      BuildContext context, List<ImageAsset> images,
      [int index = 0]) async {
    if (images.isEmpty) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (BuildContext context) {
        return SafeArea(
          bottom: false,
          top: false,
          child: Material(
            color: Colors.black,
            child: Stack(
              children: [
                ImagePreviewWidget(
                  images: images,
                  index: index,
                ),
                Positioned(
                  right: 12,
                  top: AppUtils.safeAreapadding.top + 12,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
