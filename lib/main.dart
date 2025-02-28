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
      port.send({"event": "BigPhotoEvent", "data": null, 'size': 0});
      port.send({
        "event": "TaskProgressEvent",
        "type": 'bigPhoto',
        "progress": 33.33,
      });
      break;
    }
    final assetItems = await album.getAssetListRange(start: 0, end: count);
    bool findBigPhoto = false;
    for (var asset in assetItems) {
      final originalFile = await asset.originFile;
      if (originalFile != null) {
        final length = await originalFile.length();
        final size = AppUtils.fileSizeFormat(length);
        if (size.contains("MB")) {
          if (Platform.isAndroid) {
            throw Exception('');
          }
          final mbSize = double.tryParse(size.replaceAll("MB", '')) ?? 0;
          if (mbSize > maxImageMB) {
            findBigPhoto = true;
            bigPhotoSize += length;
            port.send({
              "event": "BigPhotoEvent",
              "data": asset.id,
              'size': bigPhotoSize
            });
          }
        }
      }
      final index = assetItems.indexOf(asset);
      double imageProcessProgress = ((index + 1) / assetItems.length) * 33.33;
      port.send({
        "event": "TaskProgressEvent",
        "type": 'bigPhoto',
        "progress": imageProcessProgress,
      });
    }
    if (!findBigPhoto) {
      port.send({"event": "BigPhotoEvent", "data": null, 'size': 0});
      port.send({
        "event": "TaskProgressEvent",
        "type": 'bigPhoto',
        "progress": 33.33,
      });
    }
    break;
  }
}

@pragma('vm:entry-point')
void spawnScreenshotIsolate(SendPort port) async {
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  // 获取所有图片资源对象
  for (var album in assetPaths) {
    if (album.name == 'Screenshots') {
      final count = await album.assetCountAsync;
      if (count > 0) {
        final screenshotAssets =
            await album.getAssetListRange(start: 0, end: count);
        if (screenshotAssets.isEmpty) {
          port.send({
            "event": "TaskProgressEvent",
            "type": 'screenshotPhoto',
            "progress": 33.33,
          });
          port.send({
            "event": "screenshotEvent",
            "data": null,
            'size': 0,
          });
          break;
        } else {
          int totalSize = 0;
          for (var i = 0; i < screenshotAssets.length; i++) {
            final asset = screenshotAssets[i];
            final originalFile = await asset.originFile;
            if (originalFile != null) {
              final length = await originalFile.length();
              totalSize += length;
              port.send({
                "event": "screenshotEvent",
                "data": asset.id,
                'size': totalSize,
              });
            }
            double imageProcessProgress =
                ((i + 1) / screenshotAssets.length) * 33.33;
            port.send({
              "event": "TaskProgressEvent",
              "type": 'screenshotPhoto',
              "progress": imageProcessProgress,
            });
          }
        }
      }
      break;
    }
  }
}

