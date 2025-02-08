import 'dart:async';

import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class BigImagePage extends StatefulWidget {
  const BigImagePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BigImagePageState createState() => _BigImagePageState();
}

class _BigImagePageState extends State<BigImagePage> {
  List<ImageAsset> screenshots = [];

  late Timer timer;

  @override
  void initState() {
    super.initState();
    fetchScreenShots();

    
    
  }

  fetchScreenShots() async {
    timer = Timer.periodic(const Duration(seconds: 2), (timer) { 
        final tempAsset = PhotoManagerTool.bigImageEntity;
        setState(() {
          screenshots = PhotoManagerTool.bigImageEntity.map((e) => ImageAsset(e)).toList();
        });
    });
    final tempAssets = await PhotoManagerTool.fetchBigImages();
    screenshots = tempAssets.map((e) => ImageAsset(e)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                final assets = screenshots[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FutureBuilder(
                        future: _loadImage(assets),
                        initialData: assets.bytes,
                        builder: (context, snapshot) {
                          if (assets.bytes != null) {
                            return Image.memory(
                              snapshot.data!,
                              width: imgW,
                              fit: BoxFit.cover,
                            );
                          } else if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.data != null) {
                              assets.bytes = snapshot.data;
                              return Image.memory(
                                snapshot.data!,
                                width: imgW,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Image.asset(
                                'assets/images/common/placeholder.png',
                                width: imgW,
                              );
                            }
                          } else {
                            return Image.asset(
                              'assets/images/common/placeholder.png',
                              width: imgW,
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            assets.selected = !assets.selected;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            assets.selected
                                ? 'assets/images/common/selected_sel.png'
                                : 'assets/images/common/selected_normal.png',
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        child: FutureBuilder(
                          future: _loadImageSize(assets),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.connectionState == ConnectionState.done
                                  ? '${snapshot.data}'
                                  : '0B',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<Uint8List?> _loadImage(ImageAsset asset) async {
    final imgW = AppUtils.screenW / 4;
    return await asset.assetEntity
        .thumbnailDataWithSize(ThumbnailSize(imgW.toInt(), imgW.toInt()));
  }

  Future<String?> _loadImageSize(ImageAsset asset) async {
    // if (asset.fileSize != null) {
    //   return asset.fileSize;
    // }
    final originBytes = await asset.assetEntity.originBytes;
    if (originBytes != null) {
      asset.length = originBytes.length;
      print(
          'size-----${(originBytes.length / imgUnitOfAccount / imgUnitOfAccount) * 1000}');
      if (originBytes.length /
              imgUnitOfAccount /
              imgUnitOfAccount /
              imgUnitOfAccount >
          1) {
        // MB
        asset.fileSize =
            '${((originBytes.length / imgUnitOfAccount / imgUnitOfAccount)).floorToDouble().toStringAsFixed(1)}MB';
      } else if (originBytes.length / imgUnitOfAccount / imgUnitOfAccount > 1) {
        // KB
        asset.fileSize =
            '${((originBytes.length / imgUnitOfAccount / imgUnitOfAccount) * 1000).floorToDouble().toStringAsFixed(1)}KB';
      } else if (originBytes.length / imgUnitOfAccount > 1) {
        // B
        asset.fileSize =
            '${(originBytes.length / imgUnitOfAccount).floorToDouble().toStringAsFixed(1)}B';
      } else {
        asset.fileSize =
            '${(originBytes.length).floorToDouble().toStringAsFixed(1)}B';
      }
      return asset.fileSize;
    } else {
      return '0B';
    }
  }
}
