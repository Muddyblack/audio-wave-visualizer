"""Now-playing for the Windows overlay: what MPRIS provides on Linux.

Windows' media sessions (GlobalSystemMediaTransportControls, the API behind
the media flyout next to the volume slider) are where Spotify, browsers, VLC
and the Media Player app publish title, artist, cover, timeline and controls.
This polls them on a background asyncio loop and exposes the chosen session
to QML shaped like Quickshell's MprisPlayer — trackTitle, trackArtist,
trackArtUrl, position in seconds (assigning it seeks), togglePlaying() and so
on — so the shared VisualizerView, TransportDock and PlaybackClock take it
exactly as they take a player on Hyprland.

Off Windows, or without the winrt packages, `available` is false and there is
never a player; the overlay then falls back to always showing the bars.
"""

import asyncio
import gc
import hashlib
import threading
import time
from datetime import UTC, datetime
from pathlib import Path

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot

POLL_SECONDS = 0.5
PLAYING = 4  # GlobalSystemMediaTransportControlsSessionPlaybackStatus.PLAYING


def _identity(app_id: str) -> str:
    """A readable player name from an AppUserModelID.

    "Spotify.exe" -> "Spotify", "Microsoft.ZuneMusic_8wekyb3d8bbwe!App" ->
    "ZuneMusic"; plain ids such as "Chrome" pass through.
    """
    name = app_id.split("!")[0]
    if name.lower().endswith(".exe"):
        name = name[:-4]
    if "_" in name:
        name = name.split("_")[0].split(".")[-1]
    return name


async def _read_thumbnail(reference) -> bytes:
    from winrt.windows.storage.streams import Buffer, InputStreamOptions

    stream = await reference.open_read_async()
    buffer = Buffer(stream.size)
    await stream.read_async(buffer, buffer.capacity, InputStreamOptions.READ_AHEAD)
    return bytes(buffer)


class MediaPlayer(QObject):
    """The session the overlay follows, as an MPRIS-like player object."""

    changed = Signal()

    def __init__(self, sessions: "MediaSessions"):
        super().__init__()
        self._sessions = sessions
        self._state: dict = {}
        self._synced_at = time.monotonic()

    def update(self, state: dict) -> None:
        # Every property shares one notify signal, and everything showing the
        # player (the overlay, each settings preview tile) re-evaluates on it,
        # so only emit for a real change. Position moving as predicted is not
        # one — the getter extrapolates — but a jump (a seek, a new track) is.
        drift = abs(state.get("position", 0.0) - self._position())
        unchanged = {k: v for k, v in state.items() if k != "position"} == {
            k: v for k, v in self._state.items() if k != "position"
        } and drift < 1.5
        self._state = state
        self._synced_at = time.monotonic()
        if not unchanged:
            self.changed.emit()

    def _get(self, key, default):
        return self._state.get(key, default)

    def _position(self) -> float:
        # Players report the timeline only every few seconds; between reports
        # it keeps moving, so extrapolate while playing.
        position = self._get("position", 0.0)
        if self._get("playing", False):
            position += time.monotonic() - self._synced_at
        length = self._get("length", 0.0)
        return min(position, length) if length > 0 else position

    def _seek(self, seconds: float) -> None:
        self._state["position"] = seconds
        self._synced_at = time.monotonic()
        self._sessions.command(self._get("id", ""), "seek", seconds)
        self.changed.emit()

    def _metadata(self) -> dict:
        metadata = {
            "xesam:title": self._get("title", ""),
            "xesam:artist": [self._get("artist", "")],
            "xesam:album": self._get("album", ""),
            "mpris:trackid": f"{self._get('id', '')}:{self._get('title', '')}",
            "mpris:length": int(self._get("length", 0.0) * 1_000_000),
        }
        if self._get("trackNumber", 0):
            metadata["xesam:trackNumber"] = self._get("trackNumber", 0)
        if self._get("genres", []):
            metadata["xesam:genre"] = self._get("genres", [])
        return metadata

    identity = Property(str, lambda self: self._get("identity", ""), notify=changed)
    desktopEntry = Property(str, lambda self: "", notify=changed)
    isPlaying = Property(bool, lambda self: self._get("playing", False), notify=changed)
    trackTitle = Property(str, lambda self: self._get("title", ""), notify=changed)
    trackArtist = Property(str, lambda self: self._get("artist", ""), notify=changed)
    trackAlbum = Property(str, lambda self: self._get("album", ""), notify=changed)
    trackArtUrl = Property(str, lambda self: self._get("artUrl", ""), notify=changed)
    length = Property(float, lambda self: self._get("length", 0.0), notify=changed)
    position = Property(float, _position, _seek, notify=changed)
    canControl = Property(bool, lambda self: True, notify=changed)
    canSeek = Property(bool, lambda self: self._get("canSeek", False), notify=changed)
    positionSupported = Property(
        bool, lambda self: self._get("canSeek", False), notify=changed
    )
    canTogglePlaying = Property(
        bool, lambda self: self._get("canToggle", False), notify=changed
    )
    canGoNext = Property(bool, lambda self: self._get("canNext", False), notify=changed)
    canGoPrevious = Property(
        bool, lambda self: self._get("canPrevious", False), notify=changed
    )
    metadata = Property("QVariantMap", _metadata, notify=changed)

    @Slot()
    def togglePlaying(self) -> None:
        self._sessions.command(self._get("id", ""), "toggle")

    @Slot()
    def next(self) -> None:
        self._sessions.command(self._get("id", ""), "next")

    @Slot()
    def previous(self) -> None:
        self._sessions.command(self._get("id", ""), "previous")


