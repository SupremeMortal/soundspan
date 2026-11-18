// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Generates every app icon, launch image, tray icon and notification icon from
// the two vector masters in assets/brand/ (doc 10, Icons and Splash).
//
// Usage, from client/:
//   dart run tool/gen_icons.dart [--check] [--root <dir>]
// Without `--check` it writes every file in [iconOutputs]. With `--check` it
// generates into a temporary directory, prints `<path>: <problem>` for each
// committed file that differs, is missing or is no longer generated, and exits
// 1 when there is any. `--root` names the client root (default: the current
// directory).
//
// The tool owns only the image files in the table. The XML, storyboard,
// Contents.json and manifest files that reference them are hand-written.
//
// Rasterizing is pure Dart at 4x4 supersampling and PNGs are compressed with
// the pure-Dart deflate of package:archive, not the platform zlib, so the bytes
// are the same on every machine. PNGs carry no timestamp or other metadata.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart' show ZLibEncoderWeb, getCrc32;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// The colour master, relative to the client root.
const colourMasterPath = 'assets/brand/soundspan-mark.svg';

/// The single-colour master, relative to the client root.
const monoMasterPath = 'assets/brand/soundspan-mark-mono.svg';

/// The background of opaque icons and launch screens, `#0A0A0A`.
const background = 0x0A0A0A;

const _white = 0xFFFFFF;
const _black = 0x000000;

/// The master an output is drawn from.
enum Master {
  /// `soundspan-mark.svg`: per-shape fills and an outline.
  colour,

  /// `soundspan-mark-mono.svg`: one colour, given by [IconOutput.glyph].
  mono,
}

/// What is drawn behind the mark.
enum Backdrop {
  /// Nothing: the image is transparent around the mark.
  none,

  /// An opaque [background] square filling the image. The PNG has no alpha
  /// channel.
  square,

  /// A [background] rounded square inset as in the macOS app icon grid
  /// (824 of 1024 with a 185.4 corner radius), transparent outside.
  roundedSquare,
}

/// The file format of an output.
enum OutputKind {
  /// One PNG.
  png,

  /// A Windows icon holding one PNG per size in [IconOutput.icoSizes].
  ico,

  /// A byte copy of the colour master.
  svgCopy,
}

/// One generated file.
class IconOutput {
  /// Describes the file at [path], [width] by [height] pixels.
  const new(
    this.path, {
    required this.width,
    required this.height,
    required this.master,
    this.padding = 0,
    this.backdrop = Backdrop.none,
    this.glyph = _white,
    this.kind = OutputKind.png,
    this.icoSizes = const [],
  });

  /// The path relative to the client root, with `/` separators.
  final String path;

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// The master the mark is drawn from.
  final Master master;

  /// The margin on each side of the 512 grid, as a fraction of the shorter
  /// side of the image. The grid is centred in the image.
  final double padding;

  /// What is drawn behind the mark.
  final Backdrop backdrop;

  /// The RGB colour of the mark when [master] is [Master.mono].
  final int glyph;

  /// The file format.
  final OutputKind kind;

  /// The square sizes inside an [OutputKind.ico] file.
  final List<int> icoSizes;

  /// This output at [size] by [size] pixels, for one image of an ICO file.
  IconOutput _atSize(int size) => IconOutput(
    path,
    width: size,
    height: size,
    master: master,
    padding: padding,
    backdrop: backdrop,
    glyph: glyph,
  );
}

const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

const _res = 'android/app/src/main/res';

List<IconOutput> _android(
  String dir,
  String name,
  int dp,
  Master master, {
  double padding = 0,
  Backdrop backdrop = Backdrop.none,
}) => [
  for (final MapEntry(key: density, value: scale) in _densities.entries)
    IconOutput(
      '$_res/$dir-$density/$name.png',
      width: (dp * scale).round(),
      height: (dp * scale).round(),
      master: master,
      padding: padding,
      backdrop: backdrop,
    ),
];

