import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/tabbar/tabbar_screen.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_compare_2/image_compare_2.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

// RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
StreamController globalStreamControler = StreamController.broadcast();
ReceivePort globalPort = ReceivePort();

// 根据EXIF旋转图片
Future<img.Image> _applyExifRotation(
    img.Image image, Map<String, IfdTag> exif) async {
  if (!exif.containsKey('Image Orientation')) return image;
  final orientation = exif['Image Orientation']!.printable;
  switch (orientation) {
    case 'Rotated 90 CW':
      return img.copyRotate(image, angle: 90);
    case 'Rotated 180':
      return img.copyRotate(image, angle: 180);
    case 'Rotated 270 CW':
      return img.copyRotate(image, angle: 270);
    default:
      return image;
  }
}

/// 获取缩略图
_getThumbnailImage(File file) async {
  final bytes = await file.readAsBytes();
  img.Image image = img.decodeImage(bytes)!;

  // 处理EXIF旋转
  final exifData = await readExifFromBytes(bytes);
  if (exifData == null) return null;
  // 过滤掉 null 键
  Map<String, IfdTag> nonNullableKeyMap = {};
  exifData.forEach((key, value) {
    if (key != null) {
      nonNullableKeyMap[key] = value;
    }
  });
  image = await _applyExifRotation(image, nonNullableKeyMap);

  // 缩放为32x32并灰度化
  image = img.copyResize(image, width: 32, height: 32);
  image = img.grayscale(image);
  return image;
}

/// 加载所有资源路径
Future loadAllPhotosIsolate() async {
  PhotoManagerTool.allPhotoAssets = [];
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  // 获取所有图片资源对象
  for (var album in assetPaths) {
    final count = await album.assetCountAsync;
    final assetItems = await album.getAssetListRange(start: 0, end: count);
    PhotoManagerTool.allPhotoAssets.addAll(assetItems);
    // id 映射
    for (var asset in assetItems) {
      if (!PhotoManagerTool.allPhotoAssetsIdMaps.containsKey(asset.id)) {
        PhotoManagerTool.allPhotoAssetsIdMaps[asset.id] = asset;
      }
    }
  }
  // 所有图片加载完成 发送通知
  globalStreamControler.add(AllPhotoLoadFinishEvent());
}

@pragma('vm:entry-point')
void spawnBigPhotosIsolate(SendPort port) async {
  PhotoManagerTool.allPhotoAssets = [];
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  // 获取所有图片资源对象
  for (var album in assetPaths) {
    final count = await album.assetCountAsync;
    final assetItems = await album.getAssetListRange(start: 0, end: count);
    for (var asset in assetItems) {
      final originalFile = await asset.file;
      if (originalFile != null) {
        final length = await originalFile.length();
        final size = AppUtils.fileSizeFormat(length);
        if (size.contains("MB")) {
          final mbSize = double.tryParse(size.replaceAll("MB", '')) ?? 0;
          if (mbSize > maxImageMB) {
            port.send({"event": "BigPhotoEvent", "data": asset.id});
          }
        }
      }
    }
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
      final screenshotAssets =
          await album.getAssetListRange(start: 0, end: 100000);
      photoAssets.addAll(screenshotAssets);
      break;
    }
  }
  port.send({
    "event": "screenshotEvent",
    "data": photoAssets.map((e) => e.id).toList()
  });
}

String averageHash(img.Image image, {int size = 8}) {
  final resized = img.copyResize(image, width: size, height: size);
  final grayscale = img.grayscale(resized);
  int mean = 0;
  List<int> pixels = [];
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final pixel = grayscale.getPixel(x, y);
      final luma = img.getLuminance(pixel);
      pixels.add(luma.toInt());
      mean += luma.toInt();
    }
  }
  mean = mean ~/ (size * size);
  String hash = '';
  for (var luma in pixels) {
    hash += luma >= mean ? '1' : '0';
  }
  return hash;
}

Map<String, String> hashs = {};

