import 'package:image/image.dart' as img;

class ImageFilterUtil {
  ImageFilterUtil._();

  static img.Image applySharpening(img.Image image) {
    // 3x3 Sharpening Kernel
    final List<List<int>> kernel = [
      [-1, -1, -1],
      [-1, 9, -1],
      [-1, -1, -1],
    ];

    final img.Image newImage = img.Image.from(image);
    final int width = image.width;
    final int height = image.height;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double sumR = 0, sumG = 0, sumB = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            img.Pixel pixel = image.getPixel(x + kx, y + ky);
            int kernelValue = kernel[ky + 1][kx + 1];

            sumR += pixel.r * kernelValue;
            sumG += pixel.g * kernelValue;
            sumB += pixel.b * kernelValue;
          }
        }

        // Clamp values to [0, 255]
        int newR = sumR.clamp(0, 255).toInt();
        int newG = sumG.clamp(0, 255).toInt();
        int newB = sumB.clamp(0, 255).toInt();

        newImage.setPixelRgba(x, y, newR, newG, newB, 255);
      }
    }

    return newImage;
  }

  static img.Image applyThreshold(img.Image image, {int threshold = 128}) {
    img.Image newImage = img.Image.from(image);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        img.Pixel pixel = image.getPixel(x, y);

        int luminance =
            ((pixel.r * 0.3) + (pixel.g * 0.59) + (pixel.b * 0.11)).toInt();
        int binary = (luminance > threshold) ? 255 : 0;

        newImage.setPixelRgba(x, y, binary, binary, binary, 255);
      }
    }

    return newImage;
  }
}