const _ios = 'ios/Runner/Assets.xcassets';
const _iosIconSizes = {
  '20x20@1x': 20,
  '20x20@2x': 40,
  '20x20@3x': 60,
  '29x29@1x': 29,
  '29x29@2x': 58,
  '29x29@3x': 87,
  '40x40@1x': 40,
  '40x40@2x': 80,
  '40x40@3x': 120,
  '60x60@2x': 120,
  '60x60@3x': 180,
  '76x76@1x': 76,
  '76x76@2x': 152,
  '83.5x83.5@2x': 167,
  '1024x1024@1x': 1024,
};

IconOutput _square(
  String path,
  int size,
  Master master, {
  double padding = 0,
  Backdrop backdrop = Backdrop.none,
  int glyph = _white,
}) => IconOutput(
  path,
  width: size,
  height: size,
  master: master,
  padding: padding,
  backdrop: backdrop,
  glyph: glyph,
);

/// The margin around the mark on an opaque square icon.
const _iconPadding = 0.12;

/// The margin that keeps the mark inside the adaptive icon safe zone (a circle
/// of 66 in 108) and the maskable web icon safe zone (a circle of 80%).
const _safeZonePadding = 0.17;

/// Every generated file. Tests read this table too.
final List<IconOutput> iconOutputs = List.unmodifiable([
  // Android: legacy launcher icon, adaptive foreground and monochrome layers,
  // notification icon and launch image.
  ..._android(
    'mipmap',
    'ic_launcher',
    48,
    Master.colour,
    padding: _iconPadding,
    backdrop: Backdrop.square,
  ),
  ..._android(
    'mipmap',
    'ic_launcher_foreground',
    108,
    Master.colour,
    padding: _safeZonePadding,
  ),
  ..._android(
    'mipmap',
    'ic_launcher_monochrome',
    108,
    Master.mono,
    padding: _safeZonePadding,
  ),
  ..._android(
    'drawable',
    'ic_stat_soundspan',
    24,
    Master.mono,
    padding: 1 / 12,
  ),
  ..._android('drawable', 'launch_image', 128, Master.colour),
  // iOS: app icon set and launch image.
  for (final MapEntry(key: name, value: size) in _iosIconSizes.entries)
    _square(
      '$_ios/AppIcon.appiconset/Icon-App-$name.png',
      size,
      Master.colour,
      padding: _iconPadding,
      backdrop: Backdrop.square,
    ),
  for (final (suffix, size) in [('', 128), ('@2x', 256), ('@3x', 384)])
    _square(
      '$_ios/LaunchImage.imageset/LaunchImage$suffix.png',
      size,
      Master.colour,
    ),
  // macOS: app icon set.
  for (final size in [16, 32, 64, 128, 256, 512, 1024])
    _square(
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
      size,
      Master.colour,
      padding: 0.2,
      backdrop: Backdrop.roundedSquare,
    ),
  // Windows: application icon and MSIX tiles.
  const IconOutput(
    'windows/runner/resources/app_icon.ico',
    width: 256,
    height: 256,
    master: Master.colour,
    kind: OutputKind.ico,
    icoSizes: [16, 24, 32, 48, 64, 128, 256],
  ),
  _square('windows/msix_assets/Square44x44Logo.png', 44, Master.colour),
  for (final size in [71, 150, 310])
    _square(
      'windows/msix_assets/Square${size}x${size}Logo.png',
      size,
      Master.colour,
      padding: _safeZonePadding,
    ),
  const IconOutput(
    'windows/msix_assets/Wide310x150Logo.png',
    width: 310,
    height: 150,
    master: Master.colour,
    padding: _safeZonePadding,
  ),
  // Linux: hicolor theme icons.
  for (final size in [16, 24, 32, 48, 64, 128, 256, 512])
    _square(
      'linux/packaging/icons/hicolor/${size}x$size/apps/io.soundspan.app.png',
      size,
      Master.colour,
    ),
  const IconOutput(
    'linux/packaging/icons/hicolor/scalable/apps/io.soundspan.app.svg',
    width: 512,
    height: 512,
    master: Master.colour,
    kind: OutputKind.svgCopy,
  ),
  // Web: favicon and manifest icons.
  _square('web/favicon.png', 32, Master.colour),
  for (final size in [192, 512]) ...[
    _square(
      'web/icons/Icon-$size.png',
      size,
      Master.colour,
      padding: _iconPadding,
      backdrop: Backdrop.square,
    ),
    _square(
      'web/icons/Icon-maskable-$size.png',
      size,
      Master.colour,
      padding: _safeZonePadding,
      backdrop: Backdrop.square,
    ),
  ],
  // Tray: a dark glyph for light panels and a light glyph for dark panels.
  for (final size in [16, 22, 24, 32]) ...[
    _square(
      'assets/brand/tray/tray_light_$size.png',
      size,
      Master.mono,
      glyph: _black,
    ),
    _square('assets/brand/tray/tray_dark_$size.png', size, Master.mono),
  ],
]);

