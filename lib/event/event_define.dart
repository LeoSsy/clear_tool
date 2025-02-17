import 'package:clear_tool/const/const.dart';

class SamePhotoEvent {
  final SamePhotoGroup? group;
  SamePhotoEvent(this.group);
}

class SamePhotoDeleteEvent {
  final List<String> ids;
  final int deleteTotalSize;
  SamePhotoDeleteEvent(this.ids, this.deleteTotalSize);
}

/// 大图event
class BigPhotoEvent {
  final String? id;
  final int totalSize;
  BigPhotoEvent(this.id, this.totalSize);
}

class BigPhotoDeleteEvent {
  final List<String> ids;
  final int deleteTotalSize;
  BigPhotoDeleteEvent(this.ids, this.deleteTotalSize);
}

/// 二级页面监听
class SubBigPhotoEvent {
  final List<ImageAsset> assets;
  final int totalSize;
  SubBigPhotoEvent(this.assets, this.totalSize);
}

/// 截图event
class ScreenPhotoEvent {
  final String? id;
  final int totalSize;
  ScreenPhotoEvent(this.id, this.totalSize);
}

class ScreenPhotoDeleteEvent {
  final List<String> ids;
  final int deleteTotalSize;
  ScreenPhotoDeleteEvent(this.ids, this.deleteTotalSize);
}

/// 二级页面监听
class SubScreenPhotoEvent {
  final List<ImageAsset> assets;
  final int totalSize;
  SubScreenPhotoEvent(this.assets, this.totalSize);
}

class RefreshEvent {}

class AllPhotoLoadFinishEvent {}

class TaskProgressEvent {
  final String type;
  final double progress;
  TaskProgressEvent({required this.type, required this.progress});
}
