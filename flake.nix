{
  description = "Plasma 6 audio visualizer widget (cava-backed)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
      metadata = builtins.fromJSON (builtins.readFile ./package/metadata.json);
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "plasma-audio-visualizer";
            version = metadata.KPlugin.Version;
            src = ./package;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              runHook preInstall
              root=$out/share/plasma/plasmoids/${metadata.KPlugin.Id}
              mkdir -p "$root"
              cp -r . "$root/"
              for script in feeder.sh doctor.sh stereo_capture.sh local_lyrics.sh track_profile.sh; do
                chmod +x "$root/contents/code/$script"
                wrapProgram "$root/contents/code/$script" \
                  --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.cava (pkgs.python3.withPackages (ps: [ ps.mutagen ps.pykakasi ps.pypinyin ])) pkgs.pipewire pkgs.ffmpeg pkgs.gawk pkgs.util-linux pkgs.procps pkgs.coreutils pkgs.gnused ]}
              done
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Plasma 6 audio visualizer widget (cava-backed)";
              license = licenses.gpl3Plus;
              platforms = platforms.linux;
              homepage = "https://github.com/muddyblack/kde-audio-visualizer";
            };
          };
        });

      apps = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          ruff = {
            type = "app";
            program = "${pkgs.ruff}/bin/ruff";
          };
          view-hyprland = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "view-hyprland";
              runtimeInputs = [ pkgs.quickshell pkgs.cava (pkgs.python3.withPackages (ps: [ ps.mutagen ps.pykakasi ps.pypinyin ])) pkgs.pipewire pkgs.ffmpeg pkgs.gawk pkgs.util-linux pkgs.procps pkgs.coreutils pkgs.gnused ];
              text = ''
                exec bash "$PWD/hyprland/run.sh" "$@"
              '';
            }}/bin/view-hyprland";
          };
          view = {
            type = "app";
            program = toString (pkgs.writeShellScript "view" ''
              export PATH=${pkgs.lib.makeBinPath [ pkgs.kdePackages.plasma-sdk (pkgs.python3.withPackages (ps: [ ps.mutagen ps.pykakasi ps.pypinyin ])) ]}:"$PATH"
              exec plasmoidviewer \
                -a "$PWD/package" -f "''${1:-planar}"
            '');
          };
          pack = {
            type = "app";
            program = toString (pkgs.writeShellScript "pack" ''
              set -euo pipefail
              here="$PWD"
              ver="$(grep -oE '"Version":[[:space:]]*"[^"]+"' "$here/package/metadata.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
              name="$(basename "$here")"
              out="$here/$name-$ver.plasmoid"
              rm -f "$out"
              (cd "$here/package" && ${pkgs.zip}/bin/zip -r "$out" . -x '*.swp' '*~')
              echo "wrote $out"
            '');
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # CI runners lack /etc/dbus-1/session.conf; use the packaged config.
          sessionBus = pkgs.writeShellScriptBin "dbus-run-session" ''
            exec ${pkgs.dbus}/bin/dbus-run-session \
              --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon \
              --config-file=${pkgs.dbus}/share/dbus-1/session.conf "$@"
          '';
        in {
          default = pkgs.mkShell {
            name = "plasma-audio-visualizer-dev";
            packages = with pkgs; [
              qt6.qtdeclarative
              qt6.qtsvg
              kdePackages.kirigami
              # qsb, for `make shaders`
              qt6.qtshadertools
              # Headless Quickshell integration tests and their process tools.
              quickshell
              (python3.withPackages (ps: [ ps.mutagen ps.pykakasi ps.pypinyin ]))
              ruff
              dbus
              gnumake
              util-linux
              procps
              gawk
              kdePackages.kpackage
              kdePackages.plasma-sdk
              pre-commit
              zip
              # tests/test_feeder.py also streams frames through the awks
              # Debian/Ubuntu (mawk) and BSD-style systems (nawk) ship.
              mawk
              nawk
            ];
            # Supply QML modules and SVG decoding explicitly: CI runners have
            # no desktop Qt paths for qmltestrunner or qmllint to inherit.
            shellHook = ''
              # Qt's propagated tools can put the unwrapped D-Bus first.
              export PATH="${sessionBus}/bin:$PATH"
              export NIXPKGS_QT6_QML_IMPORT_PATH="${pkgs.lib.makeSearchPath pkgs.qt6.qtbase.qtQmlPrefix [ pkgs.qt6.qtdeclarative pkgs.kdePackages.kirigami ]}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}"
              export QT_PLUGIN_PATH="${pkgs.qt6.qtsvg}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
              pre-commit install -f --install-hooks
              echo "plasma-audio-visualizer dev shell ready"
              echo "  make help        — list targets (view, install, pack, tag)"
            '';
          };
        });
    };
}
