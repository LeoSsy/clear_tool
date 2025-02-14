import 'dart:math';
import 'package:image/image.dart' as img;

class ImageHashUtil {
  // 计算平均哈希值
  static String calculateAverageHash(img.Image image) {
    // 1. 调整图像大小为 8x8
    img.Image resizedImage = img.copyResize(image, width: 8, height: 8);

    // 2. 将图像转换为灰度图
    img.Image grayImage = img.grayscale(resizedImage);

    // 3. 计算灰度图的平均像素值
    int total = 0;
    for (int y = 0; y < grayImage.height; y++) {
      for (int x = 0; x < grayImage.width; x++) {
        img.Pixel pixel = grayImage.getPixel(x, y);
        num grayValue = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        total += grayValue.toInt();
      }
    }
    double average = total / (grayImage.width * grayImage.height);
    // 4. 生成哈希值
    String hash = '';
    for (int y = 0; y < grayImage.height; y++) {
      for (int x = 0; x < grayImage.width; x++) {
        img.Pixel pixel = grayImage.getPixel(x, y);
        num grayValue = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        if (grayValue > average) {
          hash += '1';
        } else {
          hash += '0';
        }
      }
    }
    return hash;
  }

  // 计算差异哈希值
  static String calculateDHash(img.Image image) {
    // 1. 调整图像大小为 9x8
    img.Image resizedImage = img.copyResize(image, width: 9, height: 8);
    // 2. 将图像转换为灰度图
    img.Image grayImage = img.grayscale(resizedImage);
    // 3. 比较相邻像素的灰度值
    String hash = '';
    for (int y = 0; y < grayImage.height; y++) {
      for (int x = 0; x < grayImage.width - 1; x++) {
        img.Pixel currentPixel = grayImage.getPixel(x, y);
        img.Pixel nextPixel = grayImage.getPixel(x + 1, y);
        int currentGray = img
            .getLuminanceRgb(currentPixel.r, currentPixel.g, currentPixel.b)
            .toInt();
        int nextGray =
            img.getLuminanceRgb(nextPixel.r, nextPixel.g, nextPixel.b).toInt();
        if (currentGray > nextGray) {
          hash += '1';
        } else {
          hash += '0';
        }
      }
    }
    return hash;
  }

// 计算汉明距离的函数
  static int calculateHammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) {
      throw ArgumentError('两个哈希值长度必须相同');
    }
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        distance++;
      }
    }
    return distance;
  }

  static double compareHashes(String hash1, String hash2) {
    int matches = 0;
    for (var i = 0; i < hash1.length; i++) {
      if (hash1[i] == hash2[i]) {
        matches++;
      }
    }
    return matches / hash1.length;
  }

  // 改进的感知哈希算法（使用DCT） 0.75 以上
  static String calculatePHash(img.Image image) {

    // 1. 调整尺寸为32x32（保留更多特征）
    final resizedImage = img.copyResize(image, width: 32, height: 32);

    // 2. 转换为灰度图
    final grayImage = img.grayscale(resizedImage);

    // 3. 计算DCT（离散余弦变换）
    final dctMatrix = _computeDCT(grayImage);

    // 4. 取左上8x8区域（保留低频特征）
    final hashValues = <double>[];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        hashValues.add(dctMatrix[y][x]); // 收集左上8x8区域的哈希值
      }
    }

    // 5. 计算中位数
    final median = _calculateMedian2(hashValues);

    // 6. 生成二进制哈希
    return hashValues.map((v) => v > median ? '1' : '0').join(''); // 根据哈希值和中位数生成二进制哈希字符串
  }

  // 计算中位数
  static double _calculateMedian2(List<double> list) {
    final sorted = List<double>.from(list)..sort(); // 复制并排序列表
    final mid = sorted.length ~/ 2; // 计算中位数索引
    return sorted.length % 2 == 1 // 如果列表长度是奇数
        ? sorted[mid] // 返回中间值
        : (sorted[mid - 1] + sorted[mid]) / 2; // 如果列表长度是偶数，返回中间两个值的平均值
  }


  // DCT计算实现
  static List<List<double>> _computeDCT(img.Image image) {
    final size = image.width; // 获取图片尺寸（假设图片是正方形的）
    final matrix = List.generate(size, (y) => List.generate(size, (x) {
      final pixel = image.getPixel(x, y); // 获取图片像素
      return (pixel.r * 0.299 + // 计算灰度值
          pixel.g * 0.587 +
          pixel.b * 0.114) / 255;
    }));

    return _applyDCT(matrix); // 应用DCT变换
  }


  // 应用二维DCT变换
  static List<List<double>> _applyDCT(List<List<double>> matrix) {
    final size = matrix.length; // 获取矩阵尺寸
    final result = List.generate(size, (_) => List<double>.filled(size, 0)); // 初始化结果矩阵

    final piOverTwoSize = pi / (2 * size); // 计算常量 pi / (2 * size)

    for (int u = 0; u < size; u++) {
      final cu = u == 0 ? 1 / sqrt(2) : 1.0; // 计算常量 cu
      for (int v = 0; v < size; v++) {
        final cv = v == 0 ? 1 / sqrt(2) : 1.0; // 计算常量 cv
        double sum = 0.0;
        for (int x = 0; x < size; x++) {
          final xuTerm = (2 * x + 1) * u; // 计算 xuTerm
          for (int y = 0; y < size; y++) {
            sum += matrix[x][y] * // 计算DCT变换中的和
                cos(xuTerm * piOverTwoSize) * // 计算 cos(xuTerm * pi / (2 * size))
                cos((2 * y + 1) * v * piOverTwoSize); // 计算 cos((2 * y + 1) * v * pi / (2 * size))
          }
        }
        result[u][v] = 0.25 * cu * cv * sum; // 计算结果矩阵中的值
      }
    }
    return result; // 返回结果矩阵
  }
}

