import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageConvertingUtil {
  ImageConvertingUtil._();

  static img.Image convertBGRA8888toImage(
    Uint8List bgraBytes,
    int width,
    int height,
    int bytesPerRow,
  ) {
    Uint8List alignedBytes = Uint8List(width * height * 4);
    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int pixelIndex = (y * bytesPerRow) + (x * 4);
        if (pixelIndex + 3 >= bgraBytes.length) break;
        alignedBytes[index] = bgraBytes[pixelIndex + 2]; // R <- B
        alignedBytes[index + 1] = bgraBytes[pixelIndex + 1]; // G
        alignedBytes[index + 2] = bgraBytes[pixelIndex]; // B <- R
        alignedBytes[index + 3] = bgraBytes[pixelIndex + 3]; // A
        index += 4;
      }
    }
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: alignedBytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  static img.Image convertNV21toImage(
    Uint8List nv21Bytes,
    int width,
    int height,
  ) {
    Uint8List rgbaBytes = yuv420NV21ToRgba8888(nv21Bytes, width, height);
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbaBytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  static Uint8List yuv420NV21ToRgba8888(
    Uint8List src,
    int width,
    int height,
  ) {
    final rgba = Uint8List(width * height * 4);
    final nvStart = width * height;
    int index = 0, rgbaIndex = 0;
    int y, u, v;
    int r, g, b, a;
    int nvIndex = 0;
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        nvIndex = (i ~/ 2 * width + j - j % 2).toInt();
        y = src[rgbaIndex];
        u = src[nvStart + nvIndex];
        v = src[nvStart + nvIndex + 1];
        r = y + (1.13983 * (v - 128)).toInt();
        g = y - (0.39465 * (u - 128)).toInt() - (0.58060 * (v - 128)).toInt();
        b = y + (2.03211 * (u - 128)).toInt();
        a = 255;
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);
        index = rgbaIndex % width + i * width;
        rgba[index * 4 + 0] = b;
        rgba[index * 4 + 1] = g;
        rgba[index * 4 + 2] = r;
        rgba[index * 4 + 3] = a;
        rgbaIndex++;
      }
    }
    return rgba;
  }

  static Uint8List convertRgbaToNv21(
    Uint8List rgbaBytes,
    int width,
    int height,
  ) {
    int frameSize = width * height;
    Uint8List nv21 = Uint8List(frameSize + (frameSize ~/ 2));
    int yIndex = 0;
    int uvIndex = frameSize;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int rgbaIndex = (y * width + x) * 4;
        int r = rgbaBytes[rgbaIndex];
        int g = rgbaBytes[rgbaIndex + 1];
        int b = rgbaBytes[rgbaIndex + 2];
        int yValue = ((0.299 * r) + (0.587 * g) + (0.114 * b)).toInt();
        nv21[yIndex++] = yValue.clamp(0, 255);
        if (y % 2 == 0 && x % 2 == 0) {
          int uValue = (((b - yValue) * 0.565) + 128).toInt();
          int vValue = (((r - yValue) * 0.713) + 128).toInt();
          nv21[uvIndex++] = vValue.clamp(0, 255); // V first
          nv21[uvIndex++] = uValue.clamp(0, 255); // U second
        }
      }
    }
    return nv21;
  }

  static Uint8List convertRgbaToBgra(Uint8List rgba) {
    for (int i = 0; i < rgba.length; i += 4) {
      int temp = rgba[i];
      rgba[i] = rgba[i + 2];
      rgba[i + 2] = temp;
    }
    return rgba;
  }
}