class MediaSessions(QObject):
    """All media sessions, and the one the overlay shows (`player`)."""

    changed = Signal()
    _polled = Signal(object, str)

    def __init__(self, cover_dir: Path):
        super().__init__()
        self._cover_dir = cover_dir
        self._snapshot: list[dict] = []
        self._pinned = ""
        self._current = ""
        self._player = MediaPlayer(self)
        self._has_player = False
        self._count = 0
        self._loop: asyncio.AbstractEventLoop | None = None
        self._sessions: dict = {}
        self._covers: dict = {}
        self._available = False
        # Emitted from the polling thread; Qt queues it onto this object's.
        self._polled.connect(self._apply)
        try:
            import winrt.windows.media.control  # noqa: F401
        except ImportError:
            return
        self._available = True
        self._loop = asyncio.new_event_loop()
        threading.Thread(
            target=self._loop.run_forever, name="media-sessions", daemon=True
        ).start()
        self._polling = asyncio.run_coroutine_threadsafe(
            self._poll_forever(), self._loop
        )

    def stop(self) -> None:
        if self._loop is None:
            return
        # WinRT objects must be released on the thread that made them: freed
        # by the main thread's garbage collector at exit they fail with
        # RPC_E_WRONG_THREAD (0x8001010e) and a fatal-exception dump.
        try:
            asyncio.run_coroutine_threadsafe(self._shutdown(), self._loop).result(2)
        except Exception:  # noqa: BLE001 — quitting anyway
            pass
        self._loop.call_soon_threadsafe(self._loop.stop)
        self._loop = None

    async def _shutdown(self) -> None:
        self._polling.cancel()
        await asyncio.sleep(0)  # Let the cancelled poll unwind, dropping its manager.
        self._sessions = {}
        # Reference cycles (tracebacks of a session that closed mid-poll hold
        # its frames) would otherwise reach the main thread's collector.
        gc.collect()

    # --- QML side -----------------------------------------------------------

    available = Property(bool, lambda self: self._available, constant=True)
    player = Property(
        QObject, lambda self: self._player if self._has_player else None, notify=changed
    )
    playerCount = Property(int, lambda self: self._count, notify=changed)

    @Slot()
    def cyclePlayer(self) -> None:
        """The player switcher: pin the next session, like Hyprland's."""
        ids = [entry["id"] for entry in self._snapshot]
        if not ids:
            return
        shown = self._player._get("id", "")
        index = ids.index(shown) if shown in ids else -1
        self._pinned = ids[(index + 1) % len(ids)]
        self._apply(self._snapshot, self._current)

    def _apply(self, snapshot: list[dict], current: str = "") -> None:
        self._snapshot = snapshot
        self._current = current
        by_id = {entry["id"]: entry for entry in snapshot}
        # A pinned player wins; otherwise follow the one playing, then the one
        # Windows itself considers current (what the media flyout shows).
        chosen = (
            by_id.get(self._pinned)
            or next((entry for entry in snapshot if entry["playing"]), None)
            or by_id.get(current)
            or (snapshot[0] if snapshot else None)
        )
        if chosen is not None:
            self._player.update(dict(chosen))
        before = (self._has_player, self._count)
        self._has_player = chosen is not None
        self._count = len(snapshot)
        if (self._has_player, self._count) != before:
            self.changed.emit()

    # --- polling thread -----------------------------------------------------

    def command(self, session_id: str, action: str, value: float = 0.0) -> None:
        if self._loop is not None and session_id:
            asyncio.run_coroutine_threadsafe(
                self._command(session_id, action, value), self._loop
            )

    async def _command(self, session_id: str, action: str, value: float) -> None:
        session = self._sessions.get(session_id)
        if session is None:
            return
        try:
            if action == "toggle":
                await session.try_toggle_play_pause_async()
            elif action == "next":
                await session.try_skip_next_async()
            elif action == "previous":
                await session.try_skip_previous_async()
            elif action == "seek":
                # TimeSpan ticks are 100 ns.
                await session.try_change_playback_position_async(int(value * 1e7))
        except OSError:
            pass  # The session closed between the click and the call.

    async def _poll_forever(self) -> None:
        from winrt.windows.media.control import (
            GlobalSystemMediaTransportControlsSessionManager as Manager,
        )

        manager = None
        while True:
            try:
                if manager is None:
                    manager = await Manager.request_async()
                await self._poll(manager)
            except Exception:  # noqa: BLE001 — a flaky player must not end polling
                manager = None
            await asyncio.sleep(POLL_SECONDS)

    async def _poll(self, manager) -> None:
        current = manager.get_current_session()
        sessions = {s.source_app_user_model_id: s for s in manager.get_sessions()}
        self._sessions = sessions
        snapshot = []
        for session_id, session in sessions.items():
            try:
                snapshot.append(await self._describe(session_id, session))
            except Exception:  # noqa: BLE001, S112 — skip a session that just closed
                continue
        self._polled.emit(snapshot, current.source_app_user_model_id if current else "")

    async def _describe(self, session_id: str, session) -> dict:
        properties = await session.try_get_media_properties_async()
        info = session.get_playback_info()
        timeline = session.get_timeline_properties()
        controls = info.controls
        length = (timeline.end_time - timeline.start_time).total_seconds()
        position = (timeline.position - timeline.start_time).total_seconds()
        playing = info.playback_status == PLAYING
        updated = timeline.last_updated_time
        if playing and updated and updated.year > 1601:
            position += max(0.0, (datetime.now(UTC) - updated).total_seconds())
        return {
            "id": session_id,
            "identity": _identity(session_id),
            "title": properties.title or "",
            "artist": properties.artist or properties.album_artist or "",
            "album": properties.album_title or "",
            "trackNumber": properties.track_number or 0,
            "genres": list(properties.genres or []),
            "playing": playing,
            "length": max(0.0, length),
            "position": max(0.0, position),
            "canSeek": bool(controls.is_playback_position_enabled) and length > 0,
            "canToggle": bool(controls.is_play_pause_toggle_enabled),
            "canNext": bool(controls.is_next_enabled),
            "canPrevious": bool(controls.is_previous_enabled),
            "artUrl": await self._cover(session_id, properties),
        }

    async def _cover(self, session_id: str, properties) -> str:
        """The track's cover as a file URL, fetched once per track."""
        key = (properties.title, properties.artist, properties.album_title)
        cached = self._covers.get(session_id)
        if cached and cached[0] == key:
            return cached[1]
        url = ""
        if properties.thumbnail is not None:
            data = await _read_thumbnail(properties.thumbnail)
            if data:
                suffix = ".png" if data.startswith(b"\x89PNG") else ".jpg"
                # Named by content: a new name per cover, so QML's Image cache
                # never shows the previous track's art for a reused path.
                name = "cover-" + hashlib.sha1(data).hexdigest()[:16] + suffix
                path = self._cover_dir / name
                if not path.exists():
                    path.write_bytes(data)
                url = QUrl.fromLocalFile(str(path)).toString()
        self._covers[session_id] = (key, url)
        # Drop the previous cover unless another session still shows it.
        if (
            cached
            and cached[1]
            and cached[1] != url
            and all(entry[1] != cached[1] for entry in self._covers.values())
        ):
            Path(QUrl(cached[1]).toLocalFile()).unlink(missing_ok=True)
        return url
