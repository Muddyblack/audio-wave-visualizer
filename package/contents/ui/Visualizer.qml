import QtQuick
import QtCore
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: vis

    property int numBars: plasmoid.configuration.numBars
    property real maxRange: 1000.0
    property var bars: Array(numBars).fill(0)
    // Audio capture is independent of MPRIS: browsers and other apps can emit
    // sound without the selected media player reporting playback.
    property bool active: true
    readonly property bool hasAudio: bars.some(value => value > idleThreshold)
    property int idleCounter: 0
    property bool restarting: false

    // plasmoid.visible is undefined inside plasmoidviewer (only the real shell
    // sets it), which makes `running: active && plasmoid.visible` evaluate to
    // undefined → timers never start → no data → frozen idle line. Coerce to a
    // real bool, defaulting to visible when the property is absent.
    readonly property bool plasmoidVisible: (plasmoid.visible === undefined) ? true : plasmoid.visible

    readonly property string feederPath: Qt.resolvedUrl("../code/feeder.sh").toString().replace(/^file:\/\//, "")

    Plasma5Support.DataSource {
        id: feederLauncher
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source);
        }
        function spawnCommand() {
            const args = [plasmoid.configuration.numBars, plasmoid.configuration.framerate, plasmoid.configuration.sensitivity, plasmoid.configuration.noiseReduction, plasmoid.configuration.inputMethod || "auto"].join(" ");
            return "bash " + vis.shellQuote(vis.feederPath) + " " + args;
        }
        function spawn() {
            connectSource(spawnCommand());
        }
        // Stop the feeder by the PID it records once it holds the lock, so a
        // restart during a backend probe cannot carry on with the old settings.
        // -f spares a process that reused a stale PID. Older feeders write no
        // PID file; stopping their cava makes them exit too. Neither kill can
        // hit the shell running it.
        function killCommand() {
            if (!vis.resolvedRunDir)
                return "";
            const conf = (vis.resolvedRunDir + "/cava.conf").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            return "pkill -F " + vis.shellQuote(vis.resolvedRunDir + "/feeder.pid") + " -f 'feeder\\.sh' 2>/dev/null; pkill -f -- " + vis.shellQuote("^([^ ]*/)?cava -p " + conf + "$");
        }
        function killFeeder() {
            const command = killCommand();
            if (command)
                connectSource(command);
        }
        // Wait for the old feeder to release the lock rather than a fixed
        // delay, which lost the race whenever it was slow to exit.
        function restartFeeder() {
            const kill = killCommand();
            connectSource(kill ? kill + "; flock -w 3 " + vis.shellQuote(vis.resolvedRunDir + "/lock") + " true; " + spawnCommand() : spawnCommand());
        }
    }

    // Resolved at startup by pathResolver — no shell expansion needed after that.
    property string resolvedRunDir: ""
    readonly property string resolvedBarsPath: resolvedRunDir ? resolvedRunDir + "/bars" : ""
    readonly property string resolvedFramePath: resolvedRunDir ? resolvedRunDir + "/frame.ini" : ""
    readonly property string resolvedStatusPath: resolvedRunDir ? resolvedRunDir + "/status" : ""

    Plasma5Support.DataSource {
        id: pathResolver
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source);
            const p = (data["stdout"] || "").trim();
            if (p)
                vis.resolvedRunDir = p;
        }
    }

    Component.onCompleted: {
        // Resolve $XDG_RUNTIME_DIR once at startup so we can use the absolute path
        // without spawning a shell to expand variables on every frame.
        pathResolver.connectSource("echo -n ${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget");
    }

    // ── Backend health ────────────────────────────────────────────────────────
    // feeder.sh writes a one-line status file: "ok <method>", "probing <method>"
    // or "error <code> [detail]". Without it a broken cava is indistinguishable
    // from silence — the widget just draws a flat line forever, which is exactly
    // what users report as "the bars don't work".
    property string backendState: ""   // "" (unknown) | "ok" | "probing" | "error"
    property string backendCode: ""    // no-cava | no-backend | cava-exited
    property string backendDetail: ""
    property int backendErrorStreak: 0

    // cava exiting is usually transient (sound server restart, sink switch) and
    // the respawn below fixes it within seconds, so only complain once it has
    // clearly stuck. A missing cava or no usable backend is reported right away.
    readonly property bool backendFailed: backendState === "error" && (backendCode !== "cava-exited" || backendErrorStreak >= 3)

    readonly property string backendMessage: {
        if (!backendFailed)
            return "";
        if (backendCode === "no-cava")
            return "cava is not installed";
        if (backendCode === "no-backend")
            return "No usable audio input (tried " + backendDetail.replace(/,/g, ", ") + ")";
        return "Audio capture stopped";
    }

    // The install command for whatever package manager feeder.sh found. Naming
    // the command is the whole point — "cava is not installed" on its own is
    // what sends people to the issue tracker.
    readonly property string installCommand: {
        switch (backendDetail) {
        case "apt-get":
            return "sudo apt install cava";
        case "dnf":
            return "sudo dnf install cava";
        case "pacman":
            return "sudo pacman -S cava";
        case "zypper":
            return "sudo zypper install cava";
        case "apk":
            return "sudo apk add cava";
        case "xbps-install":
            return "sudo xbps-install cava";
        case "emerge":
            return "sudo emerge media-sound/cava";
        case "nix-env":
            return "add pkgs.cava to your configuration";
        default:
            return "install the 'cava' package";
        }
    }

    // Second line under the headline: short enough for a 44px tall waveform.
    readonly property string backendAction: {
        if (!backendFailed)
            return "";
        if (backendCode === "no-cava")
            return installCommand;
        if (backendCode === "no-backend")
            return "is PipeWire or PulseAudio running?";
        return "see " + vis.resolvedRunDir + "/cava.log";
    }

    readonly property string backendHint: {
        if (!backendFailed)
            return "";
        if (backendCode === "no-cava")
            return installCommand + "\nThe widget picks it up within 30 seconds — no restart needed, unless your package manager only changes PATH for new sessions.";
        if (backendCode === "no-backend")
            return "cava could not capture from any backend. Check that PipeWire or PulseAudio is running, or pin one under Audio Input in the widget settings.";
        return "cava keeps exiting — see " + vis.resolvedRunDir + "/cava.log";
    }

    Plasma5Support.DataSource {
        id: statusReader
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source);
            vis.handleStatus((data["stdout"] || "").trim());
        }
        function read() {
            if (vis.resolvedStatusPath)
                connectSource("cat " + vis.shellQuote(vis.resolvedStatusPath));
        }
    }

    function handleStatus(line) {
        // No status file at all (feeder never ran, or an older one is still
        // holding the lock): stay quiet rather than guess.
        if (!line)
            return;
        const parts = line.split(" ");
        backendState = parts[0] || "";
        backendCode = parts[1] || "";
        backendDetail = parts[2] || "";
        if (backendState === "error") {
            backendErrorStreak++;
            // A backend that worked and died usually comes straight back, so
            // nudge the feeder instead of waiting out the 30s heartbeat. The
            // flock in feeder.sh makes this a no-op if it is already healthy.
            // Hard failures (no cava, no backend at all) are left to the
            // heartbeat — respawning every 4s would never fix them.
            if (backendCode === "cava-exited" && vis.active)
                feederLauncher.spawn();
        } else {
            backendErrorStreak = 0;
        }
    }

    Timer {
        interval: 4000
        running: vis.plasmoidVisible && vis.active && vis.resolvedStatusPath !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: statusReader.read()
    }

    // ── Frame transport ───────────────────────────────────────────────────────
    // New feeders publish a separate INI frame for in-process reads. Keep the
    // original semicolon file usable by older widgets sharing this feeder.
    // A timestamp detects a stale INI file if an older feeder takes over later.
    Loader {
        id: barsSource
        active: vis.resolvedFramePath !== ""
        sourceComponent: Settings {
            location: "file://" + vis.resolvedFramePath
        }
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'";
    }

    Plasma5Support.DataSource {
        id: legacyReader
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source);
            vis.handleData((data["stdout"] || "").trim());
        }
        function read() {
            if (vis.resolvedBarsPath && connectedSources.length === 0)
                connectSource("cat " + vis.shellQuote(vis.resolvedBarsPath));
        }
    }

    property real lastIniFrame: 0

    function readBars() {
        const s = barsSource.item as Settings;
        if (!s)
            return;
        s.sync();
        const now = Date.now();
        const stamp = Number(s.value("t", 0)) * 1000;
        if (stamp > 0 && Math.abs(now - stamp) < 2000) {
            lastIniFrame = now;
            handleData(s.value("v", ""));
        } else if (now - lastIniFrame >= 2000) {
            // Join an already-running old feeder without killing it. This
            // fallback goes away as soon as a current feeder owns the lock.
            legacyReader.read();
        }
        // Otherwise the poll landed between the feeder truncating and writing
        // the file: keep the previous frame, as for an empty legacy read.
    }

    readonly property int pollInterval: Math.round(1000 / plasmoid.configuration.framerate)

    // Exponential moving average toward each new cava frame. Cava already
    // smooths over time, but reading a fresh frame every poll still snaps
    // visibly; blending softens the motion without adding latency you'd notice.
    // 0 = frozen, 1 = no smoothing (raw snap). ~0.55 reads as fluid.
    readonly property real smoothing: 0.55

    // Treat the bottom slice of the range as silence. Cava's noise floor and
    // residual smoothing leave tiny non-zero values even when nothing plays, so
    // a strict `val > 0` idle test never trips. Anything under this is "quiet".
    readonly property real idleThreshold: maxRange * 0.012

    // Accept both the INI string list and the original semicolon transport.
    // Empty or malformed reads keep the previous frame.
    function handleData(frame) {
        if (!frame)
            return;
        const rawParts = typeof frame === "string" ? frame.replace(/^v=/, "").split(/[;,]/) : Array.prototype.slice.call(frame);
        const parts = [];
        for (let i = 0; i < rawParts.length; i++) {
            if (rawParts[i] === "")
                continue;
            const value = Number(rawParts[i]);
            if (!isFinite(value))
                return;
            parts.push(Math.max(0, Math.min(maxRange, value)));
        }
        if (!parts.length)
            return;
        const prev = bars;
        const out = [];
        let isQuiet = true;
        let changed = prev.length !== numBars;
        const a = smoothing;
        for (let i = 0; i < numBars; i++) {
            // Keep animating even if the feeder is briefly still on the old bar
            // count while cava restarts after a config change.
            const sourceIndex = Math.min(parts.length - 1, Math.floor(i * parts.length / numBars));
            const v = parts[sourceIndex];
            const target = v > idleThreshold ? v : 0;
            if (target > idleThreshold)
                isQuiet = false;
            const p = prev[i] || 0;
            const blended = p + a * (target - p);
            const next = Math.abs(blended - target) < 0.5 ? target : blended;
            out.push(next);
            changed = changed || next !== p;
        }
        if (changed)
            bars = out;

        if (restarting) {
            pollTimer.interval = vis.pollInterval;
        } else if (isQuiet) {
            if (idleCounter < plasmoid.configuration.framerate * 3) {
                idleCounter++;
            } else {
                pollTimer.interval = 500; // Slow down to 2 FPS when idle
            }
        } else {
            idleCounter = 0;
            pollTimer.interval = vis.pollInterval;
        }
    }

    Timer {
        id: pollTimer
        interval: vis.pollInterval
        running: vis.active && vis.plasmoidVisible
        repeat: true
        onTriggered: vis.readBars()
    }

    onActiveChanged: {
        if (active) {
            idleCounter = 0;
            pollTimer.interval = pollInterval;
        }
    }

    // Keep the feeder alive. spawn() is guarded by flock in feeder.sh, so a
    // re-spawn while cava is healthy is a cheap no-op (it exits immediately).
    // We still avoid hammering it: fire once on start to get cava up fast, then
    // fall back to a slow 30s heartbeat that recovers from a crashed feeder.
    Timer {
        interval: 30000
        running: vis.plasmoidVisible && vis.active
        repeat: true
        triggeredOnStart: true
        onTriggered: feederLauncher.spawn()
    }

    function restart() {
        vis.restarting = true;
        vis.idleCounter = 0;
        vis.backendErrorStreak = 0;
        vis.bars = Array(vis.numBars).fill(0);
        pollTimer.interval = vis.pollInterval;
        feederLauncher.restartFeeder();
        restartCooldown.start();
    }

    Timer {
        id: restartCooldown
        interval: 1200
        repeat: false
        onTriggered: vis.restarting = false
    }

    Connections {
        target: plasmoid.configuration
        ignoreUnknownSignals: true
        function onNumBarsChanged() {
            vis.bars = Array(vis.numBars).fill(0);
            vis.restart();
        }
        function onSensitivityChanged() {
            vis.restart();
        }
        function onFramerateChanged() {
            vis.restart();
        }
        function onNoiseReductionChanged() {
            vis.restart();
        }
        function onInputMethodChanged() {
            vis.restart();
        }
    }

    Component.onDestruction: feederLauncher.killFeeder()
}
