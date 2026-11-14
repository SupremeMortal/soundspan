// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/database_too_new_exception.dart';

void main() {
  test('names the database and both versions', () {
    const e = DatabaseTooNewException('app.db', 3, 1);
    expect((e.database, e.found, e.supported), ('app.db', 3, 1));
    expect(
      e.toString(),
      'DatabaseTooNewException: app.db is at schema version 3; '
      'this build supports up to 1',
    );
  });
}
