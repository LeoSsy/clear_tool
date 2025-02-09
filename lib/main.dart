import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/const/const.dart';
import 'package:clear_tool/event/event_define.dart';
import 'package:clear_tool/photo_manager/photo_manager_tool.dart';
import 'package:clear_tool/tabbar/tabbar_screen.dart';
import 'package:clear_tool/utils/permission_utils.dart';
// import 'package:easy_isolate/easy_isolate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_compare_2/image_compare_2.dart';
import 'package:photo_manager/photo_manager.dart';

// RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
StreamController globalStreamControler = StreamController.broadcast();

@pragma('vm:entry-point')
void spawnIsolate(SendPort port) async {
  final assetPaths =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  List<AssetEntity> photoAssets = <AssetEntity>[];
  // 获取所有图片资源对象
  for (var album in assetPaths) {
    // final assetItems = await album.getAssetListPaged(page: 0, size: 100000);
    final count = await album.assetCountAsync;
    final assetItems = await album.getAssetListRange(start: 0, end: count);

    /// 两两比较
    for (var i = 0; i < assetItems.length; i++) {
      for (var j = 0; j < assetItems.length; j++) {
        final asset1 = await assetItems[i].file;
        final asset2 = await assetItems[j].file;
        // id 相同的不比较
        if (assetItems[i].id == assetItems[j].id) continue;
        try {
          if (asset1 != null && asset2 != null) {
            final result = await compareImages(src1: asset1, src2: asset2);
            if (result < 0.02) {
              // sameAssets.add(photoAssets[i]);
              // sameAssets.add(photoAssets[j]);
              // 发送消息通知首页更新数据
              // 发送图片资源的id path
              final asset1 = assetItems[i];
              final asset2 = assetItems[j];
              final asset1File = await asset1.file;
              final asset2File = await asset2.file;
              if (asset1File != null && asset2File != null) {
                final asset1ThumnailBytes = await asset1.thumbnailData;
                final asset2ThumnailBytes = await asset2.thumbnailData;
                final asset1OriginFile = await asset2.originFile;
                final asset2OriginFile = await asset2.originFile;
                final msg1 = IsolateAssetMessage(
                    id: asset1.id,
                    title: asset1.title,
                    orignalFilePath: asset1OriginFile?.path,
                    thumnailBytes: asset1ThumnailBytes,
                    orientation: asset1.orientation,
                    width: asset1.width,
                    height: asset1.height,
                    isFavorite: asset1.isFavorite,
                    isLivePhoto: asset1.isLivePhoto,
                    createDateSecond: asset1.createDateSecond,
                    modifiedDateSecond: asset1.modifiedDateSecond,
                    latitude: asset1.latitude,
                    longitude: asset1.longitude,
                    mimeType: asset1.mimeType);

                final msg2 = IsolateAssetMessage(
                    id: asset2.id,
                    title: asset2.title,
                    orignalFilePath: asset2OriginFile?.path,
                    thumnailBytes: asset2ThumnailBytes,
                    orientation: asset2.orientation,
                    width: asset2.width,
                    height: asset2.height,
                    isFavorite: asset2.isFavorite,
                    isLivePhoto: asset2.isLivePhoto,
                    createDateSecond: asset2.createDateSecond,
                    modifiedDateSecond: asset2.modifiedDateSecond,
                    latitude: asset2.latitude,
                    longitude: asset2.longitude,
                    mimeType: asset2.mimeType);
                port.send([msg1.toJson(), msg2.toJson()]);
              }
            }
            print('result-----$result');
          }
        } catch (e) {
          print('识别异常 ${e.toString()}');
        }
      }
    }
    //计算分页
    // const pageSize = 10;
    // final totalPage = (count / pageSize).ceil();
    // var curentPage = 1;
    // while (curentPage < totalPage) {
    //   final assetItems =
    //       await album.getAssetListPaged(page: curentPage, size: pageSize);

    //   /// 两两比较
    //   for (var i = 0; i < assetItems.length; i++) {
    //     for (var j = 0; j < assetItems.length; j++) {
    //       final asset1 = await assetItems[i].file;
    //       final asset2 = await assetItems[j].file;
    //       // id 相同的不比较
    //       if (assetItems[i].id == assetItems[j].id) continue;
    //       try {
    //         if (asset1 != null && asset2 != null) {
    //           final result = await compareImages(src1: asset1, src2: asset2);
    //           if (result * 100 < 2) {
    //             // sameAssets.add(photoAssets[i]);
    //             // sameAssets.add(photoAssets[j]);
    //             // 发送消息通知首页更新数据
    //             // 发送图片资源的id path
    //             final asset1 = assetItems[i];
    //             final asset2 = assetItems[j];
    //             final asset1File = await asset1.file;
    //             final asset2File = await asset2.file;
    //             if (asset1File != null && asset2File != null) {
    //               final asset1ThumnailBytes = await asset1.thumbnailData;
    //               final asset2ThumnailBytes = await asset2.thumbnailData;
    //               final asset1OriginFile = await asset2.originFile;
    //               final asset2OriginFile = await asset2.originFile;
    //               final msg1 = IsolateAssetMessage(
    //                   id: asset1.id,
    //                   title: asset1.title,
    //                   orignalFilePath: asset1OriginFile?.path,
    //                   thumnailBytes: asset1ThumnailBytes,
    //                   orientation: asset1.orientation,
    //                   width: asset1.width,
    //                   height: asset1.height,
    //                   isFavorite: asset1.isFavorite,
    //                   isLivePhoto: asset1.isLivePhoto,
    //                   createDateSecond: asset1.createDateSecond,
    //                   modifiedDateSecond: asset1.modifiedDateSecond,
    //                   latitude: asset1.latitude,
    //                   longitude: asset1.longitude,
    //                   mimeType: asset1.mimeType);

    //               final msg2 = IsolateAssetMessage(
    //                   id: asset2.id,
    //                   title: asset2.title,
    //                   orignalFilePath: asset2OriginFile?.path,
    //                   thumnailBytes: asset2ThumnailBytes,
    //                   orientation: asset2.orientation,
    //                   width: asset2.width,
    //                   height: asset2.height,
    //                   isFavorite: asset2.isFavorite,
    //                   isLivePhoto: asset2.isLivePhoto,
    //                   createDateSecond: asset2.createDateSecond,
    //                   modifiedDateSecond: asset2.modifiedDateSecond,
    //                   latitude: asset2.latitude,
    //                   longitude: asset2.longitude,
    //                   mimeType: asset2.mimeType);
    //               port.send([msg1.toJson(), msg2.toJson()]);
    //             }
    //           }
    //           print('result-----$result');
    //         }
    //       } catch (e) {
    //         print('识别异常 ${e.toString()}');
    //       }
    //     }
    //   }
    //   curentPage++;
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
  var port = ReceivePort();
  port.listen((data) {
    // 监听子线程发送的数据
    globalStreamControler.add(SamePhotoEvent(data));
    print("Received message from isolate $data");
  }, onError: (err) {
    print("Received message from isolate $err");
  });
  await FlutterIsolate.spawn(spawnIsolate, port.sendPort);
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
