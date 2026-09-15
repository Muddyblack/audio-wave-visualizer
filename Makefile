.PHONY: help view view-h view-hyprland settings-hyprland install doctor pack tag shaders
.DEFAULT_GOAL := help

help: ## list targets
	@awk 'BEGIN{FS=":.*##"} /^[a-z][a-zA-Z0-9_-]+:.*##/ {printf "  make %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

view: ## preview widget (planar)
	@if command -v nix >/dev/null 2>&1 && [ -f flake.nix ]; then \
	  nix run .#view; \
	else \
	  plasmoidviewer -a package -f planar; \
	fi

view-hyprland: ## run standalone Quickshell desktop widget (Ctrl+C to stop)
	@if command -v qs >/dev/null 2>&1; then \
	  bash "$(CURDIR)/hyprland/run.sh"; \
	else \
	  nix run .#view-hyprland; \
	fi

settings-hyprland: ## open settings in the running Quickshell widget
	@if command -v qs >/dev/null 2>&1; then \
	  qs -p "$(CURDIR)/shell.qml" ipc call settings open; \
	else \
	  nix run .#view-hyprland -- ipc call settings open; \
	fi

view-h: ## preview widget (horizontal)
	@if command -v nix >/dev/null 2>&1 && [ -f flake.nix ]; then \
	  nix run .#view -- horizontal; \
	else \
	  plasmoidviewer -a package -f horizontal; \
	fi

install: ## install test copy to local Plasma session
	@./test_install.sh

doctor: ## diagnose "the bars don't move" (paste output into issues)
	@bash package/contents/code/doctor.sh

shaders: ## rebuild the waveform shader after editing visualizer.frag
	@if command -v qsb >/dev/null 2>&1; then \
	  qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o package/contents/shaders/visualizer.frag.qsb package/contents/shaders/visualizer.frag; \
	else \
	  nix develop --command qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o package/contents/shaders/visualizer.frag.qsb package/contents/shaders/visualizer.frag; \
	fi

pack: ## build .plasmoid archive
	@if command -v nix >/dev/null 2>&1 && [ -f flake.nix ]; then \
	  nix run .#pack; \
	else \
	  ver=$$(grep -oE '"Version":[[:space:]]*"[^"]+"' package/metadata.json | head -1 | sed -E 's/.*"([^"]+)"$$/\1/'); \
	  name=$$(basename "$$PWD"); \
	  out="$$PWD/$$name-$$ver.plasmoid"; \
	  rm -f "$$out"; \
	  (cd package && zip -r "$$out" . -x '*.swp' '*~'); \
	  echo "wrote $$out"; \
	fi

tag: ## bump version, commit, tag, push
	@./tag.sh