// import 'dart:math';
// import 'package:image/image.dart';

// import 'dart:math';
// import 'package:image/image.dart';

// class Pair<T1, T2> {
//   T1 _first;
//   T2 _second;

//   Pair(this._first, this._second);
// }

// class Pixel {
//   final int _red;
//   final int _green;
//   final int _blue;
//   final int _alpha;

//   Pixel(this._red, this._green, this._blue, this._alpha);

//   @override
//   String toString() {
//     return 'red: $_red, green: $_green, blue: $_blue, alpha: $_alpha';
//   }
// }

// class ImageHashUtil {
//   static final Pair _pixelListPair = Pair([], []);
//   static int _size = 32;

//   static generateImageHash(image) {
//     var bytes1 = image.getBytes();
//     const bytesPerPixel = 4;
//     for (var i = 0; i <= bytes1.length - bytesPerPixel; i += bytesPerPixel) {
//       _pixelListPair._first
//           .add(Pixel(bytes1[i], bytes1[i + 1], bytes1[i + 2], bytes1[i + 3]));
//     }
//     return _calcPhash(_pixelListPair._first);
//   }

//   static String _calcPhash(List pixelList) {
//     var bitString = '';
//     var matrix = List<dynamic>.filled(32, 0);
//     var row = List<dynamic>.filled(32, 0);
//     var rows = List<dynamic>.filled(32, 0);
//     var col = List<dynamic>.filled(32, 0);
//     var data = _unit8ListToMatrix(pixelList); //returns a matrix used for DCT
//     for (var y = 0; y < _size; y++) {
//       for (var x = 0; x < _size; x++) {
//         var color = data[x][y];
//         try {
//           row[x] = getLuminanceRgb(color._red, color._green, color._blue);
//         } catch (e) {
          
//         }
//       }
//       rows[y] = _calculateDCT(row);
//     }
//     for (var x = 0; x < _size; x++) {
//       for (var y = 0; y < _size; y++) {
//         col[y] = rows[y][x];
//       }

//       matrix[x] = _calculateDCT(col);
//     }

//     // Extract the top 8x8 pixels.
//     var pixels = [];

//     for (var y = 0; y < 8; y++) {
//       for (var x = 0; x < 8; x++) {
//         pixels.add(matrix[y][x]);
//       }
//     }

//     // Calculate hash.
//     var bits = [];
//     var compare = _average(pixels);

//     for (var pixel in pixels) {
//       bits.add(pixel > compare ? 1 : 0);
//     }

//     bits.forEach((element) {
//       bitString += (1 * element).toString();
//     });

//     return BigInt.parse(bitString, radix: 2).toRadixString(16);
//   }

//   ///Helper funciton to compute the average of an array after dct caclulations
//   static num _average(List pixels) {
//     // Calculate the average value from top 8x8 pixels, except for the first one.
//     var n = pixels.length - 1;
//     return pixels.sublist(1, n).reduce((a, b) => a + b) / n;
//   }

//   ///Helper function to perform 1D discrete cosine tranformation on a matrix
//   static List _calculateDCT(List matrix) {
//     var transformed = List<num>.filled(32, 0);
//     var _size = matrix.length;

//     for (var i = 0; i < _size; i++) {
//       num sum = 0;

//       for (var j = 0; j < _size; j++) {
//         sum += matrix[j] * cos((i * pi * (j + 0.5)) / _size);
//       }

//       sum *= sqrt(2 / _size);

//       if (i == 0) {
//         sum *= 1 / sqrt(2);
//       }

//       transformed[i] = sum;
//     }

//     return transformed;
//   }

//   ///Helper function to convert a Unit8List to a nD matrix
//   static List _unit8ListToMatrix(List pixelList) {
//     var copy = pixelList.sublist(0);
//     pixelList.clear();

//     for (var r = 0; r < _size; r++) {
//       var res = [];
//       for (var c = 0; c < _size; c++) {
//         var i = r * _size + c;

//         if (i < copy.length) {
//           res.add(copy[i]);
//         }
//       }

//       pixelList.add(res);
//     }

//     return pixelList;
//   }
// }
