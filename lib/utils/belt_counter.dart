import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:tuple/tuple.dart';

Tuple4<int, int, int, int> _marker;

int getBeltDensity(String imagePath, {bool annotatePicture}) {
  var image = _getImage(imagePath);
  var oneInch = _getOneSquareInchOfBelt(image);

  var inBelt = false;
  var belts = 0;
  for (var x = 0; x < oneInch.width; x++) {
    var isWhite = _isWhite(oneInch.getPixel(x, 2));

    if (isWhite && !inBelt) belts++;
    inBelt = isWhite;
  }

  if (annotatePicture) {
    markPicture(imagePath);
  }

  return belts;
}

markPicture(String imagePath) {
  var image = _getImage(imagePath);
  var ppi = _getPpi(image);
  var marker = _findMarker(image);

  for (var x = marker.item1 - ppi; x < marker.item1; x++) {
    var isWhite = _isWhite(image.getPixel(x, marker.item2 + 2));
    drawRect(image, x, (marker.item2 + (ppi / 2)).floor(), x, marker.item2 + ppi,
        isWhite ? Color.fromRgb(255, 255, 255) : Color.fromRgb(0, 0, 0));
    drawRect(image, x, marker.item2 + 10, x, (marker.item2 + (ppi / 2)).floor(), image.getPixel(x, 2));
  }

  drawRect(image, marker.item1, marker.item2, marker.item3, marker.item4, Color.fromRgb(255, 0, 0));
  drawRect(image, marker.item1 - ppi, marker.item2, marker.item1, marker.item2 + ppi, Color.fromRgb(0, 255, 0));

  File(imagePath).writeAsBytesSync(encodePng(image));
}

Image _getImage(String imagePath) {
  return copyRotate(decodeImage(File(imagePath).readAsBytesSync()), 90);
}

int _getPpi(Image image) {
  var marker = _findMarker(image);
  return min(marker.item4 - marker.item2, marker.item3 - marker.item1);
}

Image _getOneSquareInchOfBelt(Image image) {
  var marker = _findMarker(image);
  int ppi = _getPpi(image);

  return copyRotate(copyCrop(image, marker.item1 - ppi, marker.item2, ppi, ppi), 90);
}

Tuple4<int, int, int, int> _findMarker(Image image) {
  if (_marker != null) return _marker;

  List<Tuple2<int, int>> greens = new List();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (_isGreen(image.getPixel(x, y))) greens.add(new Tuple2(x, y));
    }
  }

  var x1 = greens.map((x) => x.item1).reduce(min);
  var y1 = greens.map((x) => x.item2).reduce(min);
  var x2 = greens.map((x) => x.item1).reduce(max);
  var y2 = greens.map((x) => x.item2).reduce(max);

  _marker = new Tuple4(x1, y1, x2, y2);
  return _marker;
}

// Color is encoded in a Uint32 as #AABBGGRR
bool _isGreen(int pixel) {
  var red = pixel & 0xFF;
  var green = (pixel & 0xFF00) >> 8;
  var blue = (pixel & 0xFF0000) >> 16;
  var tolerance = 20;

  return green > red + tolerance && green > blue + tolerance;
}

bool _isWhite(int pixel) {
  var red = pixel & 0xFF;
  var green = (pixel & 0xFF00) >> 8;
  var blue = (pixel & 0xFF0000) >> 16;

  var tolerance = 2.0;
  var min = 50;

  return (max(1.0 * red / green, 1.0 * green / red) <= tolerance) &&
      (max(1.0 * red / blue, 1.0 * blue / red) <= tolerance) &&
      (max(1.0 * green / blue, 1.0 * blue / green) <= tolerance) &&
      red >= min &&
      green >= min &&
      blue >= min;
}