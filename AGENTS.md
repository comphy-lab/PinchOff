# AGENTS

## Project Overview
PinchOff is a Basilisk CFD project with simulation entry points in `simulationCases/`.

## Layout
- simulationCases/: main `.c` cases (e.g., `plateau-basilisk-website.c`, `plateau-viscous.c`)
- src-local/: project-specific headers/helpers (optional)
- postProcess/: analysis/visualization utilities (optional)

## Build and Run
1. Set `BASILISK` to your local Basilisk `src` path by creating a local `.project_config` (gitignored) or exporting it in your shell.
2. Build a case from repo root:
   `make -C simulationCases plateau-viscous`
3. Run the resulting executable from `simulationCases/`.

## Notes
- Keep the Basilisk checkout outside this repo; do not add a local `basilisk/` directory.
- `.project_config` is local and gitignored; create it only if you do not want to export `BASILISK`.
- Avoid removing or rewriting case output directories unless explicitly requested.
