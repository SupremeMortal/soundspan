import assert from "node:assert/strict";
import test from "node:test";
import {
    albumCoverProvidersUpdate,
    artistImageProvidersUpdate,
    insertProvider,
    moveProvider,
    parseProviderList,
    playbackProvidersUpdate,
    removeProvider,
    searchProvidersUpdate,
} from "../../features/settings/providerPriority";

const KNOWN = ["a", "b", "c", "d"] as const;

test("parseProviderList keeps known providers once, in stored order", () => {
    assert.deepEqual(parseProviderList(" c, a,x,c ,b", KNOWN), ["c", "a", "b"]);
});

test("parseProviderList treats a missing or empty value as no providers", () => {
    assert.deepEqual(parseProviderList(undefined, KNOWN), []);
    assert.deepEqual(parseProviderList("", KNOWN), []);
});

test("moveProvider moves one entry to a new index", () => {
    assert.deepEqual(moveProvider(["a", "b", "c"], 0, 2), ["b", "c", "a"]);
    assert.deepEqual(moveProvider(["a", "b", "c"], 2, 0), ["c", "a", "b"]);
});

test("moveProvider ignores out-of-range indexes", () => {
    assert.deepEqual(moveProvider(["a", "b"], 0, 5), ["a", "b"]);
    assert.deepEqual(moveProvider(["a", "b"], -1, 0), ["a", "b"]);
});

test("insertProvider adds a new provider at the drop index", () => {
    assert.deepEqual(insertProvider(["a", "c"], "b", 1), ["a", "b", "c"]);
    assert.deepEqual(insertProvider(["a"], "b", 9), ["a", "b"]);
});

test("insertProvider re-places a provider that is already active", () => {
    // Dropping "a" at index 3 (after "c") of the list as rendered.
    assert.deepEqual(insertProvider(["a", "b", "c"], "a", 3), ["b", "c", "a"]);
    assert.deepEqual(insertProvider(["a", "b", "c"], "c", 0), ["c", "a", "b"]);
});

test("removeProvider drops the provider", () => {
    assert.deepEqual(removeProvider(["a", "b"], "a"), ["b"]);
});

test("playbackProvidersUpdate stores the order and syncs each enable flag", () => {
    assert.deepEqual(playbackProvidersUpdate(["soulseek", "tidal"]), {
        playbackProviders: "soulseek,tidal",
        tidalEnabled: true,
        ytMusicEnabled: false,
        lidarrEnabled: false,
    });
    assert.deepEqual(playbackProvidersUpdate(["lidarr", "ytmusic"]), {
        playbackProviders: "lidarr,ytmusic",
        tidalEnabled: false,
        ytMusicEnabled: true,
        lidarrEnabled: true,
    });
});

test("searchProvidersUpdate keeps a full order with inactive providers last", () => {
    assert.deepEqual(
        searchProvidersUpdate(
            ["tidal", "lastfm"],
            "lastfm,deezer,tidal,youtube",
        ),
        {
            searchProviderOrder: "tidal,lastfm,deezer,youtube",
            searchProvidersEnabled: "tidal,lastfm",
        },
    );
    assert.deepEqual(searchProvidersUpdate([], undefined), {
        searchProviderOrder: "lastfm,deezer,tidal,youtube",
        searchProvidersEnabled: "",
    });
});

test("metadata updates turn Fanart.tv on while either list uses it", () => {
    assert.deepEqual(
        artistImageProvidersUpdate(["deezer"], "coverartarchive,fanart"),
        { artistImageProviders: "deezer", fanartEnabled: true },
    );
    assert.deepEqual(
        albumCoverProvidersUpdate(["coverartarchive"], "wikidata,deezer"),
        { albumCoverProviders: "coverartarchive", fanartEnabled: false },
    );
    assert.deepEqual(artistImageProvidersUpdate(["fanart"], ""), {
        artistImageProviders: "fanart",
        fanartEnabled: true,
    });
});
