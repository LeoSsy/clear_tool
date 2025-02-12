import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/tabbar/tabbar_screen.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/image_hash_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

// RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
StreamController globalStreamControler = StreamController.broadcast();
ReceivePort globalPort = ReceivePort();

FlutterIsolate? bigPhotoIsolate;
FlutterIsolate? screenshotPhotoIsolate;

@pragma('vm:entry-point')
void spawnBigPhotosIsolate(SendPort port) async {
  PhotoManagerTool.allPhotoAssets = [];
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  // 获取所有图片资源对象
  int bigPhotoSize = 0;
  for (var album in assetPaths) {
    final count = await album.assetCountAsync;
    if (count == 0) {
      break;
    }
    final assetItems = await album.getAssetListRange(start: 0, end: count);
    for (var asset in assetItems) {
      final originalFile = await asset.file;
      if (originalFile != null) {
        final length = await originalFile.length();
        final size = AppUtils.fileSizeFormat(length);
        if (size.contains("MB")) {
          final mbSize = double.tryParse(size.replaceAll("MB", '')) ?? 0;
          if (mbSize > maxImageMB) {
            bigPhotoSize += length;
            port.send({
              "event": "BigPhotoEvent",
              "data": asset.id,
              'size': bigPhotoSize
            });
          }
        }
      }
    }
    break;
  }
}

@pragma('vm:entry-point')
void spawnScreenshotIsolate(SendPort port) async {
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  List<AssetEntity> photoAssets = <AssetEntity>[];
  // 获取所有图片资源对象
  for (var album in assetPaths) {
    if (album.name == 'Screenshots') {
      final count = await album.assetCountAsync;
      if (count > 0) {
        final screenshotAssets =
            await album.getAssetListRange(start: 0, end: count);
        photoAssets.addAll(screenshotAssets);
      }
      break;
    }
  }
  int totalSize = 0;
  for (var asset in photoAssets) {
    final originalFile = await asset.file;
    if (originalFile != null) {
      final length = await originalFile.length();
      totalSize += length;
      port.send({
        "event": "screenshotEvent",
        "data": asset.id,
        'size': totalSize,
      });
    }
  }
}

Map<String, String> hashs = {};

@pragma('vm:entry-point')
void spawnSamePhotosIsolate(SendPort port) async {
  // 获取所有图片资源对象
  Map<String, AssetEntity> hashs = {};
    PhotoManagerTool.allPhotoAssets = [];
    final assetPaths =
        await PhotoManager.getAssetPathList(type: RequestType.image);
    int allCount = 0;
    int afterCmpNum = 11;
    if (assetPaths.isNotEmpty) {
      for (var album in assetPaths) {
        int count = await album.assetCountAsync;
        if (count == 0) continue;
        final assetItems = await album.getAssetListRange(start: 0, end: count);
        for (var i = 0; i < assetItems.length; i++) {
          final asset = assetItems[i];
          final bytes = await asset.thumbnailData;
          if (bytes != null) {
            final hash =
                ImageHashUtil.calculateAverageHash(img.decodeImage(bytes)!);
            hashs[hash] = asset;
            print('hash.....$hash');
          }
          // final currentImage = await assetItems[i].file;
          // int afterIndex = 1;
          // final groupIds = <String>[];
          // while (afterIndex < afterCmpNum &&
          //     (i + afterIndex) < assetItems.length) {
          //   final nextImage = await assetItems[i + afterIndex].file;
          //   final similary =
          //       await compareImages(src1: currentImage, src2: nextImage);
          //   if (similary < 0.5) {
          //     print('找到相似图片.....');
          //     // 添加组
          //     if (groupIds.isEmpty) {
          //       groupIds.add(assetItems[i].id);
          //     }
          //     groupIds.add(assetItems[i + afterIndex].id);
          //   }
          //   afterIndex++;
          // }
          // port.send({
          //   "event": "sameEvent",
          //   "data": SamePhotoGroup(
          //           id: assetItems[i].id,
          //           title: '${groupIds.length}',
          //           ids: groupIds)
          //       .toJson(),
          // });
        }
      }
    }
    for (var i = 0; i < hashs.length; i++) {
      final groupIds = <String>[];
      final currentHash = hashs.keys.toList()[i];
      bool isFindSame = false;
      for (var j = 0; j < hashs.length; j++) {
        final nextHash = hashs.keys.toList()[j];
        if (hashs[currentHash]!.id == hashs[nextHash]!.id) {
          continue;
        }
        // final distance =
        //     ImageHashUtil.calculateHammingDistance(currentHash, nextHash);
        final distance = ImageHashUtil.compareHashes(currentHash, nextHash);
        print('distance.....$distance');
        if (distance > 0.85) {
          isFindSame = true;
          print('找到相似图片.....');
          print('找到相似图片.....');
          //   // 添加组
          if (groupIds.isEmpty) {
            groupIds.add(hashs[currentHash]!.id);
            groupIds.add(hashs[nextHash]!.id);
          }
        }
      }
      if (isFindSame) {
        port.send({
          "event": "sameEvent",
          "data": SamePhotoGroup(
                  id: hashs[currentHash]!.id,
                  title: '${groupIds.length}',
                  ids: groupIds)
              .toJson(),
        });
      }

      // int afterIndex = i + 1;
      // final currentHash = hashs.keys.toList()[i];
      // final groupIds = <String>[];
      // int loop = 1;
      // while (loop < afterCmpNum) {
      //   if (i + loop < hashs.length) {
      //     final nextHash = hashs.keys.toList()[i + loop];
      //     final distance =
      //         ImageHashUtil.calculateHammingDistance(currentHash, nextHash);
      //     print('distance.....$distance');
      //     if (distance < 5) {
      //       print('找到相似图片.....');

      //     }
      //   }
      //   loop++;
      //   // final nextHash = hashs.keys.toList()[afterIndex];
      //   // final distance =
      //   //     ImageHashUtil.calculateHammingDistance(currentHash, nextHash);
      //   // print('distance.....$distance');
      //   // if (distance < 5) {
      //   //   print('找到相似图片.....');
      //   // }
      //   // final nextImage = await assetItems[i + afterIndex].file;
      //   // final similary =
      //   //     await compareImages(src1: currentImage, src2: nextImage);
      //   // if (similary < 0.5) {
      //   //   print('找到相似图片.....');
      //   //   // 添加组
      //   //   if (groupIds.isEmpty) {
      //   //     groupIds.add(assetItems[i].id);
      //   //   }
      //   //   groupIds.add(assetItems[i + afterIndex].id);
      //   // }
      // }
  }
}

