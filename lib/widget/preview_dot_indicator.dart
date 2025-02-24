library page_view_dot_indicator;

import 'dart:io';

import 'package:clear_tool/const/const.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ImagePreviewDotIndicator extends StatefulWidget {
  /// Creates a PageViewDotIndicator widget.
  ///
  /// The [currentItem], [count], [unselectedColor] and [selectedColor]
  /// arguments must not be null.
  const ImagePreviewDotIndicator({
    Key? key,
    required this.currentItem,
    required this.count,
    required this.images,
    required this.unselectedColor,
    required this.selectedColor,
    this.size = const Size(12, 12),
    this.tap,
    this.unselectedSize = const Size(12, 12),
    this.duration = const Duration(milliseconds: 150),
    this.margin = const EdgeInsets.symmetric(horizontal: 4),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = Alignment.center,
    this.fadeEdges = true,
  })  : assert(
          currentItem >= 0 && currentItem < count,
          'Current item must be within the range of items. Make sure you are using 0-based indexing',
        ),
        super(key: key);

  /// The index of the currentItem. It is a 0-based index and cannot be
  /// neither greater or equal to count nor smaller than 0.
  final int currentItem;

  /// The total amount of dots. Usually it should be the same count of pages of
  /// the corresponding pageview).
  final int count;

  /// 所有图片资源
  final List<ImageAsset> images;

  /// 点击事件
  final ValueChanged? tap;

  /// The color applied to the dot when the dots' indexes are different from
  /// [currentItem].
  final Color unselectedColor;

  /// The color applied to the dot when the dots' index is the same as
  /// [currentItem].
  final Color selectedColor;

  /// The size of the dot corresponding to the [currentItem] or the default
  /// size of the dots when [unselectedSize] is null.
  final Size size;

  /// The size of the dots when the [currentItem] is different from the dots'
  /// indexes.
  final Size unselectedSize;

  /// The duration of the animations used by the dots when the [currentItem] is
  /// changed
  final Duration duration;

  /// The margin between the dots.
  final EdgeInsets margin;

  /// The external padding.
  final EdgeInsets padding;

  /// The alignment of the dots regarding the whole container.
  final Alignment alignment;

  /// If the edges should be faded or not.
  final bool fadeEdges;

  @override
  _ImagePreviewDotIndicatorState createState() =>
      _ImagePreviewDotIndicatorState();
}

class _ImagePreviewDotIndicatorState extends State<ImagePreviewDotIndicator> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      scrollToCurrentPosition();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ImagePreviewDotIndicator oldWidget) {
    scrollToCurrentPosition();
    super.didUpdateWidget(oldWidget);
  }

  void scrollToCurrentPosition() {
    final widgetOffset = _getOffsetForCurrentPosition();
    _scrollController
      ..animateTo(
        widgetOffset,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            widget.fadeEdges ? Color.fromARGB(0, 255, 255, 255) : Colors.white,
            Colors.white,
            Colors.white,
            widget.fadeEdges ? Color.fromARGB(0, 255, 255, 255) : Colors.white,
          ],
          tileMode: TileMode.mirror,
          stops: [0, 0.05, 0.95, 1],
        ).createShader(bounds);
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        alignment: widget.alignment,
        height: widget.size.height,
        child: ListView.builder(
          padding: widget.padding,
          // physics: NeverScrollableScrollPhysics(),
          itemCount: widget.count,
          controller: _scrollController,
          shrinkWrap: !_needsScrolling(),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.antiAlias,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              margin: widget.margin,
              duration: widget.duration,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: index == widget.currentItem
                    ? widget.selectedColor
                    : widget.unselectedColor,
              ),
              width: index == widget.currentItem
                  ? widget.size.width
                  : widget.unselectedSize.width,
              height: index == widget.currentItem
                  ? widget.size.height
                  : widget.unselectedSize.height,
              child: GestureDetector(
                onTap: (){
                  if(widget.tap != null){
                    widget.tap!(index);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ExtendedImage.file(File(widget.images[index].originalFilePath!)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getOffsetForCurrentPosition() {
    final offsetPerPosition =
        _scrollController.position.maxScrollExtent / widget.count;
    final widgetOffset = widget.currentItem * offsetPerPosition;
    return widgetOffset;
  }

  /// This is important to center the list items if they fit on screen by making
  /// the list shrinkWrap or to make the list more performatic and avoid
  /// rendering all dots at once, otherwise.
  bool _needsScrolling() {
    final viewportWidth = MediaQuery.of(context).size.width;
    final itemWidth =
        widget.unselectedSize.width + widget.margin.left + widget.margin.right;
    final selectedItemWidth =
        widget.size.width + widget.margin.left + widget.margin.right;
    final listViewPadding = 32;
    final shaderPadding = viewportWidth * 0.1;
    return viewportWidth <
        selectedItemWidth +
            (widget.count - 1) * itemWidth +
            listViewPadding +
            shaderPadding;
  }
}