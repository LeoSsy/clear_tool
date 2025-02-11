import 'dart:math';
import 'package:image/image.dart';

import 'dart:math';
import 'package:image/image.dart';

class Pair<T1, T2> {
  T1 _first;
  T2 _second;

  Pair(this._first, this._second);
}

class Pixel {
  final int _red;
  final int _green;
  final int _blue;
  final int _alpha;

  Pixel(this._red, this._green, this._blue, this._alpha);

  @override
  String toString() {
    return 'red: $_red, green: $_green, blue: $_blue, alpha: $_alpha';
  }
}

class ImageHashUtil {
  static final Pair _pixelListPair = Pair([], []);
  static int _size = 32;

  static generateImageHash(image) {
    var bytes1 = image.getBytes();
    const bytesPerPixel = 4;
    for (var i = 0; i <= bytes1.length - bytesPerPixel; i += bytesPerPixel) {
      _pixelListPair._first
          .add(Pixel(bytes1[i], bytes1[i + 1], bytes1[i + 2], bytes1[i + 3]));
    }
    return _calcPhash(_pixelListPair._first);
  }

  static String _calcPhash(List pixelList) {
    var bitString = '';
    var matrix = List<dynamic>.filled(32, 0);
    var row = List<dynamic>.filled(32, 0);
    var rows = List<dynamic>.filled(32, 0);
    var col = List<dynamic>.filled(32, 0);
    var data = _unit8ListToMatrix(pixelList); //returns a matrix used for DCT
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        var color = data[x][y];
        try {
          row[x] = getLuminanceRgb(color._red, color._green, color._blue);
        } catch (e) {
          
        }
      }
      rows[y] = _calculateDCT(row);
    }
    for (var x = 0; x < _size; x++) {
      for (var y = 0; y < _size; y++) {
        col[y] = rows[y][x];
      }

      matrix[x] = _calculateDCT(col);
    }

    // Extract the top 8x8 pixels.
    var pixels = [];

    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        pixels.add(matrix[y][x]);
      }
    }

    // Calculate hash.
    var bits = [];
    var compare = _average(pixels);

    for (var pixel in pixels) {
      bits.add(pixel > compare ? 1 : 0);
    }

    bits.forEach((element) {
      bitString += (1 * element).toString();
    });

    return BigInt.parse(bitString, radix: 2).toRadixString(16);
  }

  ///Helper funciton to compute the average of an array after dct caclulations
  static num _average(List pixels) {
    // Calculate the average value from top 8x8 pixels, except for the first one.
    var n = pixels.length - 1;
    return pixels.sublist(1, n).reduce((a, b) => a + b) / n;
  }

  ///Helper function to perform 1D discrete cosine tranformation on a matrix
  static List _calculateDCT(List matrix) {
    var transformed = List<num>.filled(32, 0);
    var _size = matrix.length;

    for (var i = 0; i < _size; i++) {
      num sum = 0;

      for (var j = 0; j < _size; j++) {
        sum += matrix[j] * cos((i * pi * (j + 0.5)) / _size);
      }

      sum *= sqrt(2 / _size);

      if (i == 0) {
        sum *= 1 / sqrt(2);
      }

      transformed[i] = sum;
    }

    return transformed;
  }

  ///Helper function to convert a Unit8List to a nD matrix
  static List _unit8ListToMatrix(List pixelList) {
    var copy = pixelList.sublist(0);
    pixelList.clear();

    for (var r = 0; r < _size; r++) {
      var res = [];
      for (var c = 0; c < _size; c++) {
        var i = r * _size + c;

        if (i < copy.length) {
          res.add(copy[i]);
        }
      }

      pixelList.add(res);
    }

    return pixelList;
  }
}
