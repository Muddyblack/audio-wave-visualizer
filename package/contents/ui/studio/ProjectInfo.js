// Shared project links and optional network statistics for both Studios.
var name = "Plasma Audio Visualizer";
var author = "Muddyblack";
var repository = "https://github.com/Muddyblack/kde-audio-visualizer";
var profile = "https://github.com/Muddyblack";
var avatar = "https://github.com/Muddyblack.png?size=128";
var store = "https://www.opendesktop.org/p/2359422";
var links = [
    ["GitHub", repository], ["OpenDesktop / KDE Store", store],
    ["Report an issue", repository + "/issues"], ["Releases", repository + "/releases"]
];
var statistics = [
    {id: "stars", label: "GitHub stars", url: "https://img.shields.io/github/stars/Muddyblack/kde-audio-visualizer.json"},
    {id: "downloads", label: "GitHub downloads", url: "https://img.shields.io/github/downloads/Muddyblack/kde-audio-visualizer/total.json"},
    {id: "kde", label: "OpenDesktop downloads", url: "https://img.shields.io/badge/dynamic/json.json?url=" + encodeURIComponent("https://api.pling.com/ocs/v1/content/data?search=audio+wave+visualizer&format=json") + "&query=" + encodeURIComponent("$.data[0].downloads") + "&label=Downloads"}
];
function count(text) {
    try {
        var badge = JSON.parse(text);
        var value = String(badge.value === undefined ? "" : badge.value).trim();
        return !badge.isError && /^\d[\d,. ]*[kmbt]?\+?$/i.test(value) ? value : "";
    } catch (error) { return ""; }
}
