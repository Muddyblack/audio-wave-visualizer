// Read the metadata bridge as well as host properties: browser players can leave
// the convenience artist/album fields empty while MPRIS still supplies them.
function payload(view) {
    var metadata = view.metadata || {};
    function text(value) { return Array.isArray(value) ? value.join(', ') : String(value || ''); }
    var time = String(view.lengthText || '').split(':').map(Number);
    var duration = time.length === 2 && time.every(isFinite) ? time[0] * 60 + time[1] : 0;
    return {track: view.track || text(metadata['xesam:title']),
        artist: view.artist || text(metadata['xesam:artist']),
        album: view.album || text(metadata['xesam:album']),
        duration: duration, apple: !!view.configuration?.appleTrackInfo};
}
function notice(status, result) {
    if (status === 'loading') return qsTr('Looking up song details…');
    if (status === 'error') return qsTr('The information services could not be reached. Try again.');
    if (result.partial) return qsTr('Some details could not be loaded. You can retry.');
    if (result.reason === 'ambiguous') return result.candidates?.length ? qsTr('Several recordings match. Choose a version below if you know which one is playing.') : qsTr('Too many recordings match. More artist or album metadata is needed.');
    if (status === 'empty') return result.reason === 'metadata'
        ? qsTr('The player needs to supply an artist or a song title and length.')
        : qsTr('No extra catalog details found for this song. Available player information is shown above.');
    if (result.matchBasis === 'duration') return qsTr('Matched by title and length; the player supplied no artist.');
    return '';
}
