import 'dart:io';

import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/widget/image_preview_dot_indicator.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 图片预览组件
/// [images] 图片数组：内部元素可以是： 网络地址、本地文件地址、本地项目图片资源地址
/// [index]  默认显示图片下标
/// [showDownloadBtn] 是否显示下载按钮
class ImagePreviewWidget extends StatefulWidget {
  final List<String> images;
  final int index;
  const ImagePreviewWidget(
      {Key? key, required this.images, required this.index})
      : super(key: key);

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  late PageController _pageController;

  int _current = 0;

  @override
  void initState() {
    _current = widget.index;
    _pageController = PageController(initialPage: widget.index);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding:  EdgeInsets.only(top: AppUtils.safeAreapadding.top + 12),
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  var imageProvider;
                  if (widget.images[index].startsWith('https://') ||
                      widget.images[index].startsWith('http://')) {
                    // 网络地址
                    imageProvider = NetworkImage(widget.images[index]);
                  } else {
                    final file = File(widget.images[index]);
                    if (file.existsSync()) {
                      // 本地文件地址
                      imageProvider = FileImage(file);
                    } else {
                      // 项目资源地址
                      imageProvider = AssetImage(widget.images[index]);
                    }
                  }
                  return PhotoViewGalleryPageOptions(
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 5,
                    heroAttributes: PhotoViewHeroAttributes(tag: "$index"),
                    imageProvider: imageProvider,
                  );
                },
                itemCount: widget.images.length,
                loadingBuilder: (context, event) => Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                    ),
                  ),
                ),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: AppUtils.safeAreapadding.bottom + 12, top: 12),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: ImagePreviewDotIndicator(
                count: widget.images.length,
                currentItem: _current,
                images: widget.images,
                unselectedColor: Colors.white,
                selectedColor: Colors.blue,
                size:  const Size(54, 54),
                unselectedSize:  const Size(54, 54),
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                fadeEdges: true,
                tap: (index) {
                  _pageController.animateToPage(index,duration: const Duration(milliseconds: 200),curve: Curves.linear);
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
