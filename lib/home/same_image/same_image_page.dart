import 'dart:async';
import 'dart:io';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/main.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';

class SameImagePage extends StatefulWidget {
  const SameImagePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SameImagePageState createState() => _SameImagePageState();
}

class _SameImagePageState extends State<SameImagePage> {
  List<IsolateAssetMessage> samePhotos = [];
  StreamSubscription? streamSubscription;
  @override
  void initState() {
    super.initState();
    samePhotos = PhotoManagerTool.sameImageEntity;
    streamSubscription = globalStreamControler.stream.listen((event) {
      setState(() {
        samePhotos = PhotoManagerTool.sameImageEntity;
      });
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgW = AppUtils.screenW / 4;
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Image.asset(
              'assets/images/common/back.png',
            ),
          ),
        ),
        title: Text(
          AppUtils.i18Translate('home.samePhoto'),
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
              itemCount: samePhotos.length,
              itemBuilder: (context, index) {
                final assets = samePhotos[index];
                return Stack(
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

  Future<String?> _loadImageSize(IsolateAssetMessage asset) async {
    if (asset.fileSize != null) {
      return AppUtils.fileSizeFormat(asset.fileSize!);
    }
    final orignalFilePath = asset.orignalFilePath;
    if (orignalFilePath != null) {
      final length = await File(orignalFilePath).length();
      asset.fileSize = length;
      return AppUtils.fileSizeFormat(length);
    } else {
      return '0B';
    }
  }
}
