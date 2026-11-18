import axios from "axios";

/** A podcast from the iTunes directory, as `DiscoverResult` with `type: "podcast"`. */
export interface DirectoryPodcastResult {
    type: "podcast";
    id: string;
    itunesId: number;
    name: string;
    artist: string;
    description: string;
    coverUrl: string;
    feedUrl: string;
    genres: string[];
    trackCount: number;
}

/** Searches the iTunes podcast directory; throws when the request fails. */
export async function searchItunesPodcasts(
    query: string,
    limit: number,
): Promise<DirectoryPodcastResult[]> {
    const response = await axios.get("https://itunes.apple.com/search", {
        params: {
            term: query,
            media: "podcast",
            entity: "podcast",
            limit,
        },
        timeout: 5000,
    });
    return response.data.results.map((podcast: any) => ({
        type: "podcast",
        id: podcast.collectionId.toString(),
        itunesId: podcast.collectionId,
        name: podcast.collectionName,
        artist: podcast.artistName,
        description: podcast.description,
        coverUrl: podcast.artworkUrl600 || podcast.artworkUrl100,
        feedUrl: podcast.feedUrl,
        genres: podcast.genres || [],
        trackCount: podcast.trackCount,
    }));
}