void main() async {
  final FlutterI18nDelegate flutterI18nDelegate = FlutterI18nDelegate(
    translationLoader: NamespaceFileTranslationLoader(
      namespaces: ["common", "home"],
      useCountryCode: false,
      fallbackDir: 'en',
      basePath: 'assets/i18n',
      forcedLocale: const Locale('zh'),
    ),
    missingTranslationHandler: (key, locale) {
      // ignore: avoid_print
      print("--- Missing Key: $key, languageCode: ${locale!.languageCode}");
    },
  );
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    SystemUiOverlayStyle style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(style);
  }
  globalPort.listen((data) {
    // 监听子线程发送的数据
    if (data['event'] == "sameEvent") {
      globalStreamControler
          .add(SamePhotoEvent(SamePhotoGroup.fromJson(data['data'])));
    } else if (data['event'] == "BigPhotoEvent") {
      globalStreamControler.add(BigPhotoEvent(data['data'], data['size']));
    } else if (data['event'] == "screenshotEvent") {
      globalStreamControler.add(ScreenPhotoEvent(data['data'], data['size']));
    } else if (data['event'] == "refresh") {
      globalStreamControler.add(RefreshEvent());
    } else if (data['event'] == "test") {
      hashs = data['data'];
      globalStreamControler.add(RefreshEvent());
    }
    // print("Received message from isolate $data");
  }, onError: (err) {
    print("Received message from isolate $err");
  });
  // loadAllPhotosIsolate();
  runApp(MyApp(
    flutterI18nDelegate: flutterI18nDelegate,
  ));
}

class MyApp extends StatelessWidget {
  final FlutterI18nDelegate flutterI18nDelegate;
  const MyApp({super.key, required this.flutterI18nDelegate});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: getMaterialColor(AppColor.mainColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColor.mainColor,
        ),
        brightness: Brightness.light,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
            TargetPlatform.values,
            value: (dynamic _) => const CupertinoPageTransitionsBuilder(),
          ),
        ),
      ),
      home: const TabbarScreen(),
      localizationsDelegates: [
        flutterI18nDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }

  MaterialColor getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;
    final int alpha = color.alpha;

    final Map<int, Color> shades = {
      50: Color.fromARGB(alpha, red, green, blue),
      100: Color.fromARGB(alpha, red, green, blue),
      200: Color.fromARGB(alpha, red, green, blue),
      300: Color.fromARGB(alpha, red, green, blue),
      400: Color.fromARGB(alpha, red, green, blue),
      500: Color.fromARGB(alpha, red, green, blue),
      600: Color.fromARGB(alpha, red, green, blue),
      700: Color.fromARGB(alpha, red, green, blue),
      800: Color.fromARGB(alpha, red, green, blue),
      900: Color.fromARGB(alpha, red, green, blue),
    };

    return MaterialColor(color.value, shades);
  }
}
