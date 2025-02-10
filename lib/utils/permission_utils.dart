import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:clear_tool/dialog/dialog.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限工具类
class PermissionUtils {
  /// 检查相册权限
  static Future<bool> checkPhotosPermisson({String? permisinUsingInfo}) async {
    bool? isPoped;
    var navigator;
    if (AppUtils.globalContext != null) {
      isPoped = false;
      navigator = Navigator.of(AppUtils.globalContext!);
      AppDialog.showPermissionHintDialog(AppUtils.globalContext,
              desc: permisinUsingInfo ?? AppUtils.i18Translate("common.dialog.use_info_photo"))
          .then((value) {
        if (value != null) {
          isPoped = true;
        }
      });
    }

    /// 授权结果
    bool permisionResult = false;
    PermissionStatus permission;
    // android 13
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (int.parse(androidInfo.version.release.split('.').first) >= 13) {
        permission = await Permission.photos.status;
      } else {
        // 申请结果  权限检测
        permission = await Permission.storage.status;
      }
      // ios
    } else {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      // ios14及以上 使用photos
      if (int.parse(iosInfo.systemVersion!.split('.').first) >= 14) {
        // 申请结果  权限检测
        permission = await Permission.photos.status;
      } else {
        // 申请结果  权限检测
        permission = await Permission.camera.status;
      }
    }
    if (permission != PermissionStatus.granted) {
      PermissionStatus pp;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (int.parse(androidInfo.version.release.split('.').first) >= 13) {
          await [Permission.photos].request();
          pp = await Permission.photos.status;
        } else {
          //   //只有当用户同时点选了拒绝开启权限和不再提醒后才会true
          await [Permission.storage].request();
          // 申请结果  权限检测
          pp = await Permission.storage.status;
        }
        // ios
      } else {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        // ios14及以上 使用photos
        if (int.parse(iosInfo.systemVersion!.split('.').first) >= 14) {
          //只有当用户同时点选了拒绝开启权限和不再提醒后才会true
          await [Permission.photos].request();
          // 申请结果  权限检测
          pp = await Permission.photos.status;
        } else {
          await [Permission.camera].request();
          // 申请结果  权限检测
          pp = await Permission.camera.status;
        }
      }
      if (pp == PermissionStatus.granted) {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        permisionResult = true;
      } else {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        await _showPhotoAlbumDeniedDialog();
        permisionResult = false;
      }
    } else {
      // 关闭权限说明弹框
      if (isPoped != null && !isPoped!) {
        navigator.pop();
      }
      permisionResult = true;
    }
    return permisionResult;
  }

  /// 检查相机权限
  static Future<bool> checkCameraPermisson({String? permisinUsingInfo}) async {
    bool? isPoped;
    var navigator;
    if (AppUtils.globalContext != null) {
      isPoped = false;
      navigator = Navigator.of(AppUtils.globalContext!);
      AppDialog.showPermissionHintDialog(AppUtils.globalContext!,
              desc: permisinUsingInfo ?? '仅用于拍照')
          .then((value) {
        if (value != null) {
          isPoped = true;
        }
      });
    }
    bool permisionResult = false;
    // 申请结果  权限检测
    PermissionStatus permission = await Permission.camera.status;
    if (permission != PermissionStatus.granted) {
      final permissionResult = await [Permission.camera].request();
      PermissionStatus pp = permissionResult[Permission.camera]!;
      if (pp == PermissionStatus.granted) {
        permisionResult = true;
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
      } else {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        await _showPhotoCameraDeniedDialog();
        permisionResult = false;
      }
    } else {
      // 关闭权限说明弹框
      if (isPoped != null && !isPoped!) {
        navigator.pop();
      }
      permisionResult = true;
    }
    return permisionResult;
  }

  /// 检查存储权限
  static Future<bool> checkStoragePermisson({String? permisinUsingInfo}) async {
    bool? isPoped;
    var navigator;
    if (AppUtils.globalContext != null) {
      isPoped = false;
      navigator = Navigator.of(AppUtils.globalContext!);
      AppDialog.showPermissionHintDialog(AppUtils.globalContext!,
              desc: permisinUsingInfo ?? '仅用于保存文件到手机')
          .then((value) {
        if (value != null) {
          isPoped = true;
        }
      });
    }
    // 存储授权结果
    bool permisionResult = false;
    PermissionStatus permission;
    //只有当用户同时点选了拒绝开启权限和不再提醒后才会true
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (int.parse(androidInfo.version.release) > 10) {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        return true;
      }
      // 申请结果  权限检测
      permission = await Permission.storage.status;
    } else {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      // ios14及以上 使用photos
      if (int.parse(iosInfo.systemVersion!.split('.').first) >= 14) {
        // 申请结果  权限检测
        permission = await Permission.photos.status;
      } else {
        // 申请结果  权限检测
        permission = await Permission.camera.status;
      }
    }
    if (permission != PermissionStatus.granted) {
      PermissionStatus pp;
      if (Platform.isAndroid) {
        await [Permission.storage].request();
        // 申请结果  权限检测
        pp = await Permission.storage.status;
      } else {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        // ios14及以上 使用photos
        if (int.parse(iosInfo.systemVersion!.split('.').first) >= 14) {
          //只有当用户同时点选了拒绝开启权限和不再提醒后才会true
          await [Permission.photos].request();
          // 申请结果  权限检测
          pp = await Permission.photos.status;
        } else {
          await [Permission.camera].request();
          // 申请结果  权限检测
          pp = await Permission.camera.status;
        }
      }
      if (pp == PermissionStatus.granted) {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        permisionResult = true;
      } else {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        await _showStorageDeniedDialog();
        permisionResult = false;
      }
    } else {
      // 关闭权限说明弹框
      if (isPoped != null && !isPoped!) {
        navigator.pop();
      }
      permisionResult = true;
    }
    return permisionResult;
  }

  /// 检查位置权限
  /// [permisinUsingInfo] 权限使用说明
  /// [showUseingDialog] 是否显示权限使用说明弹框 默认false
  /// [showDenyDialog]   是否显示无权限弹框 默认true
  static Future<bool> checkLocationPermisson(
      {String? permisinUsingInfo,
      bool showUseingDialog = false,
      bool showDenyDialog = true}) async {
    final res = await _checkPermission(
        Permission.locationWhenInUse,
        permisinUsingInfo ?? '仅用于获取您当前的位置',
        showDenyDialog ? '无法获取您的定位,请前往系统设置中允许友客e家访问您的位置权限' : null);
    return res;
  }

  /// 权限联系人检查
  static Future<bool> checkContactsPermisson(
      {String? permisinUsingInfo}) async {
    final res = await _checkPermission(
        Permission.contacts,
        permisinUsingInfo ?? '用户读取手机联系人信息，自动填充电话号码，请放心授权访问！',
        '无法访问您的联系人信息,请前往系统设置中允许友客e家访问您的联系人权限');
    return res;
  }

  /// 权限麦克风检查
  static Future<bool> checkMicrophonePermisson(
      {String? permisinUsingInfo}) async {
    final res = await _checkPermission(
        Permission.microphone,
        permisinUsingInfo ?? '仅用于录制语音备注，请放心授权！',
        '无法访问您的麦克风,请前往系统设置中允许友客e家访问您的麦克风权限');
    return res;
  }

  /// 检查通知权限
  static Future<bool> checkNotificationPermisson() async {
    // 申请结果  权限检测
    var permission = await Permission.notification.status;
    if (Platform.isAndroid) {
      if (permission != PermissionStatus.granted) {
        await Permission.notification.request();
        var pp = await Permission.notification.status;
        if (pp == PermissionStatus.granted) {
          return true;
        } else {
          await _showNotificationDeniedDialog();
          return false;
        }
      } else {
        return true;
      }
    } else if (Platform.isIOS) {
      await Permission.notification.request();
      // Ios 永久被拒绝
      if (permission.isPermanentlyDenied) {
        await _showNotificationDeniedDialog();
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  /// 检查权限通用方法
  /// [permission] 权限对象
  /// [permisinUsingInfo] 辅助弹框提示信息
  /// [showUseingDialog] 是否显示辅助弹框
  /// [deniedInfo]  权限拒绝 提示信息
  static Future<bool> _checkPermission(Permission permission,
      String? permisinUsingInfo, String? deniedInfo) async {
    // 授权结果
    bool permisionResult = false;
    var navigator;
    bool? isPoped;
    navigator = Navigator.of(AppUtils.globalContext!);
    if (permisinUsingInfo != null &&
        AppUtils.globalContext != null) {
      isPoped = false;
      AppDialog.showPermissionHintDialog(AppUtils.globalContext!,
              desc: permisinUsingInfo)
          .then((value) {
        if (value != null) {
          isPoped = true;
        }
      });
    }
    // 申请结果  权限检测
    var permissionStatus = await permission.status;
    if (permissionStatus != PermissionStatus.granted) {
      await permission.request();
      var pp = await permission.status;
      if (pp == PermissionStatus.granted) {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        permisionResult = true;
      } else {
        // 关闭权限说明弹框
        if (isPoped != null && !isPoped!) {
          navigator.pop();
        }
        // 权限被拒绝提示
        if (deniedInfo != null) {
          await _showPermissionDeniedDialog(deniedInfo);
        }
        permisionResult = false;
      }
    } else {
      // 关闭权限说明弹框
      if (isPoped != null && !isPoped!) {
        navigator.pop();
      }
      permisionResult = true;
    }
    return permisionResult;
  }

  /// 相册权限被拒绝弹框
  static Future _showPhotoAlbumDeniedDialog() async {
    if (AppUtils.globalContext != null) {
      if (Platform.isAndroid) {
        _showPermissionDeniedDialog(AppUtils.i18Translate('common.dialog.permission_denied1'));
      } else {
        _showPermissionDeniedDialog(AppUtils.i18Translate('common.dialog.permission_denied1'));
      }
    }
  }

  /// 权限被拒绝弹框
  static Future<bool> _showPermissionDeniedDialog(String desc) async {
    if (AppUtils.globalContext != null) {
      final res = await AppDialog.showConfirmDialog(
        AppUtils.globalContext!,
        title: AppUtils.i18Translate('common.dialog.title1'),
        desc: desc,
        confirmTitle: AppUtils.i18Translate('common.dialog.confirmTitle1'),
        cancleTitle: AppUtils.i18Translate('common.dialog.cancleTitle1'),
      );
      if (res) {
        AppSettings.openAppSettings();
      }
      return res;
    }
    return false;
  }

  /// 相机权限被拒绝弹框
  static Future _showPhotoCameraDeniedDialog() async {
    if (AppUtils.globalContext != null) {
      _showPermissionDeniedDialog("无法访问您的相机,请前往系统设置中允许友客e家访问您的手机相机权限");
    }
  }

  /// 存储权限被拒绝弹框
  static Future _showStorageDeniedDialog() async {
    if (AppUtils.globalContext != null) {
      if (Platform.isAndroid) {
        _showPermissionDeniedDialog(AppUtils.i18Translate('common.dialog.permission_denied1'));
      } else {
        _showPermissionDeniedDialog(AppUtils.i18Translate('common.dialog.permission_denied1'));
      }
    }
  }

  /// 通知权限被拒绝弹框
  static Future<bool> _showNotificationDeniedDialog() async {
    if (AppUtils.globalContext != null) {
      final res = await AppDialog.showConfirmDialog(
        AppUtils.globalContext!,
        title: "温馨提示",
        desc: "当前无通知权限，为了及时获取房源动态和报备状态，是否前往设置允许友客e家为您发送通知",
        confirmTitle: '前往设置',
        cancleTitle: '暂不设置',
      );
      if (res) {
        AppSettings.openNotificationSettings();
      }
      return res;
    }
    return false;
  }
}
