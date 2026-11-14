// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

/// Serves `build/web` on the port given as the first argument (default 8080)
/// without Cross-Origin-Opener-Policy or Cross-Origin-Embedder-Policy headers
/// (doc 10, Web: "No COOP/COEP").
Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);
  final root = Directory('build/web').absolute.path;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('serving $root on http://localhost:$port/');
  await for (final request in server) {
    var path = Uri.decodeComponent(request.uri.path);
    if (path.endsWith('/')) path = '${path}index.html';
    final file = File('$root$path');
    final response = request.response;
    if (path.contains('..') || !file.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      continue;
    }
    response.headers
      ..contentType = _contentType(path)
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    await response.addStream(file.openRead());
    await response.close();
  }
}

ContentType _contentType(String path) {
  final extension = path.substring(path.lastIndexOf('.') + 1);
  return switch (extension) {
    'html' => ContentType.html,
    'js' || 'mjs' => ContentType('text', 'javascript', charset: 'utf-8'),
    'wasm' => ContentType('application', 'wasm'),
    'json' => ContentType.json,
    'png' => ContentType('image', 'png'),
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    _ => ContentType.binary,
  };
}
