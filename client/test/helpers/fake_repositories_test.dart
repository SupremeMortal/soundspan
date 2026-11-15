// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import 'fake_repositories.dart';
import 'pump_app.dart';

void main() {
  test('`FakePagedSource` reports total before pages, records requested pages '
      'and can fail a page', () async {
    final source = FakePagedSource<int>(
      total: 250,
      itemBuilder: (index) => index * 10,
      failingPages: {2},
      failure: const ServerError(),
    );
    addTearDown(source.dispose);
    final snapshots = <PagedSnapshot<int>>[];
    source.watch().listen(snapshots.add);
    await pumpEventQueue();

    expect(snapshots.single.total, 250);
    expect(snapshots.single.itemAt(0), isNull);

    source.ensureVisible(0, 10);
    await pumpEventQueue();
    expect(source.requestedPages, [0, 1]);
    expect(snapshots.last.itemAt(0), 0);
    expect(snapshots.last.itemAt(199), 1990);
    expect(snapshots.last.itemAt(200), isNull);

    source.ensureVisible(150, 160);
    await pumpEventQueue();
    expect(source.requestedPages, [0, 1, 2]);
    expect(snapshots.last.refreshError, isA<ServerError>());
    expect(snapshots.last.itemAt(199), 1990);
    expect(snapshots.last.itemAt(200), isNull);
  });

  testWidgets('`pumpApp` supplies the fakes by default', (tester) async {
    final container = await tester.pumpApp(const SizedBox());

    expect(
      await container.read(libraryRepositoryProvider.future),
      isA<FakeLibraryRepository>(),
    );
    expect(
      await container.read(playlistRepositoryProvider.future),
      isA<FakePlaylistRepository>(),
    );
    expect(
      await container.read(homeRepositoryProvider.future),
      isA<FakeHomeRepository>(),
    );
    expect(
      await container.read(searchRepositoryProvider.future),
      isA<FakeSearchRepository>(),
    );
  });

  testWidgets('a test can seed its own fakes through `overrides`', (
    tester,
  ) async {
    final fakes = FakeRepositories();
    fakes.library.albumList = const [
      Album(id: 'al-1', title: 'Album', artistName: 'Artist', artistId: 'a'),
    ];
    final container = await tester.pumpApp(
      const SizedBox(),
      overrides: fakes.overrides,
    );

    final library = await container.read(libraryRepositoryProvider.future);
    expect(library, same(fakes.library));
    final source = library.albums(const AlbumQuery());
    expect(source.pageSize, gridPageSize);
    expect(fakes.library.queries, [const AlbumQuery()]);
    source.dispose();
  });
}
