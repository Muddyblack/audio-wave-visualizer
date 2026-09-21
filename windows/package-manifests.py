"""Generate Scoop and WinGet manifests from the exact Windows release assets.

Modeled on ai-usage-widget's windows/package-manifests.py. Note: the overlay
these ship has not been run on a real Windows machine yet (see
docs/windows.md), so hold off submitting to the public catalogs until it has.

Run after building the ZIP and Inno installer; no network or third-party
modules.
"""

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

HOMEPAGE = "https://github.com/Muddyblack/audio-wave-visualizer"
PACKAGE_ID = "Muddyblack.AudioVisualizer"
# Must match installer.iss's AppId + "_is1".
PRODUCT_CODE = "{808901FC-4752-4921-BA4E-D6883FFFE601}_is1"
DESCRIPTION = "Audio-reactive desktop overlay visualizer for Windows."


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def generate(version, assets, output):
    # Stable release tags only: never produce public URLs for CI/prerelease builds.
    version = version.removeprefix("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Expected a stable version such as 3.2.0 or v3.2.0")
    portable = f"audio-visualizer-windows-{version}.zip"
    installer = f"Audio-Visualizer-Setup-{version}.exe"
    portable_hash = sha256(assets / portable)
    installer_hash = sha256(assets / installer)
    with zipfile.ZipFile(assets / portable) as archive:
        if "Audio Visualizer/Audio Visualizer.exe" not in archive.namelist():
            raise ValueError(
                "Portable ZIP must contain Audio Visualizer/Audio Visualizer.exe"
            )
    base = f"{HOMEPAGE}/releases/download/v{version}"
    output.mkdir(parents=True, exist_ok=True)
    scoop = {
        "version": version,
        "description": DESCRIPTION,
        "homepage": HOMEPAGE,
        "license": "GPL-3.0-or-later",
        "architecture": {"64bit": {"url": f"{base}/{portable}", "hash": portable_hash}},
        "extract_dir": "Audio Visualizer",
        "shortcuts": [["Audio Visualizer.exe", "Audio Visualizer"]],
        "notes": "Quit Audio Visualizer before updating. Settings are kept.",
        "checkver": "github",
        "autoupdate": {
            "architecture": {
                "64bit": {
                    "url": f"{HOMEPAGE}/releases/download/v$version/audio-visualizer-windows-$version.zip"
                }
            },
        },
    }
    (output / "audio-visualizer.json").write_text(
        json.dumps(scoop, indent=4) + "\n", encoding="utf-8"
    )

    # JSON-quoted scalar values are also valid YAML; the surrounding YAML is
    # deliberately plain so WinGet's restricted parser can read it.
    common = f'PackageIdentifier: {PACKAGE_ID}\nPackageVersion: "{version}"\n'
    manifests = {
        f"{PACKAGE_ID}.yaml": common
        + "DefaultLocale: en-US\nManifestType: version\nManifestVersion: 1.6.0\n",
        f"{PACKAGE_ID}.locale.en-US.yaml": common
        + f"""PackageLocale: en-US
Publisher: Muddyblack
PublisherUrl: {HOMEPAGE}
PublisherSupportUrl: {HOMEPAGE}/issues
PackageName: Audio Visualizer
PackageUrl: {HOMEPAGE}
License: GPL-3.0-or-later
LicenseUrl: {HOMEPAGE}/blob/v{version}/LICENSE
ShortDescription: {DESCRIPTION}
Moniker: audio-visualizer
ManifestType: defaultLocale
ManifestVersion: 1.6.0
""",
        f"{PACKAGE_ID}.installer.yaml": common
        + f"""InstallerType: inno
Scope: user
UpgradeBehavior: install
InstallerSwitches:
  Custom: /TASKS=""
Installers:
  - Architecture: x64
    InstallerUrl: {base}/{installer}
    InstallerSha256: {installer_hash.upper()}
    ProductCode: '{PRODUCT_CODE}'
    AppsAndFeaturesEntries:
      - DisplayName: Audio Visualizer
        Publisher: Muddyblack
        DisplayVersion: "{version}"
        ProductCode: '{PRODUCT_CODE}'
ManifestType: installer
ManifestVersion: 1.6.0
""",
    }
    manifest_dir = (
        output
        / "winget"
        / "manifests"
        / "m"
        / "Muddyblack"
        / "AudioVisualizer"
        / version
    )
    manifest_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        output / f"audio-visualizer-winget-{version}.zip", "w", zipfile.ZIP_DEFLATED
    ) as archive:
        for name, contents in manifests.items():
            path = manifest_dir / name
            data = contents.encode("utf-8")
            path.write_bytes(data)
            archive.writestr(path.relative_to(output / "winget").as_posix(), data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--assets", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, default=Path("dist/package-manifests"))
    args = parser.parse_args()
    generate(args.version, args.assets, args.output)


if __name__ == "__main__":
    main()