/// The kind of a [MarkShape].
enum ShapeKind {
  /// A `<circle>`.
  circle,

  /// A `<rect>` with rounded corners.
  rect,
}

/// One shape of a master, in 512-grid units.
class MarkShape {
  /// Creates a shape centred on ([cx], [cy]).
  const new({
    required this.kind,
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
    required this.radius,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  /// Circle or rounded rectangle.
  final ShapeKind kind;

  /// Horizontal centre.
  final double cx;

  /// Vertical centre.
  final double cy;

  /// Width of the bounding box.
  final double width;

  /// Height of the bounding box.
  final double height;

  /// The circle radius, or the corner radius of a rectangle.
  final double radius;

  /// The RGB fill, or null for `currentColor` (the output's glyph colour).
  final int? fill;

  /// The RGB outline colour, or null for no outline.
  final int? stroke;

  /// The outline width, centred on the shape's edge.
  final double strokeWidth;

  /// The signed distance from ([x], [y]) to the edge: negative inside.
  double distance(double x, double y) {
    final dx = (x - cx).abs();
    final dy = (y - cy).abs();
    if (kind == ShapeKind.circle) return math.sqrt(dx * dx + dy * dy) - radius;
    final r = math.min(radius, math.min(width, height) / 2);
    final qx = dx - (width / 2 - r);
    final qy = dy - (height / 2 - r);
    final ox = math.max(qx, 0);
    final oy = math.max(qy, 0);
    return math.sqrt(ox * ox + oy * oy) + math.min(math.max(qx, qy), 0) - r;
  }

  /// The extent of the shape and its outline from its centre.
  double get _halfWidth => width / 2 + (stroke == null ? 0 : strokeWidth / 2);
  double get _halfHeight => height / 2 + (stroke == null ? 0 : strokeWidth / 2);
}

/// A parsed master: its shapes in paint order.
class MarkMaster {
  /// Creates a master from [shapes].
  const new(this.shapes);

  /// The shapes, painted in order.
  final List<MarkShape> shapes;
}

const _allowedAttributes = {
  'svg': {'xmlns', 'viewBox', 'role', 'aria-label'},
  'g': {'fill', 'stroke', 'stroke-width'},
  'circle': {'cx', 'cy', 'r', 'fill'},
  'rect': {'x', 'y', 'width', 'height', 'rx', 'fill'},
};

final _tag = RegExp(r'<(/?)([A-Za-z][\w:-]*)((?:\s+[\w:-]+="[^"]*")*)\s*(/?)>');
final _attribute = RegExp(r'([\w:-]+)="([^"]*)"');

/// Parses a master made only of `<circle>` and rounded `<rect>` elements,
/// optionally inside one level of `<g>`, on a 512 grid.
///
/// Throws a [FormatException] naming the first element, attribute or value
/// outside that set, so a change to a master cannot be silently ignored.
MarkMaster parseMaster(String svg) {
  final shapes = <MarkShape>[];
  final open = <String>[];
  String? fill;
  String? stroke;
  String? strokeWidth;
  var position = 0;
  var sawRoot = false;

  while (position < svg.length) {
    final next = svg.indexOf('<', position);
    final text = svg.substring(position, next < 0 ? svg.length : next);
    if (text.trim().isNotEmpty) {
      throw FormatException('unexpected text "${text.trim()}"', svg, position);
    }
    if (next < 0) break;
    final match = _tag.matchAsPrefix(svg, next);
    if (match == null) {
      throw FormatException('unsupported markup', svg, next);
    }
    position = match.end;
    final closing = match[1] == '/';
    final name = match[2]!;
    final selfClosing = match[4] == '/';
    if (closing) {
      if (open.isEmpty || open.last != name) {
        throw FormatException('unexpected </$name>', svg, next);
      }
      open.removeLast();
      if (name == 'g') fill = stroke = strokeWidth = null;
      continue;
    }

    final allowed = _allowedAttributes[name];
    if (allowed == null) {
      throw FormatException('unsupported element <$name>', svg, next);
    }
    final attributes = <String, String>{};
    for (final attribute in _attribute.allMatches(match[3]!)) {
      final key = attribute[1]!;
      if (!allowed.contains(key)) {
        throw FormatException(
          'unsupported attribute $key on <$name>',
          svg,
          next,
        );
      }
      attributes[key] = attribute[2]!;
    }

    switch (name) {
      case 'svg':
        if (sawRoot || open.isNotEmpty) {
          throw FormatException('<svg> must be the only root', svg, next);
        }
        sawRoot = true;
        if (attributes['viewBox'] != '0 0 512 512') {
          throw FormatException('viewBox must be "0 0 512 512"', svg, next);
        }
      case 'g':
        if (open.length != 1) {
          throw FormatException('<g> must be a child of <svg>', svg, next);
        }
        fill = attributes['fill'];
        stroke = attributes['stroke'];
        strokeWidth = attributes['stroke-width'];
      default:
        if (open.isEmpty) {
          throw FormatException('<$name> outside <svg>', svg, next);
        }
        shapes.add(
          _shape(name, attributes, fill, stroke, strokeWidth, svg, next),
        );
    }
    if (!selfClosing) open.add(name);
  }
  if (!sawRoot || open.isNotEmpty) {
    throw FormatException('unterminated or missing <svg>', svg, svg.length);
  }
  return MarkMaster(List.unmodifiable(shapes));
}

MarkShape _shape(
  String name,
  Map<String, String> attributes,
  String? groupFill,
  String? groupStroke,
  String? groupStrokeWidth,
  String svg,
  int offset,
) {
  double number(String key) {
    final value = attributes[key];
    final parsed = value == null ? null : double.tryParse(value);
    if (parsed == null) {
      throw FormatException('<$name> needs a numeric $key', svg, offset);
    }
    return parsed;
  }

  final fill = _colour(attributes['fill'] ?? groupFill, 'fill', svg, offset);
  final stroke = groupStroke == null
      ? null
      : _colour(groupStroke, 'stroke', svg, offset);
  final strokeWidth = groupStrokeWidth == null
      ? 0.0
      : double.tryParse(groupStrokeWidth) ??
            (throw FormatException('stroke-width must be a number', svg));
  if (name == 'circle') {
    final r = number('r');
    return MarkShape(
      kind: ShapeKind.circle,
      cx: number('cx'),
      cy: number('cy'),
      width: r * 2,
      height: r * 2,
      radius: r,
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
    );
  }
  final width = number('width');
  final height = number('height');
  return MarkShape(
    kind: ShapeKind.rect,
    cx: number('x') + width / 2,
    cy: number('y') + height / 2,
    width: width,
    height: height,
    radius: number('rx'),
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
  );
}

final _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

/// Parses `#rrggbb` to RGB, or `currentColor` to null.
int? _colour(String? value, String key, String svg, int offset) {
  if (value == 'currentColor') return null;
  final match = value == null ? null : _hex.firstMatch(value);
  if (match == null) {
    throw FormatException(
      '$key must be #rrggbb or currentColor, got $value',
      svg,
      offset,
    );
  }
  return int.parse(match[1]!, radix: 16);
}

const _samples = 4;

/// Rasterizes [master] as [output] describes, at 4x4 supersampling.
img.Image renderOutput(MarkMaster master, IconOutput output) {
  final width = output.width;
  final height = output.height;
  final side = math.min(width, height).toDouble();
  final grid = side * (1 - 2 * output.padding);
  final scale = grid / 512;
  final originX = (width - grid) / 2;
  final originY = (height - grid) / 2;
  final glyph = output.master == Master.mono ? output.glyph : null;

  // The rounded backdrop of the macOS grid: 824 of 1024, radius 185.4.
  final backdropShape = MarkShape(
    kind: ShapeKind.rect,
    cx: width / 2,
    cy: height / 2,
    width: side * 824 / 1024,
    height: side * 824 / 1024,
    radius: side * 185.4 / 1024,
    fill: background,
    stroke: null,
    strokeWidth: 0,
  );

  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var py = 0; py < height; py++) {
    for (var px = 0; px < width; px++) {
      var alpha = 0;
      var red = 0;
      var green = 0;
      var blue = 0;
      for (var sy = 0; sy < _samples; sy++) {
        for (var sx = 0; sx < _samples; sx++) {
          final x = px + (sx + 0.5) / _samples;
          final y = py + (sy + 0.5) / _samples;
          var colour = switch (output.backdrop) {
            Backdrop.none => null,
            Backdrop.square => background,
            Backdrop.roundedSquare =>
              backdropShape.distance(x, y) <= 0 ? background : null,
          };
          final gx = (x - originX) / scale;
          final gy = (y - originY) / scale;
          for (final shape in master.shapes) {
            if ((gx - shape.cx).abs() > shape._halfWidth ||
                (gy - shape.cy).abs() > shape._halfHeight) {
              continue;
            }
            final d = shape.distance(gx, gy);
            if (shape.stroke != null && d.abs() <= shape.strokeWidth / 2) {
              colour = glyph ?? shape.stroke;
            } else if (d <= 0) {
              colour = glyph ?? shape.fill;
            }
          }
          if (colour == null) continue;
          alpha++;
          red += (colour >> 16) & 0xFF;
          green += (colour >> 8) & 0xFF;
          blue += colour & 0xFF;
        }
      }
      if (alpha == 0) continue;
      image.setPixelRgba(
        px,
        py,
        (red / alpha).round(),
        (green / alpha).round(),
        (blue / alpha).round(),
        (alpha * 255 / (_samples * _samples)).round(),
      );
    }
  }
  return image;
}

/// Encodes [image] as a PNG with only IHDR, IDAT and IEND chunks, RGB when
/// [alpha] is false and RGBA otherwise, compressed with pure-Dart deflate.
Uint8List encodePng(img.Image image, {required bool alpha}) {
  final channels = alpha ? 4 : 3;
  final raw = Uint8List((image.width * channels + 1) * image.height);
  var i = 0;
  for (var y = 0; y < image.height; y++) {
    raw[i++] = 0; // filter: none
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      raw[i++] = pixel.r.toInt();
      raw[i++] = pixel.g.toInt();
      raw[i++] = pixel.b.toInt();
      if (alpha) raw[i++] = pixel.a.toInt();
    }
  }
  final header = ByteData(13)
    ..setUint32(0, image.width)
    ..setUint32(4, image.height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(
      9,
      alpha ? 6 : 2,
    ); // colour type; compression, filter, interlace 0
  final out = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(out, 'IHDR', header.buffer.asUint8List());
  _chunk(out, 'IDAT', const ZLibEncoderWeb().encodeBytes(raw, level: 9));
  _chunk(out, 'IEND', Uint8List(0));
  return out.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typed = Uint8List.fromList([...type.codeUnits, ...data]);
  out
    ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
    ..add(typed)
    ..add((ByteData(4)..setUint32(0, getCrc32(typed))).buffer.asUint8List());
}

/// Encodes a Windows icon holding the PNGs in [images].
Uint8List encodeIco(List<Uint8List> images, List<int> sizes) {
  final header = ByteData(6 + 16 * images.length)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little) // type: icon
    ..setUint16(4, images.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < images.length; i++) {
    final entry = 6 + 16 * i;
    final size = sizes[i] == 256 ? 0 : sizes[i];
    header
      ..setUint8(entry, size)
      ..setUint8(entry + 1, size)
      ..setUint16(entry + 4, 1, Endian.little) // colour planes
      ..setUint16(entry + 6, 32, Endian.little) // bits per pixel
      ..setUint32(entry + 8, images[i].length, Endian.little)
      ..setUint32(entry + 12, offset, Endian.little);
    offset += images[i].length;
  }
  final out = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
  images.forEach(out.add);
  return out.takeBytes();
}

