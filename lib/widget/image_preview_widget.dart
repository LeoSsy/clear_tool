import 'dart:io';
import 'dart:typed_data';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/widget/preview_dot_indicator.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    _current = widget.index;
    _pageController = PageController(initialPage: widget.index);
    _scrollController = ScrollController();
    animationToOffset();
    super.initState();
  }

  animationToOffset() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_scrollController.hasClients) {
        if (_scrollController.offset <
            _scrollController.position.maxScrollExtent) {
          _scrollController.animateTo(_current * (itemW - 8),
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear);
        } else if (_current < widget.images.length - 4) {
          _scrollController.animateTo(_current * (itemW - 8),
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: AppUtils.safeAreapadding.top + 12),
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  final file = File(widget.images[index].originalFilePath!);
                  final imageProvider = FileImage(file);
                  return PhotoViewGalleryPageOptions(
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 5,
                    heroAttributes: PhotoViewHeroAttributes(tag: "$index"),
                    imageProvider: imageProvider,
                  );
                },
                itemCount: widget.images.length,
                loadingBuilder: (context, event) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                      radius: 24,
                      color: Colors.white,
                    ),
                  );
                },
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _current = index;
                  });
                  animationToOffset();
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: AppUtils.safeAreapadding.bottom,
              top: 12,
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadImage(ImageAsset asset) async {
    final originFile = await asset.assetEntity.originFile;
    if (originFile != null) {
      return originFile.readAsBytes();
    } else {
      return null;
    }
  }
}
