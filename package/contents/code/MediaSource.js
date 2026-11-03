// Browser MPRIS players identify the browser, while xesam:url can identify
// the site that supplied the media. Keep the browser name when no page URL is
// available; titles and artwork are not reliable evidence of the source.
function isBrowser(identity, desktopEntry, dbusName) {
    return [identity, desktopEntry, dbusName].some(value =>
        /(?:^|[^a-z])(firefox|zen|chromium|chrome|brave|vivaldi|opera|edge|librewolf|floorp|waterfox|epiphany|falkon|qutebrowser)(?:[^a-z]|$)/i.test(String(value ?? ""))
    );
}

function siteHost(identity, desktopEntry, dbusName, metadata) {
    if (!isBrowser(identity, desktopEntry, dbusName))
        return "";
    const url = String(metadata?.["xesam:url"] ?? "");
    const match = url.match(/^https?:\/\/([^/?#]+)/i);
    if (!match)
        return "";
    return match[1].toLowerCase().replace(/:\d+$/, "");
}

function displayName(identity, desktopEntry, dbusName, metadata) {
    const host = siteHost(identity, desktopEntry, dbusName, metadata).replace(/^www\./, "");
    if (host === "music.youtube.com")
        return "YouTube Music";
    if (host === "youtube.com" || host === "youtu.be")
        return "YouTube";
    if (host === "soundcloud.com")
        return "SoundCloud";
    if (host === "bandcamp.com" || host.endsWith(".bandcamp.com"))
        return "Bandcamp";
    if (host === "open.spotify.com")
        return "Spotify";
    if (host === "music.apple.com")
        return "Apple Music";
    if (host === "music.amazon.com" || host === "music.amazon.de" || host === "music.amazon.co.uk")
        return "Amazon Music";
    if (host === "mixcloud.com")
        return "Mixcloud";
    if (host === "deezer.com")
        return "Deezer";
    if (host === "listen.tidal.com" || host === "tidal.com")
        return "TIDAL";
    return host || identity || "";
}

// Browsers report CanGoNext/CanGoPrevious as false for most YouTube pages even
// though the page handles the key, and the flag can flicker while seeking.
// Always let the user try the skip on a browser; the call is a no-op if unused.
function canSkip(player, flag) {
    if (!player)
        return false;
    if (isBrowser(player.identity, player.desktopEntry, player.dbusName))
        return player.canControl !== false;
    return flag !== false;
}

// The video ID of a YouTube or YouTube Music page, or "".
function youtubeId(url) {
    const match = String(url ?? "").match(/^https?:\/\/(?:www\.|m\.|music\.)?(?:youtube\.com\/(?:watch\?(?:[^#]*&)?v=|shorts\/|embed\/|live\/)|youtu\.be\/)([A-Za-z0-9_-]{11})(?![A-Za-z0-9_-])/i);
    return match ? match[1] : "";
}

// YouTube Music hands the browser a zoomed-in crop of the video thumbnail,
// so text at its top and bottom is lost. YouTube's own thumbnails, largest
// first: maxresdefault (1280x720) is missing for some videos; mqdefault
// (320x180) always exists. Both are 16:9 without the black bars hqdefault and
// sddefault add.
function youtubeThumbnails(url) {
    const id = youtubeId(url);
    return id ? ["maxresdefault", "mqdefault"].map(name => "https://i.ytimg.com/vi/" + id + "/" + name + ".jpg") : [];
}