/// The bytes of a PNG or ICO [output] drawn from [master].
Uint8List encodeOutput(MarkMaster master, IconOutput output) {
  switch (output.kind) {
    case OutputKind.png:
      return encodePng(
        renderOutput(master, output),
        alpha: output.backdrop != Backdrop.square,
      );
    case OutputKind.ico:
      return encodeIco([
        for (final size in output.icoSizes)
          encodeOutput(master, output._atSize(size)),
      ], output.icoSizes);
    case OutputKind.svgCopy:
      throw ArgumentError.value(output.path, 'output', 'is a copy');
  }
}

/// Generates every output from the masters under [root] into [outDir] and
/// returns the paths written, relative to [outDir].
List<String> writeIcons(String root, String outDir) {
  final colourSource = File(p.join(root, colourMasterPath)).readAsBytesSync();
  final masters = {
    Master.colour: parseMaster(String.fromCharCodes(colourSource)),
    Master.mono: parseMaster(
      File(p.join(root, monoMasterPath)).readAsStringSync(),
    ),
  };
  return [
    for (final output in iconOutputs)
      _write(
        File(p.join(outDir, output.path)),
        output.kind == OutputKind.svgCopy
            ? colourSource
            : encodeOutput(masters[output.master]!, output),
        output.path,
      ),
  ];
}

