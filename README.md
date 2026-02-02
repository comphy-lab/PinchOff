# PinchOff: Plateau-Rayleigh Pinch-Off in Basilisk

[![Basilisk](https://img.shields.io/badge/Basilisk-C-blue)](http://basilisk.fr)

## Overview

PinchOff provides axisymmetric two-phase VOF simulations of the Rayleigh-Plateau instability and pinch-off dynamics of a liquid cylinder. The code reproduces the universal similarity scalings $r_{\min} \sim (t_0 - t)^{2/3}$ and $u_{\max} \sim (t_0 - t)^{-1/3}$ using adaptive mesh refinement and interface tracking with the Basilisk C framework.

Two simulation variants are included:
- `plateau-basilisk-website.c` — inviscid reference case (matches [Basilisk tutorial](http://basilisk.fr/src/examples/plateau.c))
- `plateau-viscous.c` — viscous extension with finite viscosity ratio

**Background references**: Popinet (2009), Popinet & Antkowiak (2011)

## Physical Problem

### Governing Equations

The solver integrates the axisymmetric incompressible Navier-Stokes equations for two immiscible fluids with surface tension:

$$
\nabla \cdot \mathbf{u} = 0
$$

$$
\rho\left(\frac{\partial \mathbf{u}}{\partial t} + \mathbf{u} \cdot \nabla \mathbf{u}\right) = -\nabla p + \nabla \cdot \left(2\mu \mathbf{D}\right) + \sigma \kappa \delta_s \mathbf{n}
$$

The volume fraction field $f$ satisfies:

$$
\frac{\partial f}{\partial t} + \mathbf{u} \cdot \nabla f = 0
$$

where $\rho$ and $\mu$ are piecewise-constant densities and viscosities, $\sigma$ is the surface tension coefficient, $\kappa$ is the interface curvature, and $\delta_s$ is the interfacial delta function.

### Problem Setup

A liquid cylinder of radius $R = 0.2$ is perturbed by a sinusoidal mode:

$$
r(x, t=0) = R \left(1 + A \sin(kx)\right)
$$

with wavenumber $k = \pi$ and amplitude $A = 0.1$. Surface tension drives the Rayleigh-Plateau instability, leading to necking, pinch-off, and satellite drop formation.

The interface is tracked with a VOF field, and the mesh is adapted to maintain at least five grid cells across the local cylinder radius, up to `maxlevel = 18`.

### Dimensionless Parameters

Simulations are nondimensionalized with $\sigma = 1$ and $\rho_1 = 1$. Key parameters:

| Parameter | Meaning | plateau-viscous | plateau-basilisk-website |
|-----------|---------|-----------------|--------------------------|
| $\rho_1/\rho_2$ | Density ratio | 100 | 100 |
| $\mu_1/\mu_2$ | Viscosity ratio | 100 | 0 (inviscid) |
| $\sigma$ | Surface tension | 1 | 1 |
| $R$ | Cylinder radius | 0.2 | 0.2 |
| $k$ | Wavenumber | $\pi$ | $\pi$ |
| $A$ | Perturbation amplitude | 0.1 | 0.1 |
| `maxlevel` | Max AMR level | 18 | 18 |

## Prerequisites

### Basilisk Installation

PinchOff requires the [Basilisk C](http://basilisk.fr) solver. Install or update to a locked reference:

**First-time install** (or reinstall):
```bash
curl -sL https://raw.githubusercontent.com/comphy-lab/basilisk-C/main/reset_install_basilisk-ref-locked.sh | bash -s -- --ref=v2026-01-29 --hard
```

**Subsequent runs** (reuses existing `basilisk/` if same ref):
```bash
curl -sL https://raw.githubusercontent.com/comphy-lab/basilisk-C/main/reset_install_basilisk-ref-locked.sh | bash -s -- --ref=v2026-01-29
```

> **Note**: Replace `v2026-01-29` with the latest release tag from [comphy-lab/basilisk-C/releases](https://github.com/comphy-lab/basilisk-C/releases).

### Environment Configuration

Set the `BASILISK` environment variable to the Basilisk `src` directory. Keep the Basilisk checkout **outside** this repository.

**Option 1**: Local config file (gitignored, repo-specific)
```bash
# .project_config
export BASILISK=/path/to/basilisk/src
```

**Option 2**: Shell environment (global)
```bash
export BASILISK=/path/to/basilisk/src  # Add to ~/.bashrc or ~/.zshrc
```

## Repository Structure

```plaintext
PinchOff/
├── simulationCases/          Simulation entry points
│   ├── plateau-basilisk-website.c
│   ├── plateau-viscous.c
│   ├── runCode.sh           Wrapper script (MPI/OpenGL builds)
│   └── Makefile             Basilisk Makefile
├── .github/                 Website generation and workflows
│   ├── docs/               Generated site output
│   ├── assets/             CSS, JS, fonts for docs
│   └── workflows/          CI/CD for documentation
├── AGENTS.md               Agent/build instructions
└── README.md               This file
```

**Note**: `src-local/` and `postProcess/` directories are not currently present.

## Building and Running

### Quick Start (Recommended)

Use the provided shell script for MPI or visualization builds:

```bash
cd simulationCases

# MPI run (4 processes)
./runCode.sh plateau-viscous

# Visualization build with OpenGL
./runCode.sh --view plateau-viscous

# Inviscid variant
./runCode.sh plateau-basilisk-website
```

**Requirements**:
- `.project_config` file in repo root (or `BASILISK` environment variable)
- `qcc` compiler in `$PATH`

**Note**: The script defaults to a case named `plateau` (not included). Always specify the case name explicitly.

### Manual Compilation

#### Basilisk Makefile (Serial)

```bash
make -C simulationCases plateau-viscous
./simulationCases/plateau-viscous
```

> **Caution**: If a directory `simulationCases/plateau-viscous/` already exists (from a previous run), the Makefile may fail. Use `runCode.sh` or build with a different target name.

#### Serial (qcc)

```bash
qcc -O2 -Wall -disable-dimensions simulationCases/plateau-viscous.c -o plateau-viscous -lm
./plateau-viscous
```

#### OpenMP (Shared Memory)

```bash
qcc -O2 -Wall -disable-dimensions -fopenmp simulationCases/plateau-viscous.c -o plateau-viscous -lm
export OMP_NUM_THREADS=8
./plateau-viscous
```

#### MPI (Distributed Memory)

```bash
CC99='mpicc -std=c99' qcc -Wall -O2 -D_MPI=1 -disable-dimensions \
    simulationCases/plateau-viscous.c -o plateau-viscous -lm
mpirun -np 4 ./plateau-viscous
```

#### Visualization Build (OpenGL)

```bash
qcc -O2 -Wall -disable-dimensions simulationCases/plateau-viscous.c -o plateau-viscous \
    -L$BASILISK/gl -lglutils -lfb_tiny -lm
./plateau-viscous
```

### Compile-Time Parameters

Parameters are defined as constants in the source files. Edit and recompile to change:

| Parameter | Location | Description | Default |
|-----------|----------|-------------|---------|
| `maxlevel` | `plateau-*.c` | Maximum AMR level | 18 |
| `R` | `plateau-*.c` | Cylinder radius | 0.2 |
| `k` | `plateau-*.c` | Perturbation wavenumber | $\pi$ |
| `A` | `plateau-*.c` | Perturbation amplitude | 0.1 |
| `rho1`, `rho2` | `plateau-*.c` | Phase densities | 1, 0.01 |
| `mu1`, `mu2` | `plateau-viscous.c` | Phase viscosities | 0.01, 0.0001 |
| `sigma` | `plateau-*.c` | Surface tension | 1 |
| `tpinch` | `plateau-*.c` | Approximate pinch-off time | 0.75626 |

### HPC Execution

Launch MPI binaries with your cluster scheduler:

```bash
# SLURM example
srun -n 16 ./plateau-viscous

# PBS/Torque example
mpirun -np 16 ./plateau-viscous
```

## Output and Post-Processing

### Output Files

Simulations write the following files in the run directory:

- `log` — time series of $(t, r_{\min}, u_{\max})$ written to stderr
- `prof-<t>` — interface profiles at specific times (from `output_facets`)
- `movie.mp4` — interface and mesh animation (when using `view.h`)

**Example**: Capture time series to a log file:
```bash
./plateau-viscous 2> log
```

### Scaling Analysis

Use the gnuplot fitting scripts embedded in the C file headers to extract similarity exponents from `log`:

```gnuplot
# Define breakup time as the time when axial velocity is maximum
t0="`awk '{ if (NF == 3 && $3 > max) { max = $3; t0 = $1; } } END{ print t0 }' < log`"

# Fit minimum radius scaling
set logscale
fit [1e-7:1e-3] a*x**(2./3.) 'log' u (t0 - $1):2 via a
plot [1e-8:][1./2**18:]'log' u (t0 - $1):2 ps 0.5, a*x**(2./3.)

# Fit maximum velocity scaling
fit [1e-7:1e-3] a*x**(-1./3.) 'log' u (t0 - $1):3 via a
plot [1e-8:]'log' u (t0 - $1):3 ps 0.5, a*x**(-1./3.)
```

The fits should yield exponents $2/3$ and $-1/3$ over several orders of magnitude.

## Citation

If you use this code, please cite the Basilisk solver and the relevant literature on pinch-off similarity solutions.

### Paper

```bibtex
@article{PinchOffPaper,
  title   = {TBD},
  author  = {TBD},
  journal = {TBD},
  year    = {TBD},
  doi     = {TBD}
}
```

### Software

```bibtex
@software{PinchOff,
  title   = {PinchOff: Plateau-Rayleigh Pinch-Off in Basilisk},
  author  = {TBD},
  year    = {2026},
  url     = {https://github.com/<org>/<repo>},
  note    = {Zenodo DOI: TBD}
}
```

### References

- Popinet, S. (2009). "An accurate adaptive solver for surface-tension-driven interfacial flows." *J. Comput. Phys.*, **228**(16), 5838–5866. [doi:10.1016/j.jcp.2009.04.042](https://doi.org/10.1016/j.jcp.2009.04.042)
- Popinet, S., & Antkowiak, A. (2011). "Numerical simulation of a viscous liquid pinch-off." *Journal TBD*. [Reference details TBD]

## Authors

**TBD** — Add author names and affiliations.

## License

**TBD** — No LICENSE file is currently included. Add a LICENSE file to clarify terms of use and redistribution.
