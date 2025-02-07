import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter/services.dart';

class AppDialog {
  /// 当前是否有弹框正在显示
  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  /// 按钮上下内边距 通过它改变按钮高度
  static const btnPadding = EdgeInsets.symmetric(vertical: 10);

  /// 按钮圆角 半径
  static const btnBorderRadius = 10.0;

  /// 弹框内边距
  static const dialogPadding =
      EdgeInsets.symmetric(horizontal: 15, vertical: 18);

  /// 显示一个提示信息框 带一个确定按钮
  /// 返回值为bool  正常点击确认按钮返回 true,点击背景遮罩或者滑动退出返回null
  static Future<bool> showInfoDialog(
    BuildContext context, {
    String? title,
    String? desc,
    String confirmTitle = "确认",
    Color? confirmBackgroundColor,
    Color? confirmTextColor,
  }) async {
    final res = await showCustomDialog(
      context,
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        padding: dialogPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Offstage(
              offstage: title == null || title.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  title ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: desc == null || desc.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  desc ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 100,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              highlightColor: Colors.white,
              splashColor: Colors.white,
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                decoration: BoxDecoration(
                  color: confirmBackgroundColor ?? AppColor.yellow,
                  borderRadius: BorderRadius.circular(btnBorderRadius),
                ),
                padding: btnPadding,
                width: MediaQuery.of(context).size.width * 0.8 / 2,
                alignment: Alignment.center,
                child: Text(
                  confirmTitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: confirmTextColor ?? Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
    return res;
  }

  /// 显示一个自定义内容区域信息提示框 带一个确定按钮
  /// 返回值为bool  正常点击确认按钮返回 true,点击背景遮罩或者滑动退出返回null
  static Future<bool> showInfoCustomContentDialog(
    BuildContext context, {
    String? title,
    Color? titleColor,
    required Widget contentWidget,
    Color? confirmBackgroundColor,
    String confirmTitle = "确认",
    Color? cancleBackgroundColor,
    String? cancleTitle,
  }) async {
    final res = await showCustomDialog(
      context,
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        padding: dialogPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Offstage(
              offstage: title == null || title.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  title ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    color: titleColor ?? AppColor.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            contentWidget,
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: cancleTitle != null,
                  child: Expanded(
                    child: InkWell(
                      highlightColor: Colors.white,
                      splashColor: Colors.white,
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cancleBackgroundColor ?? AppColor.textSecondary,
                          borderRadius: BorderRadius.circular(btnBorderRadius),
                        ),
                        padding: btnPadding,
                        alignment: Alignment.center,
                        child: Text(
                          cancleTitle ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    highlightColor: Colors.white,
                    splashColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: confirmBackgroundColor ?? AppColor.mainColor,
                        borderRadius: BorderRadius.circular(btnBorderRadius),
                      ),
                      padding: btnPadding,
                      alignment: Alignment.center,
                      child: Text(
                        confirmTitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
    return res;
  }

  /// 显示弹框 带一个确定和一个取消按钮
  /// 返回值为bool  正常点击确认按钮返回 true,点击取消按钮返回false，点击背景遮罩或者滑动退出返回null
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    String? title,
    String? desc,
    String confirmTitle = "确认",
    String cancleTitle = "取消",
    bool popDismissible = true,
    Color? cancleBackgroundColor,
    Color? cancleTextColor,
    Color? confirmBackgroundColor,
    Color? confirmTextColor,
    double titleFontSize = 18,
    double descFontSize = 15,
  }) async {
    final res = await showCustomDialog(
      context,
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        padding: dialogPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Offstage(
              offstage: title == null || title.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  title ?? '',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: desc == null || desc.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 12),
                child: Text(
                  desc ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 100,
                  style: TextStyle(
                    fontSize: descFontSize,
                    color: AppColor.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    highlightColor: Colors.white,
                    splashColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cancleBackgroundColor ?? Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: btnPadding,
                      alignment: Alignment.center,
                      child: Text(
                        cancleTitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: cancleTextColor ?? AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: confirmBackgroundColor ?? AppColor.mainColor,
                      borderRadius: BorderRadius.circular(btnBorderRadius),
                    ),
                    padding: btnPadding,
                    alignment: Alignment.center,
                    child: Text(
                      confirmTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: confirmTextColor ?? Colors.white,
                      ),
                    ),
                  ),
                ))
              ],
            ),
          ],
        ),
      ),
      popDismissible: popDismissible,
    );
    return res;
  }

  /// 显示确认弹框 带一个确定和一个取消按钮 点击背景可关闭
  /// 返回值为bool  正常点击确认按钮返回 true,点击取消按钮返回false，点击背景遮罩或者滑动退出返回null
  static Future<T?> showConfirmDialog1<T>(
    BuildContext context, {
    String? title,
    String? desc,
    String confirmTitle = "确认",
    String cancleTitle = "取消",
    bool popDismissible = true,
    bool clickPop = false,
    Color? cancleBackgroundColor,
    Color? cancleTextColor,
    Color? confirmBackgroundColor,
    Color? confirmTextColor,
  }) async {
    final res = await showCustomDialog1<T?>(
        context,
        GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            width: MediaQuery.of(context).size.width * 0.8,
            padding: dialogPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Offstage(
                  offstage: title == null || title.isEmpty,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      title ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColor.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Offstage(
                  offstage: desc == null || desc.isEmpty,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      desc ?? '',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 100,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        highlightColor: Colors.white,
                        splashColor: Colors.white,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                cancleBackgroundColor ?? Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: btnPadding,
                          alignment: Alignment.center,
                          child: Text(
                            cancleTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: cancleTextColor ?? AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: confirmBackgroundColor ?? AppColor.mainColor,
                          borderRadius: BorderRadius.circular(btnBorderRadius),
                        ),
                        padding: btnPadding,
                        alignment: Alignment.center,
                        child: Text(
                          confirmTitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: confirmTextColor ?? Colors.white,
                          ),
                        ),
                      ),
                    ))
                  ],
                ),
              ],
            ),
          ),
        ),
        popDismissible: popDismissible,
        clickPop: clickPop);
    return res;
  }

  /// 显示确认弹框 带一个确定和一个取消按钮 侧滑动可关闭
  /// 返回值为bool  正常点击确认按钮返回 true,点击取消按钮返回false，点击背景遮罩或者滑动退出返回null
  static Future<bool?> showConfirmDialogPop(
    BuildContext context, {
    String? title,
    String? desc,
    String confirmTitle = "确认",
    String cancleTitle = "取消",
    bool popDismissible = true,
  }) async {
    final res = await showCustomDialogPop(
      context,
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Offstage(
              offstage: title == null || title.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  title ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: desc == null || desc.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  desc ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 100,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    highlightColor: Colors.white,
                    splashColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(btnBorderRadius),
                      ),
                      child: Padding(
                        padding: btnPadding,
                        child: Center(
                          child: Text(
                            cancleTitle,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    highlightColor: Colors.white,
                    splashColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(btnBorderRadius),
                      ),
                      child: Padding(
                        padding: btnPadding,
                        child: Center(
                          child: Text(
                            confirmTitle,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      popDismissible: popDismissible,
    );
    return res;
  }

  /// 显示自定义弹框
  /// [context] 上下文对象
  /// [child]   自定义的widget
  ///  可选参数
  /// [barrierDismissible] 遮罩背景点击是否关闭弹框 默认为false
  /// [barrierColor]       遮罩背景颜色 默认黑色半透明  0x80000000
  /// [popDismissible]    是否可以滑动关闭弹框 默认为true
  ///
  static Future<dynamic> showCustomDialogPop(
    BuildContext context,
    Widget child, {
    bool barrierDismissible = false,
    Color barrierColor = const Color(0x80000000),
    bool popDismissible = true,
  }) async {
    _isShowing = true;
    dynamic res = await showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          onWillPop: () async {
            return popDismissible;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                ],
              ),
            ),
          ),
        );
      },
      // 自定义转场效果
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0,
            end: 1,
          ).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 1,
              end: 0,
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
    );
    _isShowing = false;
    return res;
  }

  /// 显示一个输入框的弹框 带提交按钮
  /// [context] 上下文对象
  /// [title] 弹框标题
  /// [placeholderText] 输入框的提示文字
  /// [confirmTitle] 确认按钮的文字
  /// [inputFormatter] 输入框的输入格式
  /// [maxLength] 输入框的文字个数 默认150个字符
  /// 返回值为String?  正常点击确认按钮返回输入的内容,点击背景遮罩或者滑动退出返回null
  static Future<String?> showInputNormalDialog(BuildContext context,
      {String title = '温馨提示',
      String placeholderText = '请输入内容',
      String confirmTitle = "提交",
      TextInputFormatter? inputFormatter,
      int maxLength = 150}) async {
    TextEditingController houseController = TextEditingController();
    final res = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) =>
          StatefulBuilder(builder: (buildContext, childState) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.2),
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * .7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          height: MediaQuery.of(context).size.width * .35,
                          padding:
                              EdgeInsets.only(left: 10, right: 10, bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(width: .5, color: Colors.grey[300]!),
                          ),
                          child: TextField(
                            keyboardAppearance: Brightness.light,
                            textAlign: TextAlign.left,
                            maxLength: maxLength,
                            maxLines: 1000,
                            controller: houseController,
                            autofocus: true,
                            inputFormatters:
                                inputFormatter != null ? [inputFormatter] : [],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: placeholderText,
                              hintStyle: TextStyle(
                                  color: Color.fromRGBO(188, 187, 187, 1),
                                  fontSize: 14),
                            ),
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                                child: GestureDetector(
                              onTap: () async {
                                if (houseController.text.isEmpty) {
                                  ToastUtil.showFailMsg(placeholderText);
                                  return;
                                }
                                Navigator.of(context).pop(true);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColor.mainColor,
                                  borderRadius:
                                      BorderRadius.circular(btnBorderRadius),
                                ),
                                padding: btnPadding,
                                alignment: Alignment.center,
                                child: Text(
                                  confirmTitle,
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.white),
                                ),
                              ),
                            ))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
    return res != null && res ? houseController.text : null;
  }

  /// 显示一个输入框的弹框 带确认、取消按钮
  /// 返回值为bool  正常点击确认按钮返回 true,点击背景遮罩或者滑动退出返回null
  static Future<String?> showInputDialog(BuildContext context,
      {String title = "温馨提示",
      String placeholderText = "请输入内容",
      String confirmTitle = "确认",
      TextInputFormatter? inputFormatter,
      int maxLines = 1}) async {
    TextEditingController houseController = TextEditingController();
    final res = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) =>
          StatefulBuilder(builder: (buildContext, childState) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.2),
            body: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * .7,
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(5, 5, 5, 0),
                      height: MediaQuery.of(context).size.width * .3,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(width: .5, color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        keyboardAppearance: Brightness.light,
                        textAlign: TextAlign.left,
                        controller: houseController,
                        maxLines: maxLines,
                        autofocus: true,
                        inputFormatters:
                            inputFormatter != null ? [inputFormatter] : [],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: placeholderText,
                          hintStyle: TextStyle(
                              color: Color.fromRGBO(188, 187, 187, 1),
                              fontSize: 14),
                        ),
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            highlightColor: Colors.white,
                            splashColor: Colors.white,
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(btnBorderRadius),
                              ),
                              padding: btnPadding,
                              alignment: Alignment.center,
                              child: const Text(
                                "取消",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: GestureDetector(
                          onTap: () async {
                            if (houseController.text.isEmpty) {
                              ToastUtil.showFailMsg(placeholderText);
                              return;
                            }
                            Navigator.of(context).pop(true);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColor.mainColor,
                              borderRadius:
                                  BorderRadius.circular(btnBorderRadius),
                            ),
                            padding: btnPadding,
                            alignment: Alignment.center,
                            child: Text(
                              confirmTitle,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ),
                        ))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
    return res != null && res ? houseController.text : null;
  }

  /// 精细化管理新增自建分类弹框
  /// 返回值为bool  正常点击确认按钮返回 true,点击背景遮罩或者滑动退出返回null
  static Future<Map<String, dynamic>?> showAddCateInputDialog(
      BuildContext context,
      {String title = "温馨提示",
      String placeholderText = "请输入内容",
      String confirmTitle = "确认",
      TextInputFormatter? inputFormatter,
      int maxLines = 6}) async {
    TextEditingController houseController = TextEditingController();
    TextEditingController markController = TextEditingController();
    final res = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) =>
          StatefulBuilder(builder: (buildContext, childState) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.2),
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * .8,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary,
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(5, 5, 5, 0),
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(width: .5, color: Colors.grey[300]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      keyboardAppearance: Brightness.light,
                      textAlign: TextAlign.left,
                      autofocus: true,
                      controller: houseController,
                      inputFormatters:
                          inputFormatter != null ? [inputFormatter] : [],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: placeholderText,
                        hintStyle: TextStyle(
                            color: Color.fromRGBO(188, 187, 187, 1),
                            fontSize: 14),
                      ),
                      style:
                          TextStyle(color: AppColor.textPrimary, fontSize: 14),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(5, 5, 5, 0),
                    height: MediaQuery.of(context).size.width * .2,
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: .5, color: Colors.grey[300]!)),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      keyboardAppearance: Brightness.light,
                      textAlign: TextAlign.left,
                      controller: markController,
                      maxLines: maxLines,
                      inputFormatters:
                          inputFormatter != null ? [inputFormatter] : [],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '请输入备注',
                        hintStyle: TextStyle(
                            color: Color.fromRGBO(188, 187, 187, 1),
                            fontSize: 14),
                      ),
                      style:
                          TextStyle(color: AppColor.textPrimary, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          highlightColor: Colors.white,
                          splashColor: Colors.white,
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius:
                                  BorderRadius.circular(btnBorderRadius),
                            ),
                            padding: btnPadding,
                            alignment: Alignment.center,
                            child: const Text(
                              "取消",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: GestureDetector(
                        onTap: () async {
                          if (houseController.text.isEmpty) {
                            ToastUtil.showFailMsg(placeholderText);
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.mainColor,
                            borderRadius:
                                BorderRadius.circular(btnBorderRadius),
                          ),
                          padding: btnPadding,
                          alignment: Alignment.center,
                          child: Text(
                            confirmTitle,
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ))
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
    return res != null && res
        ? {'title': houseController.text, 'remark': markController.text}
        : null;
  }

  /// 显示自定义弹框
  /// [context] 上下文对象
  /// [child]   自定义的widget
  ///  可选参数
  /// [barrierDismissible] 遮罩背景点击是否关闭弹框 默认为false
  /// [barrierColor]       遮罩背景颜色 默认黑色半透明  0x80000000
  /// [popDismissible]    是否可以滑动关闭弹框 默认为true
  ///
  static Future<bool> showCustomDialog(
    BuildContext context,
    Widget child, {
    bool barrierDismissible = false,
    Color barrierColor = const Color(0x80000000),
    bool popDismissible = true,
  }) async {
    _isShowing = true;
    bool? res = await showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          onWillPop: () async {
            return popDismissible;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                ],
              ),
            ),
          ),
        );
      },
      // 自定义转场效果
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0,
            end: 1,
          ).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 1,
              end: 0,
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
    );
    _isShowing = false;
    return res ?? false;
  }

  /// 显示自定义弹框2 指定返回类型
  /// [context] 上下文对象
  /// [child]   自定义的widget
  ///  可选参数
  /// [barrierDismissible] 遮罩背景点击是否关闭弹框 默认为false
  /// [barrierColor]       遮罩背景颜色 默认黑色半透明  0x80000000
  /// [popDismissible]    是否可以滑动关闭弹框 默认为true
  ///
  static Future<T> showCustomDialog1<T>(
    BuildContext context,
    Widget child, {
    bool barrierDismissible = false,
    Color barrierColor = const Color(0x80000000),
    bool popDismissible = true,
    bool clickPop = false,
  }) async {
    _isShowing = true;
    T? res = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          onWillPop: () async {
            return popDismissible;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (clickPop) Navigator.of(context).pop();
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                ],
              ),
            ),
          ),
        );
      },
      // 自定义转场效果
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0,
            end: 1,
          ).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 1,
              end: 0,
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
    );
    _isShowing = false;
    return Future.value(res);
  }

  /// 显示推荐好房弹框
  static Future<String?> showRecommendHouseDialog(labels, text, context) async {
    TextEditingController messageController = TextEditingController();
    var temp;
    if (text != null) {
      messageController.text = text;
    } else {
      if (labels != null) {
        String? result;
        labels.forEach((string) => {
              if (result == null)
                result = string
              else
                result = '$result，$string'
            });
        messageController.text = '为大家推荐好房：' + result.toString();
        temp = '为大家推荐好房：' + result.toString();
      } else {
        temp = '为大家推荐好房';
      }
    }
    final res = await showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '推荐理由',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColor.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: .5,
                          color: AppColor.E8E7E7,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              constraints: const BoxConstraints(minHeight: 100),
                              child: TextField(
                                autofocus: true,
                                textAlign: TextAlign.left,
                                keyboardAppearance: Brightness.light,
                                controller: messageController,
                                maxLines: 5,
                                minLines: 1,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '输入推荐内容？',
                                  hintStyle: const TextStyle(
                                    fontSize: 14,
                                    color: AppColor.c9c9c9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Flexible(
                              child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(6),
                                ),
                                border: Border.all(
                                    color: AppColor.subTitle666, width: 0.67),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '取消',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColor.subTitle666,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(width: 13),
                          Flexible(
                              child: GestureDetector(
                            onTap: () {
                              if (messageController.text != '') {
                                Navigator.of(context)
                                    .pop(messageController.text);
                              } else {
                                Navigator.of(context).pop(temp);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(6),
                                ),
                                color: AppColor.mainColor,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '提交',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return res;
  }


  ///权限申请 辅助提示弹框
  static Future<String?> showPermissionHintDialog(context,
      {String? title, required String desc}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 500),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, _, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              child: Card(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    SizedBox(
                      height: 28,
                      child: ListTile(
                        minVerticalPadding: 0,
                        title: Text(title ?? '权限使用说明:'),
                        onTap: () => Navigator.of(context).pop('item1'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      minVerticalPadding: 0,
                      title: Text(
                        desc,
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop('desc'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ).drive(Tween<Offset>(
            begin: Offset(0, -1.0),
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  /// 显示日期选择模态框
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    DateTime? initialDateTime,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) async {
    DateTime? selDateTime;
    final dateTime = await showCupertinoModalPopup<DateTime?>(
      context: context,
      builder: (BuildContext context) => Material(
        child: Container(
          height: 260,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text(
                        '取消',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.red,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '请选择日期',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColor.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(selDateTime),
                      child: const Text(
                        '确定',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColor.mainColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    initialDateTime: initialDateTime ?? DateTime.now(),
                    mode: CupertinoDatePickerMode.date,
                    use24hFormat: true,
                    showDayOfWeek: false,
                    maximumDate: maximumDate,
                    minimumDate: minimumDate,
                    onDateTimeChanged: (DateTime newDate) {
                      selDateTime = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return dateTime;
  }

  
  /// 通用底部弹出模态框
  /// [context] context 实例
  /// [title] 弹框标题
  /// [menus] 菜单列表
  /// [onTap] 菜单点击事件
  /// [menuHeight] 单个菜单高度 默认42
  /// [titleStyle] 标题文字样式
  /// [menuTextStyle] 菜单文字样式
  /// [cancleStyle] 取消文字样式
  static FutureOr<T?> showBottomModalDialog<T>({
    required BuildContext context,
    required String title,
    required List<String> menus,
    Function(int index)? onTap,
    double menuHeight = 42,
    TextStyle titleStyle = const TextStyle(
      fontSize: 15,
      color: AppColor.subTitle999,
      fontWeight: FontWeight.w500,
    ),
    TextStyle menuTextStyle = const TextStyle(
      fontSize: 14,
      color: AppColor.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    TextStyle cancleStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColor.red,
    ),
  }) async {
    List<Widget> widgets = [];
    for (var i = 0; i < menus.length; i++) {
      widgets.add(
        SizedBox(
          height: menuHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              Navigator.of(context).pop(i);
              if (onTap != null) onTap(i);
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  border: Border(
                bottom: i != menus.length - 1
                    ? BorderSide(
                        width: 0.33,
                        color: Color(0xffE8E7E7),
                      )
                    : BorderSide.none,
              )),
              alignment: Alignment.center,
              child: Text(
                menus[i],
                style: menuTextStyle,
              ),
            ),
          ),
        ),
      );
    }
    return await showCupertinoModalPopup(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: SizedBox(
              height:
                  min(menuHeight * menus.length + 152, AppUtils.screenH * 0.8),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              '$title',
                              style: titleStyle,
                            ),
                          ),
                          Divider(height: 0.33, color: Color(0xffE8E7E7)),
                          Expanded(
                            child: SizedBox(
                              height: min(menuHeight * menus.length,
                                  AppUtils.screenH * 0.8),
                              child: SingleChildScrollView(child: Column(children: widgets)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      width: double.infinity,
                      height: menuHeight,
                      child: Center(
                        child: Text(
                          '取消',
                          style: cancleStyle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
  }


  /// 显示一个信息提示框 带一个确定按钮
  static Future<T?> showDialogHint<T>(
    context, {
    String title = '温馨提示',
    Color? titleColor,
    String btnText = '确定',
  }) async {
    return await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Material(
            color: Colors.black.withOpacity(0.3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppUtils.screenW * 0.1),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 10, right: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info,
                                        size: 18,
                                        color: titleColor ??
                                            Color.fromRGBO(255, 165, 22, 1),
                                      ),
                                      Flexible(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: titleColor ??
                                                  Color.fromRGBO(
                                                      255, 165, 22, 1),
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(true),
                              child: Container(
                                margin: EdgeInsets.only(top: 22),
                                width: AppUtils.screenW * 0.45,
                                padding: btnPadding,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(btnBorderRadius),
                                  color: Color.fromRGBO(255, 165, 22, 1)
                                      .withOpacity(0.8),
                                ),
                                child: Text(
                                  btnText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