String _write(File file, Uint8List bytes, String path) {
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  return path;
}

const _ownedExtensions = {'.png', '.ico', '.svg'};

/// Generates into a temporary directory and compares with the files under
/// [root]. Returns one `<path>: <problem>` line per committed file that
/// differs, is missing, or is an image in an output directory that the table
/// no longer produces. Empty when everything matches.
List<String> checkIcons(String root) {
  final tmp = Directory.systemTemp.createTempSync('gen_icons');
  try {
    final problems = <String>[];
    final produced = writeIcons(root, tmp.path).toSet();
    for (final path in produced) {
      final committed = File(p.join(root, path));
      if (!committed.existsSync()) {
        problems.add('$path: missing');
      } else if (!_same(
        committed.readAsBytesSync(),
        File(p.join(tmp.path, path)).readAsBytesSync(),
      )) {
        problems.add('$path: differs from a fresh run');
      }
    }
    final directories = {for (final path in produced) p.posix.dirname(path)};
    for (final dir in directories) {
      final directory = Directory(p.join(root, dir));
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync().whereType<File>()) {
        final path = p.posix.join(dir, p.basename(entity.path));
        if (_ownedExtensions.contains(p.extension(path)) &&
            !produced.contains(path)) {
          problems.add('$path: no longer generated');
        }
      }
    }
    return problems..sort();
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Runs the tool with [args] and returns the exit code.
Future<int> runGenIcons(List<String> args) async {
  var check = false;
  var root = Directory.current.path;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--check':
        check = true;
      case '--root' when i + 1 < args.length:
        root = args[++i];
      default:
        stderr.writeln(
          'usage: dart run tool/gen_icons.dart [--check] [--root <dir>]',
        );
        return 64;
    }
  }
  try {
    if (!check) {
      final written = writeIcons(root, root);
      stdout.writeln('gen_icons: wrote ${written.length} files');
      return 0;
    }
    final problems = checkIcons(root);
    if (problems.isEmpty) {
      stdout.writeln('gen_icons: every icon matches a fresh run');
      return 0;
    }
    stdout
      ..writeln('gen_icons: run `dart run tool/gen_icons.dart` and commit:')
      ..writeAll(problems.map((line) => '  $line\n'));
    return 1;
  } on FormatException catch (error) {
    stderr.writeln('gen_icons: invalid master: ${error.message}');
    return 1;
  }
}

Future<void> main(List<String> args) async {
  exitCode = await runGenIcons(args);
}
