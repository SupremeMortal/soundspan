import assert from "node:assert/strict";
import test from "node:test";
import { ADMIN_TABS, resolveAdminTab } from "../../features/settings/adminTabs";

test("admin tabs are listed in display order", () => {
    assert.deepEqual(
        ADMIN_TABS.map((tab) => tab.id),
        ["playback", "search", "metadata", "insights", "users", "system"],
    );
});

test("a tab hash opens that tab", () => {
    assert.equal(resolveAdminTab("#metadata"), "metadata");
    assert.equal(resolveAdminTab("users"), "users");
});

test("old section anchors open the tab that now holds the section", () => {
    assert.equal(resolveAdminTab("#download-services"), "playback");
    assert.equal(resolveAdminTab("#storage"), "playback");
    assert.equal(resolveAdminTab("#federation"), "playback");
    assert.equal(resolveAdminTab("#search-providers"), "search");
    assert.equal(resolveAdminTab("#ai-services"), "metadata");
    assert.equal(resolveAdminTab("#cache"), "metadata");
    assert.equal(resolveAdminTab("#library-health"), "insights");
    assert.equal(resolveAdminTab("#queue-dashboard"), "insights");
    assert.equal(resolveAdminTab("#backup"), "system");
});

test("an unknown or empty hash opens the first tab", () => {
    assert.equal(resolveAdminTab(""), "playback");
    assert.equal(resolveAdminTab("#nope"), "playback");
});
