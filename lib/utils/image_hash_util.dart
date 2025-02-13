import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:image_compare_2/image_compare_2.dart';

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

  // 计算感知哈希值
  static String calculatePHash(img.Image image) {
    // 1. 调整图像大小为 32x32
    img.Image resizedImage = img.copyResize(image, width: 32, height: 32);
    // 2. 将图像转换为灰度图
    img.Image grayImage = img.grayscale(resizedImage);
    // 3. 进行离散余弦变换（DCT）
    List<List<double>> dctMatrix = _dct(grayImage);
    // 4. 取 DCT 变换结果的左上角 8x8 区域（忽略直流分量）
    List<double> lowFrequencyComponents = [];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        if (x != 0 || y != 0) {
          lowFrequencyComponents.add(dctMatrix[y][x]);
        }
      }
    }
    // 5. 计算这些低频分量的中位数
    double median = _calculateMedian(lowFrequencyComponents);
    // 6. 根据中位数生成 pHash 值
    int pHash = 0;
    for (int i = 0; i < lowFrequencyComponents.length; i++) {
      if (lowFrequencyComponents[i] > median) {
        pHash |= (1 << i);
      }
    }
    return pHash.toString();
  }

// 进行离散余弦变换（DCT）
  static List<List<double>> _dct(img.Image image) {
    int width = image.width;
    int height = image.height;
    List<List<double>> dctMatrix =
        List.generate(height, (_) => List.filled(width, 0.0));
    double c(int k) => (k == 0) ? 1 / sqrt(2) : 1;
    for (int u = 0; u < height; u++) {
      for (int v = 0; v < width; v++) {
        double sum = 0;
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            img.Pixel pixel = image.getPixel(x, y);
            double pixelValue =
                img.getLuminanceRgb(pixel.r, pixel.g, pixel.b).toDouble();
            sum += pixelValue *
                cos((2 * y + 1) * u * pi / (2 * height)) *
                cos((2 * x + 1) * v * pi / (2 * width));
          }
        }
        dctMatrix[u][v] = 0.25 * c(u) * c(v) * sum;
      }
    }
    return dctMatrix;
  }

// 计算列表的中位数
  static double _calculateMedian(List<double> values) {
    values.sort();
    int length = values.length;
    if (length % 2 == 0) {
      return (values[length ~/ 2 - 1] + values[length ~/ 2]) / 2;
    } else {
      return values[length ~/ 2];
    }
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
