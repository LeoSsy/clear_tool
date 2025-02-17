import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/state/app_state.dart';
import 'package:clear_tool/tabbar/tabbar_screen.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/image_hash_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mmkv/mmkv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

StreamController globalStreamControler = StreamController.broadcast();
ReceivePort globalPort = ReceivePort();

FlutterIsolate? bigPhotoIsolate;
FlutterIsolate? screenshotPhotoIsolate;

/// 处理进度
double imageProcessProgress = 0;

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
            final index = assetItems.indexOf(asset);
            imageProcessProgress += (index / assetItems.length) * 33.33;
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
      final index = photoAssets.indexOf(asset);
      imageProcessProgress += (index / photoAssets.length) * 33.33;
      port.send({
        "event": "screenshotEvent",
        "data": asset.id,
        'size': totalSize,
      });
    }
  }
}

Map<String, AssetEntity> hashs = {};
_imageHashCompare(SendPort port) {
  /// 分组逻辑
  List<Map<String, dynamic>> groups = [];
  Set<String> useHashId = <String>{};
  for (var i = 0; i < hashs.length; i++) {
    final currentHash = hashs.keys.toList()[i];
    Set<String> groupIds = <String>{};
    if (useHashId.contains(currentHash)) continue;
    useHashId.add(currentHash);
    for (var j = 0; j < hashs.length; j++) {
      final nextHash = hashs.keys.toList()[j];
      if (useHashId.contains(nextHash)) continue;
      if (currentHash == nextHash) continue;
      final distance = ImageHashUtil.compareHashes(currentHash, nextHash);
      // print('distance.....$distance');
      if (distance > 0.8) {
        useHashId.add(nextHash);
        // print('找到相似图片.....');
        // 添加组
        groupIds.add(hashs[currentHash]!.id);
        groupIds.add(hashs[nextHash]!.id);
      }
    }
    final index = hashs.keys.toList().indexOf(currentHash);
    imageProcessProgress += (index / hashs.keys.length) * 33.33;
    if (groupIds.length >= 2) {
      groups.add(SamePhotoGroup(
        id: groupIds.first,
        title: '${groupIds.length}',
        ids: groupIds.toList(),
      ).toJson());
      port.send({
        "event": "sameEvent",
        "data": SamePhotoGroup(
          id: groupIds.first,
          title: '${groupIds.length}',
          ids: groupIds.toList(),
        ).toJson(),
      });
    }
  }
}

@pragma('vm:entry-point')
void spawnSamePhotosIsolate(SendPort port) async {
  // 获取所有图片资源对象
  // Map<String, AssetEntity> hashs = {};
  PhotoManagerTool.allPhotoAssets = [];
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  if (assetPaths.isNotEmpty) {
    for (var album in assetPaths) {
      int count = await album.assetCountAsync;
      if (count == 0) continue;
      final assetItems = await album.getAssetListRange(start: 0, end: count);
      for (var i = 0; i < assetItems.length; i++) {
        final asset = assetItems[i];
        final bytes = await asset.thumbnailData;
        if (bytes != null) {
          final hash = ImageHashUtil.calculatePHash(img.decodeImage(bytes)!);
          // final hash = ImageHashUtil.calculateDHash(img.decodeImage(bytes)!);
          hashs[hash] = asset;
          // 每生成50张 对比一次
          if (hashs.length % 50 == 0) {
            _imageHashCompare(port);
          }
          print('hash.....$hash');
        }
      }
    }
  }
  _imageHashCompare(port);

  // /// 分组逻辑
  // List<Map<String, dynamic>> groups = [];
  // Set<String> useHashId = <String>{};
  // for (var i = 0; i < hashs.length; i++) {
  //   final currentHash = hashs.keys.toList()[i];
  //   Set<String> groupIds = <String>{};
  //   if (useHashId.contains(currentHash)) continue;
  //   useHashId.add(currentHash);
  //   for (var j = 0; j < hashs.length; j++) {
  //     final nextHash = hashs.keys.toList()[j];
  //     if (useHashId.contains(nextHash)) continue;
  //     if (currentHash == nextHash) continue;
  //     final distance = ImageHashUtil.compareHashes(currentHash, nextHash);
  //     print('distance.....$distance');
  //     if (distance > 0.8) {
  //       useHashId.add(nextHash);
  //       print('找到相似图片.....');
  //       // 添加组
  //       groupIds.add(hashs[currentHash]!.id);
  //       groupIds.add(hashs[nextHash]!.id);
  //     }
  //   }
  //   final index = hashs.keys.toList().indexOf(currentHash);
  //   imageProcessProgress += (index / hashs.keys.length) * 33.33;
  //   if (groupIds.length >= 2) {
  //     groups.add(SamePhotoGroup(
  //       id: groupIds.first,
  //       title: '${groupIds.length}',
  //       ids: groupIds.toList(),
  //     ).toJson());
  //     port.send({
  //       "event": "sameEvent",
  //       "data": SamePhotoGroup(
  //         id: groupIds.first,
  //         title: '${groupIds.length}',
  //         ids: groupIds.toList(),
  //       ).toJson(),
  //     });
  //   }
  // }
  // print('groups----->${groups.length}');
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
  final rootDir = await MMKV.initialize();
  print('MMKV for flutter with rootDir = $rootDir');

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
    }
  }, onError: (err) {
    print("Received message from isolate $err");
  });
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
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      builder: (context, child) {
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
              builders:
                  Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
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
      },
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
