

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