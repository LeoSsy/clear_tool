

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class AppUtils {

  /// context
  static BuildContext? context;

  /// 屏幕逻辑像素比
  static double pixelRatio = 2;

  /// 屏幕宽度
  static double screenW = 0;

  /// 屏幕高度
  static double screenH = 0;

  /// 距离上下左右的 安全区域 距离
  static EdgeInsets safeAreapadding = EdgeInsets.zero;

  /// i18转换
  static String i18Translate(String key){
    if (context == null || !context!.mounted) {
      return '';
    }
    return FlutterI18n.translate(context!, key);
  }
  
}

