// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/playlist_list.dart';
import 'package:soundspan/shared/providers/repositories.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  test('a source whose reader left while the repository was opening is '
      'disposed without an error', () async {
    final repository = FakePlaylistRepository();
    final opening = Completer<PlaylistRepository>();
    final container = ProviderContainer.test(
      overrides: [
        playlistRepositoryProvider.overrideWith((ref) => opening.future),
      ],
    );
    final errors = <Object>[];

    await runZonedGuarded(() async {
      final subscription = container.listen(
        playlistListSourceProvider,
        (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      subscription.close();
      await Future<void>.delayed(Duration.zero);

      opening.complete(repository);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }, (error, _) => errors.add(error));

    expect(errors, isEmpty);
    expect(repository.sources.every((s) => s.disposed), isTrue);
  });

  test('a source read to the end is disposed when its last reader '
      'leaves', () async {
    final repository = FakePlaylistRepository();
    final container = ProviderContainer.test(
      overrides: [
        playlistRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    final subscription = container.listen(
      playlistListSourceProvider,
      (_, _) {},
    );
    await container.read(playlistListSourceProvider.future);
    expect(repository.sources.single.disposed, isFalse);

    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(repository.sources.single.disposed, isTrue);
  });
}
