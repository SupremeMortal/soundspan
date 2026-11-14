// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../tool/gen_icons.dart';

/// The client root: `flutter test` runs with it as the working directory.
final String _root = Directory.current.path;

MarkMaster _master(String name) => parseMaster(
  File(p.join(_root, 'assets', 'brand', name)).readAsStringSync(),
);

img.Image _decode(Uint8List bytes) => img.decodePng(bytes)!;

/// The images in an ICO file, read from its directory.
List<img.Image> _icoImages(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  expect(data.getUint16(0, Endian.little), 0, reason: 'reserved');
  expect(data.getUint16(2, Endian.little), 1, reason: 'type ICO');
  final count = data.getUint16(4, Endian.little);
  final images = <img.Image>[];
  for (var i = 0; i < count; i++) {
    final entry = 6 + i * 16;
    final width = bytes[entry] == 0 ? 256 : bytes[entry];
    final height = bytes[entry + 1] == 0 ? 256 : bytes[entry + 1];
    final size = data.getUint32(entry + 8, Endian.little);
    final offset = data.getUint32(entry + 12, Endian.little);
    final image = _decode(Uint8List.sublistView(bytes, offset, offset + size));
    expect([image.width, image.height], [width, height]);
    images.add(image);
  }
  return images;
}

late Directory _tmp;

