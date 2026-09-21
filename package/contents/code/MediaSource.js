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
