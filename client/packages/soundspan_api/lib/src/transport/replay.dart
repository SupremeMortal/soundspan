// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/transport/base_url_guard.dart';

/// Marks a request that must be sent without a credential.
const anonymousExtra = 'anonymous';

/// Marks a request the retry interceptor must never retry.
const noRetryExtra = 'noRetry';

/// Sends [failed] again through the whole interceptor chain of [dio], with
/// [extra] merged into its extras, so the replay carries the current
/// credential.
///
/// A failure of the replay comes back as a [DioException] whose
/// [DioException.error] is the `ApiException` (or guard [Error]) the
/// replay ended with, ready for an interceptor handler's `reject`.
Future<Response<dynamic>> replay(
  Dio dio,
  RequestOptions failed,
  Map<String, Object?> extra,
) async {
  final options = failed.copyWith(
    path: failed.extra[requestPathExtra] as String? ?? failed.path,
    extra: {...failed.extra, ...extra},
  );
  try {
    return await dio.fetch<dynamic>(options);
  } on DioException {
    rethrow;
  } on Object catch (error, stackTrace) {
    throw DioException(
      requestOptions: options,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