void main() {
  setUp(() => _tmp = Directory.systemTemp.createTempSync('gen_icons_test'));
  tearDown(() => _tmp.deleteSync(recursive: true));

  group('parseMaster', () {
    for (final name in ['soundspan-mark.svg', 'soundspan-mark-mono.svg']) {
      test('parses seven capsules and two dots from $name', () {
        final master = _master(name);
        final rects = master.shapes.where((s) => s.kind == ShapeKind.rect);
        final circles = master.shapes.where((s) => s.kind == ShapeKind.circle);
        expect(rects, hasLength(7));
        expect(rects.every((s) => s.radius * 2 == s.width), isTrue);
        expect(circles, hasLength(2));
        expect(circles.every((s) => s.radius == 14), isTrue);
      });
    }

    test('rejects an unsupported element', () {
      const svg =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"> '
          '<path d="M0 0h10v10z"/></svg>';
      expect(
        () => parseMaster(svg),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('<path>'),
          ),
        ),
      );
    });

    test('rejects an unsupported attribute', () {
      const svg =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"> '
          '<rect x="1" y="1" width="2" height="2" transform="scale(2)"/></svg>';
      expect(
        () => parseMaster(svg),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('transform'),
          ),
        ),
      );
    });
  });

  test('two runs into separate directories produce byte-identical files', () {
    final a = Directory(p.join(_tmp.path, 'a'));
    final b = Directory(p.join(_tmp.path, 'b'));
    writeIcons(_root, a.path);
    writeIcons(_root, b.path);
    for (final output in iconOutputs) {
      expect(
        File(p.join(a.path, output.path)).readAsBytesSync(),
        File(p.join(b.path, output.path)).readAsBytesSync(),
        reason: output.path,
      );
    }
  });

  test('the committed files equal a fresh run', () {
    expect(checkIcons(_root), isEmpty);
  });

  test('every output in the table exists with the declared pixel size', () {
    for (final output in iconOutputs) {
      final bytes = File(p.join(_root, output.path)).readAsBytesSync();
      switch (output.kind) {
        case OutputKind.png:
          final image = _decode(bytes);
          expect(
            [image.width, image.height],
            [output.width, output.height],
            reason: output.path,
          );
        case OutputKind.ico:
          final sizes = _icoImages(bytes).map((i) => i.width).toList()..sort();
          expect(sizes, [16, 24, 32, 48, 64, 128, 256]);
        case OutputKind.svgCopy:
          expect(
            utf8.decode(bytes),
            File(p.join(_root, 'assets/brand/soundspan-mark.svg'))
                .readAsStringSync(),
          );
      }
    }
  });

  test('the adaptive foreground keeps every opaque pixel inside the safe '
      'zone', () {
    final foregrounds = iconOutputs.where(
      (o) =>
          o.path.endsWith('ic_launcher_foreground.png') ||
          o.path.endsWith('ic_launcher_monochrome.png'),
    );
    expect(foregrounds, hasLength(10));
    for (final output in foregrounds) {
      final image = _decode(File(p.join(_root, output.path)).readAsBytesSync());
      final size = image.width;
      final safeRadius = size * 33 / 108;
      final centre = size / 2;
      for (final pixel in image) {
        if (pixel.a == 0) continue;
        // The farthest corner of the pixel must be inside the circle.
        final dx = (pixel.x + 0.5 - centre).abs() + 0.5;
        final dy = (pixel.y + 0.5 - centre).abs() + 0.5;
        expect(
          math.sqrt(dx * dx + dy * dy),
          lessThanOrEqualTo(safeRadius),
          reason: '${output.path} (${pixel.x}, ${pixel.y})',
        );
      }
    }
  });

  test('single-colour outputs contain one colour with varying alpha only', () {
    final mono = iconOutputs.where((o) => o.master == Master.mono).toList();
    expect(
      mono.where((o) => o.path.contains('ic_stat_soundspan')),
      hasLength(5),
    );
    expect(mono.where((o) => o.path.contains('/tray/')), hasLength(8));
    for (final output in mono) {
      final image = _decode(File(p.join(_root, output.path)).readAsBytesSync());
      final colours = <int>{};
      final alphas = <num>{};
      for (final pixel in image) {
        alphas.add(pixel.a);
        if (pixel.a == 0) continue;
        colours.add(
          (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt(),
        );
      }
      expect(colours, hasLength(1), reason: output.path);
      expect(alphas.length, greaterThan(2), reason: output.path);
    }
    for (final n in [16, 22, 24, 32]) {
      final light = _decode(
        File(p.join(_root, 'assets/brand/tray/tray_light_$n.png'))
            .readAsBytesSync(),
      );
      final dark = _decode(
        File(p.join(_root, 'assets/brand/tray/tray_dark_$n.png'))
            .readAsBytesSync(),
      );
      final lightGlyph = light.firstWhere((px) => px.a > 0);
      final darkGlyph = dark.firstWhere((px) => px.a > 0);
      expect(lightGlyph.luminanceNormalized, lessThan(0.5));
      expect(darkGlyph.luminanceNormalized, greaterThan(0.5));
    }
  });

  test('iOS icons are fully opaque', () {
    final ios = iconOutputs.where(
      (o) => o.path.startsWith('ios/Runner/Assets.xcassets/AppIcon'),
    );
    expect(ios, isNotEmpty);
    for (final output in ios) {
      final image = _decode(File(p.join(_root, output.path)).readAsBytesSync());
      expect(image.hasAlpha, isFalse, reason: output.path);
      expect(image.every((px) => px.a == px.maxChannelValue), isTrue);
    }
  });

  test('the centre capsule is the tallest and the image is left-right '
      'symmetric', () {
    const spec = IconOutput(
      'render.png',
      width: 512,
      height: 512,
      master: Master.colour,
    );
    final image = _decode(encodeOutput(_master('soundspan-mark.svg'), spec));

    int height(int x) {
      var count = 0;
      for (var y = 0; y < image.height; y++) {
        if (image.getPixel(x, y).a > 127) count++;
      }
      return count;
    }

    // Capsule centres on the 512 grid: 85, 142, ..., 427.
    final heights = [for (var i = 0; i < 7; i++) height(85 + 57 * i)];
    final centre = heights[3];
    for (final (i, h) in heights.indexed) {
      if (i != 3) expect(h, lessThan(centre), reason: 'capsule $i');
    }

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final a = image.getPixel(x, y);
        // Within one pixel: the mirrored pixel or one of its neighbours.
        final matches = [-1, 0, 1].any((d) {
          final mx = (image.width - 1 - x + d).clamp(0, image.width - 1);
          final b = image.getPixel(mx, y);
          return (a.r - b.r).abs() <= 2 &&
              (a.g - b.g).abs() <= 2 &&
              (a.b - b.b).abs() <= 2 &&
              (a.a - b.a).abs() <= 2;
        });
        expect(matches, isTrue, reason: '($x, $y)');
      }
    }
  });

  test('every image named in the iOS and macOS Contents.json and in the web '
      'manifest exists with the pixel size the entry declares', () {
    for (final set in [
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
    ]) {
      final contents = jsonDecode(
        File(p.join(_root, set, 'Contents.json')).readAsStringSync(),
      ) as Map<String, Object?>;
      final images = (contents['images']! as List).cast<Map<String, Object?>>();
      expect(images, isNotEmpty);
      for (final entry in images) {
        final points = double.parse(
          (entry['size']! as String).split('x').first,
        );
        final scale = int.parse(
          (entry['scale']! as String).replaceAll('x', ''),
        );
        final file = File(p.join(_root, set, entry['filename']! as String));
        final image = _decode(file.readAsBytesSync());
        final expected = (points * scale).round();
        expect(
          [image.width, image.height],
          [expected, expected],
          reason: file.path,
        );
      }
    }

    final launch = jsonDecode(
      File(
        p.join(
          _root,
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json',
        ),
      ).readAsStringSync(),
    ) as Map<String, Object?>;
    for (final entry
        in (launch['images']! as List).cast<Map<String, Object?>>()) {
      final file = File(
        p.join(
          _root,
          'ios/Runner/Assets.xcassets/LaunchImage.imageset',
          entry['filename']! as String,
        ),
      );
      expect(file.existsSync(), isTrue, reason: file.path);
    }

    final manifest = jsonDecode(
      File(p.join(_root, 'web/manifest.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    expect(manifest['name'], 'soundspan');
    expect(manifest['short_name'], 'soundspan');
    expect(manifest['background_color'], '#0A0A0A');
    expect(manifest['theme_color'], '#0A0A0A');
    final icons = (manifest['icons']! as List).cast<Map<String, Object?>>();
    expect(icons, hasLength(4));
    for (final icon in icons) {
      final file = File(p.join(_root, 'web', icon['src']! as String));
      final image = _decode(file.readAsBytesSync());
      expect(
        '${image.width}x${image.height}',
        icon['sizes'],
        reason: file.path,
      );
    }
  });

  test('--check exits 0 on a fresh copy and non-zero when a committed icon is '
      'altered', () async {
    final copy = _tmp.path;
    for (final master in ['soundspan-mark.svg', 'soundspan-mark-mono.svg']) {
      File(p.join(_root, 'assets/brand', master))
          .copySync(p.join(copy, _mkdirs(copy, 'assets/brand', master)));
    }
    writeIcons(copy, copy);
    expect(await runGenIcons(['--check', '--root', copy]), 0);

    final altered = File(p.join(copy, 'web/favicon.png'));
    final image = _decode(altered.readAsBytesSync())
      ..setPixelRgba(0, 0, 255, 0, 0, 255);
    altered.writeAsBytesSync(img.encodePng(image));
    expect(await runGenIcons(['--check', '--root', copy]), isNot(0));
    expect(checkIcons(copy), ['web/favicon.png: differs from a fresh run']);
  });

  test('--check reports a committed generated file that is no longer '
      'produced', () {
    final copy = _tmp.path;
    for (final master in ['soundspan-mark.svg', 'soundspan-mark-mono.svg']) {
      File(p.join(_root, 'assets/brand', master))
          .copySync(p.join(copy, _mkdirs(copy, 'assets/brand', master)));
    }
    writeIcons(copy, copy);
    File(p.join(copy, 'web/icons/Icon-64.png')).writeAsBytesSync([1, 2, 3]);
    expect(checkIcons(copy), ['web/icons/Icon-64.png: no longer generated']);
  });
}

/// Creates `[root]/[dir]` and returns `[dir]/[name]`.
String _mkdirs(String root, String dir, String name) {
  Directory(p.join(root, dir)).createSync(recursive: true);
  return p.join(dir, name);
}
