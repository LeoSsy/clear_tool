import 'dart:io';
import 'dart:typed_data';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
  late PageController _pageController;
  late ScrollController _scrollController;

  int _current = 0;
  double itemW = 70;
  double margin = 4;

  int pageSize = 10;
  int currentPage = 0;
  int totalPage = 0;

  List<List<ImageAsset>> pages = [];

  @override
  void initState() {
    _current = widget.index;
    _pageController = PageController(initialPage: widget.index);
    _pageController.addListener(() {
      _pageViewAndListViewOffsetSync();
    });
    _scrollController = ScrollController();
    _pageViewAndListViewOffsetSync();
    super.initState();
  }

  // subList(){
  //   totalPage = (widget.images.length/pageSize).ceil();
  //   int currentPage = 0;
  //   List<List<int>>pageRanges = [];
  //   while (currentPage < totalPage) {
  //     final subList = widget.images.sublist(currentPage,pageSize);
  //     pages.add(subList);
  //     pageRanges.add([currentPage,currentPage+pageSize]);
  //     currentPage++;
  //   }
  //   // 判断当前传入index落入的区间

  // }

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
        if (_current <= 4000) {
          _scrollController.animateTo(_pageController.offset * ratio,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear);
        } else {
          _scrollController.animateTo(_pageController.offset * ratio,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$_current/${widget.images.length}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _current = index;
                });
              },
              itemBuilder: (context, index) {
                final asset = widget.images[index];
                return ExtendedImage.file(
                  File(asset.originalFilePath!),
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
                      inPageView: false,
                      initialAlignment: InitialAlignment.center,
                    );
                  },
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.loading) {
                      return const Center(
                        child: CupertinoActivityIndicator(
                          radius: 16,
                          color: AppColor.mainColor,
                        ),
                      );
                    }
                    return null;
                  },
                );
              },
            ),
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
            child: ListView.builder(
              shrinkWrap: true,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final assets = widget.images[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _pageController.jumpToPage(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: index == _current
                          ? Border.all(color: AppColor.mainColor, width: 4)
                          : null,
                    ),
                    width: itemW,
                    height: itemW,
                    margin: const EdgeInsets.only(right: 6),
                    child: ExtendedImage.memory(
                      assets.thumnailBytes!,
                      fit: BoxFit.fitWidth,
                      loadStateChanged: (state) {
                        if (state.extendedImageLoadState == LoadState.loading) {
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
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<Uint8List?> _loadOriginBytes(ImageAsset asset) async {
    final thumbnailData = await asset.assetEntity.thumbnailDataWithSize(
        ThumbnailSize(AppUtils.screenW.toInt(), AppUtils.screenH.toInt()));
    if (thumbnailData != null) {
      asset.originBytes = thumbnailData;
      return thumbnailData;
    } else {
      return null;
    }
  }
}