// Map<String, AssetEntity> hashs = {};
bool findSamePhotos = false;
_imageHashCompare(SendPort port, Map<String, AssetEntity> rangeMap) {
  /// 分组逻辑
  List<Map<String, dynamic>> groups = [];
  Set<String> useHashId = <String>{};
  for (var i = 0; i < rangeMap.length; i++) {
    final currentHash = rangeMap.keys.toList()[i];
    Set<String> groupIds = <String>{};
    if (useHashId.contains(currentHash)) continue;
    useHashId.add(currentHash);
    for (var j = i; j < rangeMap.length; j++) {
      if (Platform.isAndroid) {
        throw Exception('');
      }
      final nextHash = rangeMap.keys.toList()[j];
      if (useHashId.contains(nextHash)) continue;
      if (currentHash == nextHash) continue;
      final distance = ImageHashUtil.compareHashes(currentHash, nextHash);
      // print('distance.....$distance');
      if (distance > 0.75) {
        useHashId.add(nextHash);
        // print('找到相似图片.....');
        findSamePhotos = true;
        // 添加组
        groupIds.add(rangeMap[currentHash]!.id);
        groupIds.add(rangeMap[nextHash]!.id);
      }
    }
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
  var start = DateTime.now().millisecondsSinceEpoch;
  // 获取所有图片资源对象
  Map<String, AssetEntity> hashs = {};
  PhotoManagerTool.allPhotoAssets = [];
  int compareCount = 50;
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  double albumCompareProgerss = compareCount / assetPaths.length;
  if (assetPaths.isNotEmpty) {
    for (var album in assetPaths) {
      int count = await album.assetCountAsync;
      double assetCompareProgress = albumCompareProgerss / count;
      if (count == 0) continue;
      final assetItems = await album.getAssetListRange(start: 0, end: count);
      for (var i = 0; i < assetItems.length; i++) {
        final asset = assetItems[i];
        final bytes = await asset.thumbnailData;
        if (bytes != null) {
          var hash = ImageHashUtil.calculatePHash(img.decodeImage(bytes)!) +
              i.toString();
          // final hash = ImageHashUtil.calculateDHash(img.decodeImage(bytes)!);
          hashs[hash] = asset;
          print('hash.....$hash');

          ///==old==
          // 每生成50张 对比一次
          // if (hashs.length % 50 == 0) {
          //   _imageHashCompare(port);
          //   double imageProcessProgress =
          //       (i + 1) / assetItems.length * assetCompareProgress * 33.33;
          //   // print('same++++++$imageProcessProgress');
          //   port.send({
          //     "event": "TaskProgressEvent",
          //     "type": 'samePhoto',
          //     "progress": imageProcessProgress,
          //   });
          // }

          ///==new==
          var flag = 50;
          var step = 2;

          if (assetItems.length < flag) {
            List<String> sortedKeys = hashs.keys.toList();
            List<String> rangeKeys = [];
            rangeKeys = sortedKeys;
            Map<String, AssetEntity> rangeMap = Map.fromIterable(
              rangeKeys,
              key: (key) => key,
              value: (key) => hashs[key]!,
            );
            _imageHashCompare(port, rangeMap);
          } else if (assetItems.length - 1 == i && hashs.length % flag != 0) {
            List<String> sortedKeys = hashs.keys.toList();
            List<String> rangeKeys = [];
            rangeKeys = sortedKeys.sublist(i, assetItems.length - 1);
            Map<String, AssetEntity> rangeMap = Map.fromIterable(
              rangeKeys,
              key: (key) => key,
              value: (key) => hashs[key]!,
            );
            _imageHashCompare(port, rangeMap);
          } else if (hashs.length % flag == 0) {
            List<String> sortedKeys = hashs.keys.toList();
            List<String> rangeKeys = [];
            if (i <= flag) {
              rangeKeys = sortedKeys.sublist(i + 1 - flag, i);
            } else {
              rangeKeys = sortedKeys.sublist(i + 1 - flag - step, i);
            }
            Map<String, AssetEntity> rangeMap = Map.fromIterable(
              rangeKeys,
              key: (key) => key,
              value: (key) => hashs[key]!,
            );
            _imageHashCompare(port, rangeMap);
            sortedKeys.clear();
            rangeKeys.clear();
            rangeMap.clear();
          }

          double imageProcessProgress =
              (i + 1) / assetItems.length * assetCompareProgress * 33.33;
          // print('same++++++$imageProcessProgress');
          port.send({
            "event": "TaskProgressEvent",
            "type": 'samePhoto',
            "progress": imageProcessProgress,
          });
        }
      }
      break;
    }
  }
  if (!findSamePhotos) {
    port.send({
      "event": "sameEvent",
      "data": null,
    });
  }
  port.send({
    "event": "TaskProgressEvent",
    "type": 'samePhoto',
    "progress": 33.33,
  });
  var end = DateTime.now().millisecondsSinceEpoch;
  print('相似度总耗时.....${end - start}');
}

void main() async {
  // 设置图片缓存大小
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 20000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 << 20; // 900 MiB;
  final FlutterI18nDelegate flutterI18nDelegate = FlutterI18nDelegate(
    translationLoader: NamespaceFileTranslationLoader(
      namespaces: ["common", "home"],
      // useCountryCode: true,
      // fallbackDir: 'en',
      basePath: 'assets/i18n',
      forcedLocale: Locale(
          WidgetsBinding.instance.window.locale.languageCode == "zh"
              ? "zh"
              : 'en'),
    ),
    missingTranslationHandler: (key, locale) {
      // ignore: avoid_print
      print("--- Missing Key: $key, languageCode: ${locale!.languageCode}");
    },
  );

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
    } else if (data['event'] == "TaskProgressEvent") {
      globalStreamControler.add(
          TaskProgressEvent(type: data['type'], progress: data['progress']));
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
    AppUtils.globalContext = context;
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Smart clear',
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
