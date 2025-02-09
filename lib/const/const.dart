import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

const double maxImageMB = 5;

const int imgUnitOfAccount = 1000;

class ImageAsset {
  final AssetEntity assetEntity;
  bool selected = false;
  int length = 0;
  String? fileSize;
  Uint8List? bytes;
  ImageAsset(this.assetEntity);
}

/// 线程之间通信数据
class IsolateAssetMessage {
  String? id;
  String? path;
  String? orignalFilePath;
  Uint8List? thumnailBytes;
  int orientation = 0;
  int width = 0;
  int height = 0;
  int duration = 0;
  bool isFavorite = false;
  String? title;
  int? createDateSecond;
  int? modifiedDateSecond;
  double? latitude;
  double? longitude;
  String? mimeType;
  bool isLivePhoto = false;

  /// 辅助属性
  bool selected = false;
  int? fileSize;

  IsolateAssetMessage({
    this.id,
    this.path,
    this.orignalFilePath,
    this.thumnailBytes,
    this.title,
    this.createDateSecond,
    this.modifiedDateSecond,
    this.latitude,
    this.longitude,
    this.mimeType,
    this.isLivePhoto = false,
    this.orientation = 0,
    this.width = 0,
    this.height = 0,
    this.isFavorite = false,
    this.duration = 0,
  });

  IsolateAssetMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    path = json['path'];
    orignalFilePath = json['orignalFilePath'];
    thumnailBytes = json['thumnailBytes'];
    orientation = json['orientation'];
    width = json['width'];
    height = json['height'];
    duration = json['duration'];
    isFavorite = json['isFavorite'];
    title = json['title'];
    createDateSecond = json['createDateSecond'];
    modifiedDateSecond = json['modifiedDateSecond'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    mimeType = json['mimeType'];
    isLivePhoto = json['isLivePhoto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['path'] = path;
    data['orignalFilePath'] = orignalFilePath;
    data['thumnailBytes'] = thumnailBytes;
    data['orientation'] = orientation;
    data['width'] = width;
    data['height'] = height;
    data['duration'] = duration;
    data['isFavorite'] = isFavorite;
    data['title'] = title;
    data['createDateSecond'] = createDateSecond;
    data['modifiedDateSecond'] = modifiedDateSecond;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['mimeType'] = mimeType;
    data['isLivePhoto'] = isLivePhoto;
    return data;
  }
}
