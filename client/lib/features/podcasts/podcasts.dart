// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Podcasts: the subscribed podcasts, podcast detail, subscribing and
/// episode progress (doc 03, Podcasts).
library;

export 'domain/podcast_detail.dart' show PodcastDetail;
export 'domain/podcast_ref.dart'
    show FeedPodcastRef, ItunesPodcastRef, PodcastRef;
export 'domain/podcast_repository.dart' show PodcastRepository;
