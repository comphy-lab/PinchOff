# PinchOff

Basilisk CFD project with simulation entry points in `simulationCases/`.

## Requirements
- Basilisk source tree (external install); set `BASILISK` to its `src` path via a local `.project_config` or your shell
- Make and a C toolchain compatible with Basilisk

## Quick start
1. Create a local `.project_config` (gitignored) with `export BASILISK=/path/to/basilisk/src`, or export `BASILISK` in your shell.
2. Build a case from repo root:
   `make -C simulationCases plateau-viscous`
3. Run the resulting executable from `simulationCases/`.

## Project structure
- simulationCases/: main `.c` cases (e.g., `plateau-basilisk-website.c`, `plateau-viscous.c`)
- src-local/: project-specific headers/helpers (optional)
- postProcess/: analysis/visualization utilities (optional)

## Notes
- Keep the Basilisk checkout outside this repo; do not add a local `basilisk/` directory.
- `.project_config` is local and gitignored; create it only if you do not want to export `BASILISK`.
- Simulation outputs under `simulationCases/` are intentionally untracked.
