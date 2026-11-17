// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/refresh_target.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// Builds the slivers of a detail page from its loaded [value].
typedef DetailSliversBuilder<T> = List<Widget> Function(
  BuildContext context,
  T value,
);

/// The states of an album, artist or playlist page (doc 09; doc 05, Read
/// Policy).
///
/// While the first value loads: a [DetailHeaderSkeleton] over skeleton
/// rows. With nothing cached and the read failed: an [ErrorView]. With a
/// value: the [builder]'s slivers, with pull-to-refresh calling
/// [onRefresh]. When a refresh fails, the value stays on screen and a
/// snackbar says so.
class DetailPage<T> extends StatefulWidget {
  /// Creates the page of [value].
  const new({
    required this.value,
    required this.builder,
    required this.onRefresh,
    this.refreshError,
    this.onRetry,
    this.thumbnails = false,
    super.key,
  });

  /// The page's read.
  final AsyncValue<T> value;

  /// Why the shown value could not be refreshed, such as a cached read's
  /// `refreshError`; a new one shows the refresh snackbar.
  final Object? refreshError;

  /// Builds the header and content slivers.
  final DetailSliversBuilder<T> builder;

  /// Fetches the value again; a throw shows the refresh snackbar.
  final Future<void> Function() onRefresh;

  /// Reads again after an error; null hides the error view's Retry.
  final VoidCallback? onRetry;

  /// Whether the skeleton rows have thumbnails.
  final bool thumbnails;

  /// How many skeleton rows stand for the content while it loads.
  static const int skeletonRows = 8;

  @override
  State<DetailPage<T>> createState() => _DetailPageState<T>();
}

class _DetailPageState<T> extends State<DetailPage<T>> {
  @override
  void didUpdateWidget(DetailPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = _refreshError(widget);
    if (error != null && error != _refreshError(oldWidget)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFailure());
    }
  }

  /// Why the shown value of [page] could not be refreshed, or null.
  static Object? _refreshError<V>(DetailPage<V> page) {
    if (!page.value.hasValue) return null;
    if (page.value.hasError) return page.value.error;
    return page.refreshError;
  }

  void _showFailure() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).detailRefreshFailed)),
    );
  }

  Future<void> _refresh() async {
    try {
      await widget.onRefresh();
    } on Exception {
      _showFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value.hasValue) {
      return AppRefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: widget.builder(context, value.requireValue),
        ),
      );
    }
    if (value.hasError) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading:
                WindowClass.of(context) != WindowClass.expanded,
            scrolledUnderElevation: 0,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(error: value.error!, onRetry: widget.onRetry),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const DetailHeaderSkeleton(),
        SliverList.builder(
          itemCount: DetailPage.skeletonRows,
          itemBuilder: (context, _) =>
              TrackRowSkeleton(withThumbnail: widget.thumbnails),
        ),
      ],
    );
  }
}