@pragma('vm:entry-point')
void spawnSamePhotosIsolate(SendPort port) async {
  PhotoManagerTool.allPhotoAssets = [];
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  // 获取所有图片资源对象
  int i = 0;
  Map<String, String> hashs = {};
  for (var album in assetPaths) {
    final count = await album.assetCountAsync;
    final assetItems = await album.getAssetListRange(start: 0, end: count);
    // PhotoManagerTool.allPhotoAssets.addAll(assetItems);
    // // id 映射
    // for (var asset in assetItems) {
    //   if (!PhotoManagerTool.allPhotoAssetsIdMaps.containsKey(asset.id)) {
    //     PhotoManagerTool.allPhotoAssetsIdMaps[asset.id] = asset;
    //   }
    // }
    for (var asset in assetItems) {
      final t = await asset.file;
      final bytes = await asset.thumbnailData;
      img.Image? image = img.decodeImage(bytes!);
      if (image != null) {
        final hash = averageHash(image, size: 8);
        final thumbnailData = await asset.thumbnailData;
        hashs[hash] = t!.path;
        print('hash----$hash');
        hashs.keys.toList().sort();
        port.send({
          "event": "test",
          "data": hashs,
        });
      }
    }
    /// 两两比较
    // for (var i = 0; i < assetItems.length; i++) {
    //   for (var j = 0; j < assetItems.length; j++) {
    //     final asset1 = await assetItems[i].file;
    //     final asset2 = await assetItems[j].file;
    //     // id 相同的不比较
    //     if (assetItems[i].id == assetItems[j].id) continue;
    //     try {
    //       if (asset1 != null && asset2 != null) {
    //         final image1 = await _getThumbnailImage(asset1);
    //         final image2 = await _getThumbnailImage(asset2);
    //         final result = await compareImages(src1: image1, src2: image2);
    //         if (result < 0.3) {
    //           // 发送消息通知首页更新数据
    //           // 发送图片资源的id path
    //           final asset1 = assetItems[i];
    //           final asset2 = assetItems[j];
    //           final asset1File = await asset1.file;
    //           final asset2File = await asset2.file;
    //           if (asset1File != null && asset2File != null) {
    //             final asset1ThumnailBytes = await asset1.thumbnailData;
    //             final asset2ThumnailBytes = await asset2.thumbnailData;
    //             final asset1OriginFile = await asset2.originFile;
    //             final asset2OriginFile = await asset2.originFile;
    //             final msg1 = IsolateAssetMessage(
    //                 id: asset1.id,
    //                 title: asset1.title,
    //                 orignalFilePath: asset1OriginFile?.path,
    //                 thumnailBytes: asset1ThumnailBytes,
    //                 orientation: asset1.orientation,
    //                 width: asset1.width,
    //                 height: asset1.height,
    //                 isFavorite: asset1.isFavorite,
    //                 isLivePhoto: asset1.isLivePhoto,
    //                 createDateSecond: asset1.createDateSecond,
    //                 modifiedDateSecond: asset1.modifiedDateSecond,
    //                 latitude: asset1.latitude,
    //                 longitude: asset1.longitude,
    //                 mimeType: asset1.mimeType);

    //             final msg2 = IsolateAssetMessage(
    //                 id: asset2.id,
    //                 title: asset2.title,
    //                 orignalFilePath: asset2OriginFile?.path,
    //                 thumnailBytes: asset2ThumnailBytes,
    //                 orientation: asset2.orientation,
    //                 width: asset2.width,
    //                 height: asset2.height,
    //                 isFavorite: asset2.isFavorite,
    //                 isLivePhoto: asset2.isLivePhoto,
    //                 createDateSecond: asset2.createDateSecond,
    //                 modifiedDateSecond: asset2.modifiedDateSecond,
    //                 latitude: asset2.latitude,
    //                 longitude: asset2.longitude,
    //                 mimeType: asset2.mimeType);
    //             port.send({
    //               "event": "sameEvent",
    //               "data": [msg1.toJson(), msg2.toJson()]
    //             });
    //           }
    //         }
    //         print('result-----$result');
    //       }
    //     } catch (e) {
    //       print('识别异常 ${e.toString()}');
    //     }
    //   }
    // }
    // PhotoManagerTool.isLoadingSamePhotos = false;
    // port.send({
    //   "event": "refresh",
    // });
  }

  // hashs.keys.toList().sort();
  // port.send({
  //   "event": "test",
  //   "data" : hashs,
  // });
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
        statusBarIconBrightness: Brightness.light);
    SystemChrome.setSystemUIOverlayStyle(style);
  }
  globalPort.listen((data) {
    // 监听子线程发送的数据
    if (data['event'] == "sameEvent") {
      globalStreamControler.add(SamePhotoEvent(data['data']));
    } else if (data['event'] == "BigPhotoEvent") {
      globalStreamControler.add(BigPhotoEvent(data['data']));
    } else if (data['event'] == "screenshotEvent") {
      globalStreamControler.add(ScreenPhotoEvent(data['data']));
    } else if (data['event'] == "refresh") {
      globalStreamControler.add(RefreshEvent());
    } else if (data['event'] == "test") {
      hashs = data['data'];
      globalStreamControler.add(RefreshEvent());
    }
    print("Received message from isolate $data");
  }, onError: (err) {
    print("Received message from isolate $err");
  });
  loadAllPhotosIsolate();
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
