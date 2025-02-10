import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ScreenShotPage extends StatefulWidget {
  const ScreenShotPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ScreenShotPageState createState() => _ScreenShotPageState();
}

class _ScreenShotPageState extends State<ScreenShotPage> {
  List<ImageAsset> screenshots = [];

  @override
  void initState() {
    super.initState();
    fetchScreenShots();
  }

  fetchScreenShots() async {
    if (PhotoManagerTool.screenShotImageEntity.isNotEmpty) {
      screenshots = PhotoManagerTool.screenShotImageEntity;
    } else {
      final tempAssets = PhotoManagerTool.screenShotOrigineEntity;
      for (var asset in tempAssets) {
        final imageAsset = ImageAsset(asset);
        imageAsset.thumnailBytes = await asset.thumbnailData;
        final file = await asset.originFile;
        imageAsset.originalFilePath = file!.path;
        screenshots.add(imageAsset);
      }
      PhotoManagerTool.screenShotImageEntity = screenshots;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Image.asset(
              'assets/images/common/back.png',
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          AppUtils.i18Translate('home.screenshot', context: context),
          style: const TextStyle(fontSize: 18),
        ),
      ),
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
                return GestureDetector(
                  onTap: () {
                    AppUtils.showImagePreviewDialog(context, screenshots.map((e) => e.originalFilePath!).toList(),index);
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: assets.thumnailBytes != null
                            ? Image.memory(
                                assets.thumnailBytes!,
                                width: imgW,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/common/placeholder.png',
                                width: imgW,
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
                          child: assets.length > 0
                              ? Text(
                                  AppUtils.fileSizeFormat(assets.length),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                )
                              : FutureBuilder(
                                  future: _loadImageSize(assets),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.connectionState ==
                                              ConnectionState.done
                                          ? '${snapshot.data}'
                                          : '0KB',
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
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<String?> _loadImageSize(ImageAsset asset) async {
    final originFile = await asset.assetEntity.originFile;
    if (originFile != null) {
      asset.length = await originFile.length();
      return AppUtils.fileSizeFormat(asset.length);
    } else {
      return '0KB';
    }
  }
}
