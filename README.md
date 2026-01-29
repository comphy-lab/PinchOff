# PinchOff: Plateau-Rayleigh Pinch-Off in Basilisk

[![Basilisk](https://img.shields.io/badge/Basilisk-C-blue)](http://basilisk.fr)

## Overview

PinchOff contains axisymmetric two-phase VOF simulations of the Rayleigh-Plateau instability and pinch-off scaling of a liquid cylinder. The cases reproduce the similarity laws $r_{min} \sim (t_0 - t)^{2/3}$ and $u_{max} \sim (t_0 - t)^{-1/3}$ using adaptive mesh refinement and interface tracking. Two variants are provided: an inviscid setup (`plateau-basilisk-website.c`) and a viscous setup (`plateau-viscous.c`).

Background references: Popinet (2009) and Popinet & Antkowiak (2011).

## Physics

### Problem Description

A liquid cylinder of radius $R = 0.2$ is perturbed by a sinusoidal mode with wavenumber $k = \pi$ and amplitude $A = 0.1$ in an axisymmetric domain. Surface tension drives the Rayleigh-Plateau instability, leading to necking, pinch-off, and satellite drop formation. The interface is tracked with a VOF field, and the mesh is refined to keep at least five cells across the local radius up to `maxlevel = 18`.

### Governing Equations

The solver integrates the axisymmetric incompressible Navier-Stokes equations for two phases with surface tension:

$$\nabla \cdot \mathbf{u} = 0$$

$$\rho\left(\frac{\partial \mathbf{u}}{\partial t} + \mathbf{u} \cdot \nabla \mathbf{u}\right) = -\nabla p + \nabla \cdot (2\mu \mathbf{D}) + \sigma \kappa \delta_s \mathbf{n}$$

The VOF field $f$ satisfies:

$$\frac{\partial f}{\partial t} + \mathbf{u} \cdot \nabla f = 0$$

### Dimensionless Parameters and Defaults

The simulations are nondimensionalized with $\sigma = 1$ and $\rho_1 = 1$. Key defaults are:

| Parameter | Meaning | plateau-viscous | plateau-basilisk-website |
|---|---|---|---|
| $\rho_1/\rho_2$ | Density ratio | 100 | 100 |
| $\mu_1/\mu_2$ | Viscosity ratio | 100 | inviscid (default $\mu = 0$) |
| $\sigma$ | Surface tension | 1 | 1 |
| $R$ | Initial cylinder radius | 0.2 | 0.2 |
| $k$ | Perturbation wavenumber | $\pi$ | $\pi$ |
| $A$ | Perturbation amplitude | 0.1 | 0.1 |
| `maxlevel` | Max AMR level | 18 | 18 |

## Basilisk (Required)

First-time install (or reinstall):
```bash
curl -sL https://raw.githubusercontent.com/comphy-lab/basilisk-C/main/reset_install_basilisk-ref-locked.sh | bash -s -- --ref=v2026-01-29 --hard
```

Subsequent runs (reuses existing `basilisk/` if same ref):
```bash
curl -sL https://raw.githubusercontent.com/comphy-lab/basilisk-C/main/reset_install_basilisk-ref-locked.sh | bash -s -- --ref=v2026-01-29
```

> Note: Replace `v2026-01-29` with the latest release tag from https://github.com/comphy-lab/basilisk-C/releases.

Set `BASILISK` to the Basilisk `src` path and keep the Basilisk checkout outside this repository:

```bash
# .project_config (gitignored)
export BASILISK=/path/to/basilisk/src
```

You can also export `BASILISK` directly in your shell.

## Repository Structure

```plaintext
├── simulationCases/
│   ├── plateau-basilisk-website.c
│   ├── plateau-viscous.c
│   ├── runCode.sh
│   └── Makefile
└── .github/                  Website assets and workflows
```

`src-local/` and `postProcess/` are not present currently.

## Running the Code

### Using Scripts (Recommended)

```bash
cd simulationCases

# MPI run (4 ranks) using the default script
./runCode.sh plateau-viscous

# Visualization build/run (single rank, OpenGL)
./runCode.sh --view plateau-viscous

# Inviscid variant
./runCode.sh plateau-basilisk-website
```

`runCode.sh` expects a `.project_config` file in the repo root (used to set `BASILISK`) and a working `qcc`. The script defaults to `plateau`; this repository does not include `plateau.c`, so pass the case name explicitly.

### Manual Compilation

**Basilisk Makefile (serial):**
```bash
make -C simulationCases plateau-viscous
./simulationCases/plateau-viscous
```

Note: `runCode.sh` creates `simulationCases/<case>/` output directories. In a clean clone, `make -C simulationCases <case>` builds an executable with the same name. If a directory with that name already exists, prefer `runCode.sh` or build into a different target name.

**Serial qcc:**
```bash
qcc -O2 -Wall -disable-dimensions simulationCases/plateau-viscous.c -o plateau-viscous -lm
./plateau-viscous
```

**OpenMP (shared memory):**
```bash
qcc -O2 -Wall -disable-dimensions -fopenmp simulationCases/plateau-viscous.c -o plateau-viscous -lm
export OMP_NUM_THREADS=8
./plateau-viscous
```

**MPI (distributed memory):**
```bash
CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=1 -disable-dimensions simulationCases/plateau-viscous.c -o plateau-viscous -lm
mpirun -np 4 ./plateau-viscous
```

**Visualization build (OpenGL):**
```bash
qcc -O2 -Wall -disable-dimensions simulationCases/plateau-viscous.c -o plateau-viscous -L$BASILISK/gl -lglutils -lfb_tiny -lm
./plateau-viscous
```

### Parameters (Compile-Time)

These cases use compile-time constants. Edit them in the `.c` files and recompile:

| Parameter | Location | Description | Default |
|---|---|---|---|
| `maxlevel` | plateau-*.c | Maximum AMR level | 18 |
| `R` | plateau-*.c | Base radius | 0.2 |
| `k` | plateau-*.c | Perturbation wavenumber | pi |
| `A` | plateau-*.c | Perturbation amplitude | 0.1 |
| `rho1`, `rho2` | plateau-*.c | Densities | 1, 1e-2 |
| `mu1`, `mu2` | plateau-viscous.c | Viscosities | 1e-2, 1e-4 |
| `sigma` | plateau-*.c | Surface tension | 1 |

### HPC Cluster Execution

Use your scheduler to launch the MPI binary, for example:

```bash
srun -n 4 ./plateau-viscous
```

## Post-Processing

Outputs are written in the run directory:

- `prof-<t>`: interface profiles from `output_facets`
- `movie.mp4`: interface and mesh visualization (when using `view.h`)
- `log`: time series of `(t, r_min, u_max)` when you redirect stderr

Example:
```bash
./plateau-viscous 2> log
```

Use the gnuplot snippets in the case headers to fit the scaling laws from `log`.

## Citation

If you use this code, please cite Basilisk and the relevant pinch-off literature. Add paper and software DOIs here when available.

### Paper
```bibtex
@article{TBD,
  title = {TBD},
  author = {TBD},
  journal = {TBD},
  year = {TBD},
  doi = {TBD}
}
```

### Software
```bibtex
@software{PinchOffTBD,
  title = {PinchOff: Plateau-Rayleigh pinch-off in Basilisk},
  author = {TBD},
  year = {2026},
  url = {https://github.com/<org>/<repo>},
  note = {Add Zenodo DOI when available}
}
```

## Authors

- TBD (add authors and affiliations)

## License

No LICENSE file is included yet. Add a LICENSE file to clarify reuse.
