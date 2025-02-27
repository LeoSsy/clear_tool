import 'dart:math';
import 'dart:typed_data';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// 图片预览组件
/// [images] 图片数组：List<ImageAsset>
/// [index]  默认显示图片下标
/// [showDownloadBtn] 是否显示下载按钮
class ImagePreviewWidget extends StatefulWidget {
  final List<ImageAsset> images;
  final int index;
  const ImagePreviewWidget(
      {Key? key, required this.images, required this.index})
      : super(key: key);

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  late ExtendedPageController _pageController;
  late ScrollController _scrollController;
  int _current = 0;
  double itemW = 70;
  double margin = 4;
  List<ImageAsset> datas = [];
  Map<String, Uint8List?> originBytesMap = {};
  Map<String, Uint8List?> listOriginBytesMap = {};
  Map<String, Size?> orginImageSize = {};

  @override
  void initState() {
    _current = widget.index;
    _pageController = ExtendedPageController(initialPage: widget.index);
    _pageController.addListener(() {
      _pageViewAndListViewOffsetSync();
    });
    _scrollController = ScrollController();
    datas = widget.images;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageViewAndListViewOffsetSync();
    });
    loadAssetBytes();
    super.initState();
  }

  /// 加载指定的图片数据
  void loadAssetBytes() async {
    await _loadOriginBytes(datas[_current]);
    if (mounted) setState(() {});
  }

  /// 加载前后图片
  void loadLRImageData() async {
    const count = 2;
    if (originBytesMap.keys.toList().length >= 10) {
      /// 清理最前面的图片
      for (var i = 0; i < count * 2; i++) {
        originBytesMap.remove(originBytesMap.keys.toList()[i]);
      }
    }
    final start = max(_current - count, 0);
    final end = min(_current + count, datas.length);
    final tempList = datas.sublist(start, end);
    for (var asset in tempList) {
      if (originBytesMap[asset.assetEntity.id] != null) {
        continue;
      }
      await _loadOriginBytes(asset);
      if (mounted) setState(() {});
    }
  }

  /// 对pageview 和 listview偏移同步
  _pageViewAndListViewOffsetSync() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_pageController.hasClients) {
        // 获取pageview 最大偏移量
        final pageMaxOffset = _pageController.position.maxScrollExtent;
        // 获取listview 最大偏移量
        final listMaxOffset = _scrollController.position.maxScrollExtent;
        // 计算比例
        final ratio = listMaxOffset / pageMaxOffset;
        // 设置listview偏移量 根据pageview 比例计算
        _scrollController.jumpTo(_pageController.offset * ratio);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ExtendedImageGesturePageView.builder(
                controller: _pageController,
                itemCount: datas.length,
                onPageChanged: (index) {
                  setState(() {
                    _current = index;
                  });
                  loadLRImageData();
                },
                itemBuilder: (context, index) {
                  final asset = datas[index];
                  return originBytesMap[asset.assetEntity.id] != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ExtendedImage.memory(
                            originBytesMap[asset.assetEntity.id]!,
                            mode: ExtendedImageMode.gesture,
                            initGestureConfigHandler: (state) {
                              return GestureConfig(
                                minScale: 0.9,
                                animationMinScale: 0.7,
                                maxScale: 3.0,
                                animationMaxScale: 3.5,
                                speed: 1.0,
                                inertialSpeed: 100.0,
                                initialScale: 1.0,
                                inPageView: true,
                                initialAlignment: InitialAlignment.center,
                              );
                            },
                            loadStateChanged: (state) {
                              if (state.extendedImageLoadState ==
                                  LoadState.loading) {
                                return const Center(
                                  child: CupertinoActivityIndicator(
                                    radius: 16,
                                    color: AppColor.mainColor,
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        )
                      : const Center(
                          child: CupertinoActivityIndicator(
                            radius: 16,
                            color: AppColor.mainColor,
                          ),
                        );
                }),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: AppUtils.safeAreapadding.bottom,
            top: 12,
            left: 12,
            right: 12,
          ),
          child: SizedBox(
              height: 90,
              child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 1.0,
                  ),
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  itemCount: datas.length,
                  itemBuilder: (context, index) {
                    final assets = datas[index];
                    return SizedBox(
                      width: 90,
                      height: 90,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _pageController.animateToPage(index,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.linear);
                          loadAssetBytes();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: index == _current
                                ? Border.all(
                                    color: AppColor.mainColor, width: 4)
                                : null,
                          ),
                          width: itemW,
                          height: itemW,
                          margin: const EdgeInsets.only(right: 6),
                          child: listOriginBytesMap[assets.assetEntity.id] !=
                                  null
                              ? ExtendedImage.memory(
                                  listOriginBytesMap[assets.assetEntity.id]!,
                                  fit: BoxFit.cover,
                                )
                              : FutureBuilder(
                                  future: _loadListOriginBytes(assets),
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      return ExtendedImage.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      return const Center(
                                        child: CupertinoActivityIndicator(
                                          radius: 16,
                                          color: AppColor.mainColor,
                                        ),
                                      );
                                    }
                                  }),
                        ),
                      ),
                    );
                  })),
        ),
      ],
    );
  }

  // 计算等比例宽高
  Size _getImageSize(ImageAsset asset) {
    if (orginImageSize[asset.assetEntity.id] != null) {
      return orginImageSize[asset.assetEntity.id]!;
    }
    final imageShowW = AppUtils.screenW;
    final imageShowH = AppUtils.screenH -
        (AppUtils.safeAreapadding.bottom +
            12 +
            90 +
            AppUtils.safeAreapadding.top +
            50);
    final originW = asset.assetEntity.width;
    final originH = asset.assetEntity.height;
    final resultW = imageShowW * originH / imageShowH;
    final resultH = imageShowH * originW / imageShowW;
    orginImageSize[asset.assetEntity.id] = Size(resultW, resultH);
    return Size(resultW, resultH);
  }

  Future<Uint8List?> _loadOriginBytes(ImageAsset asset) async {
    final resultSize = _getImageSize(asset);
    final thumbnailData = await asset.assetEntity.thumbnailDataWithSize(
      ThumbnailSize(
        (resultSize.width).toInt(),
        (resultSize.height).toInt(),
      ),
    );
    if (thumbnailData != null) {
      originBytesMap[asset.assetEntity.id] = thumbnailData;
      return thumbnailData;
    } else {
      return null;
    }
  }

  Future<Uint8List?> _loadListOriginBytes(ImageAsset asset) async {
    final thumbnailData = await asset.assetEntity
        .thumbnailDataWithSize(const ThumbnailSize(90, 90));
    if (thumbnailData != null) {
      listOriginBytesMap[asset.assetEntity.id] = thumbnailData;
      return thumbnailData;
    } else {
      return null;
    }
  }
}
