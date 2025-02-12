import 'package:clear_tool/const/const.dart';

class SamePhotoEvent {
  final SamePhotoGroup group;
  SamePhotoEvent(this.group);
}


/// 大图event
class BigPhotoEvent {
  final String id;
  final int totalSize;
  BigPhotoEvent(this.id,this.totalSize);
}

/// 二级页面监听
class SubBigPhotoEvent {
  final List<ImageAsset> assets;
  final int totalSize;
  SubBigPhotoEvent(this.assets,this.totalSize);
}


/// 截图event
class ScreenPhotoEvent {
  final String id;
  final int totalSize;
  ScreenPhotoEvent(this.id,this.totalSize);
}

/// 二级页面监听
class SubScreenPhotoEvent {
  final List<ImageAsset> assets;
  final int totalSize;
  SubScreenPhotoEvent(this.assets,this.totalSize);
}


class RefreshEvent {
}


class AllPhotoLoadFinishEvent {
}
