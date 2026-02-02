/**
# Plateau-Rayleigh Pinch-Off (Viscous)

Axisymmetric simulation of the Rayleigh-Plateau instability with finite viscosity.
This case reproduces the universal similarity scalings for pinch-off dynamics:
minimum radius $r_{\min} \sim (t_0 - t)^{2/3}$ and maximum velocity
$u_{\max} \sim (t_0 - t)^{-1/3}$, where $t_0$ is the pinch-off time.

## Author
Vatsal Sanjay
Email: vatsalsy@comphy-lab.org
Computational Multiphase Physics Lab
Last updated: Jan 30, 2026

## Physical Setup

A liquid cylinder of radius $R = 0.2$ is perturbed sinusoidally with wavenumber
$k = \pi$ and amplitude $A = 0.1$. Surface tension drives the Rayleigh-Plateau
instability, leading to necking, pinch-off, and satellite drop formation.

The initial perturbation is:

$$r(x, t=0) = R(1 + A \sin(kx))$$

This viscous variant includes finite viscosity ratio $\mu_1/\mu_2 = 100$ and
density ratio $\rho_1/\rho_2 = 100$.

## Similarity Scalings

Using similarity arguments, the minimum radius and maximum axial velocity near
pinch-off follow power laws:

- Minimum radius: $r_{\min} \sim (t_0 - t)^{2/3}$
- Maximum velocity: $u_{\max} \sim (t_0 - t)^{-1/3}$

The figures below illustrate the initial growth, pinch-off, and satellite drop
formation.

~~~gnuplot Interfaces at times 0.2, 0.6, breakup and 0.8
set size ratio -1
unset key
unset xtics
unset ytics
unset border
array s[4] = [0, 0.6, 1.4, 2.3]
array q[4] = ["0.2","0.6","0.75585","0.8"]
plot for [j=1:4] for [x0=0:2:2] for [i=-1:1:2] 'prof-'.q[j] u (x0+$1):(i*$2 - s[j]) w l lc -1, \
     for [j=1:4] for [x0=0:2:2] for [i=-1:1:2] 'prof-'.q[j] u (x0+1-$1):(i*$2 - s[j]) w l lc -1
~~~

The animation shows how adaptive mesh refinement tracks high curvatures and short
timescales near pinch-off. Up to 18 levels of refinement capture roughly four
orders of magnitude in spatial scales.

![Mesh and interface evolution](plateau/movie.mp4)(width="80%")

The scaling plots below show the theoretical fits. The fit is excellent over
at least four orders of magnitude. Departures from power laws near pinch-off
result from saturation of spatial resolution (grid size $1/2^{18}$).

~~~gnuplot Evolution of the minimum radius
reset
# We define the breakup time as the time when the axial velocity is maximum
t0="`awk '{ if (NF == 3 && $3 > max) { max = $3; t0 = $1; } } END{ print t0 }' < log`"
set key spacing 1.5
set grid
set xlabel 't_0 - t'
set ylabel 'r_{min}'
set logscale
set format x '10^{%L}'
set format y '10^{%L}'
fit [1e-7:1e-3] a*x**(2./3.) 'log' u (t0 - $1):2 via a
plot [1e-8:][1./2**18:]'log' u (t0 - $1):2 ps 0.5 t '', a*x**(2./3.) t 'x^{2/3}'
~~~

~~~gnuplot Evolution of the maximum axial velocity
set ylabel 'u_{max}'
fit [1e-7:1e-3] a*x**(-1./3.) 'log' u (t0 - $1):3 via a
plot [1e-8:]'log' u (t0 - $1):3 ps 0.5 t '', a*x**(-1./3.) t 'x^{-1/3}'
~~~

## References

For detailed description see:
- [Popinet, 2009](/sandbox/popinet/README#popinet2009)
- [Popinet & Antkowiak, 2011](/sandbox/popinet/README#popinet2011d)

## Numerical Setup

We solve the axisymmetric, incompressible, variable-density Navier-Stokes
equations with two phases and surface tension.
*/

#include "axi.h"
#include "navier-stokes/centered.h"
#include "two-phase.h"
#include "tension.h"

/**
## Parameters

Maximum refinement level for adaptive mesh.
*/
const int maxlevel = 18;

/**
## Main Function

Initialize domain, material properties, and run the simulation.
*/
int main()
{
  origin (-0.5);
  
  /**
  Surface tension coefficient.
  */
  f.sigma = 1.;
  
  /**
  Phase densities: $\rho_1 = 1$, $\rho_2 = 0.01$ (density ratio 100).
  */
  rho1 = 1.;
  rho2 = 1e-2;

  /**
  Phase viscosities: $\mu_1 = 0.01$, $\mu_2 = 0.0001$ (viscosity ratio 100).
  This distinguishes the viscous case from the inviscid variant.
  */
  mu1 = 1e-2;
  mu2 = 1e-4;

  run();
}

/**
## Initial Conditions

Perturbed cylinder with 10% amplitude sinusoidal deformation.
*/
event init (t = 0)
{
  /**
  Perturbation parameters: wavenumber $k = \pi$, base radius $R = 0.2$,
  amplitude $A = 0.1$.
  */
  double k = pi, R = 0.2;
  fraction (f, R*(1. + 0.1*sin(k*x)) - y);
}

/**
## Diagnostics

Allocate scalar field `Y` to store the radial position of the interface
relative to the axis of symmetry.
*/
scalar Y[];

/**
### Logging

Log the minimum interface position and maximum axial velocity at regular
intervals. Output is written to stderr and can be redirected to a log file.
*/
event logfile (i += 5)
{
  position (f, Y, {0,1});
  fprintf (stderr, "%.12f %.12f %.12f\n", t, statsf(Y).min, normf(u.x).max);
}

/**
## Output

Generate interface profiles and animation for visualization.
*/
const double tpinch = 0.75626;

/**
### Interface Profiles

Write interface facet coordinates at specific times.
*/
event profiles (t = {0.2, 0.6, tpinch, 0.8})
{
  char name[80];
  sprintf (name, "prof-%g", t);
  FILE * fp = fopen (name, "w");
  output_facets (f, fp);
  fclose (fp);
}

/**
### Animation

Generate movie showing mesh refinement and interface evolution.
*/
#include "view.h"

event movie (t = 0.6; i += 5; t <= tpinch)
{
  view (fov = 30, near = 0.01, far = 1000,
	tx = -0.111, tz = -0.4,
	width = 1024, height = 680);
  squares (color = "level", min = 6, max = maxlevel, spread = -1);
  draw_vof (c = "f");
  mirror ({0,-1}) {
    squares (color = "level", min = 6, max = maxlevel, spread = -1);
    draw_vof (c = "f");
  }
  save ("movie.mp4");
}

/**
## Adaptive Mesh Refinement

Refine the mesh to maintain at least 5 grid cells across the local interface
radius, up to `maxlevel` before breakup and level 10 after.
*/
event adapt (i++)
{
  /**
  Check whether the column is broken (minimum radius below grid resolution).
  */
  position (f, Y, {0,1});
  static bool broken = false;
  if (!broken)
    broken = statsf(Y).min < 1./(1 << maxlevel);

  /**
  Refine cells containing the interface to ensure 5 cells per local radius.
  */
  const double eps = 1e-6;
  refine (level < (broken ? 10 : maxlevel) &&
	  f[] > eps && f[] < 1. - eps &&
	  Delta > Y[]/5.);

  /**
  Unrefine cells that do not contain the interface or exceed the post-breakup
  refinement level.
  */
  unrefine (f[] <= eps || f[] >= 1. - eps ||
	    (broken && level > 10));
}

/**
## See Also

- [Same test with Gerris](http://gerris.dalembert.upmc.fr/gerris/tests/tests/plateau.html)
- [3D Plateau example with Gerris](http://gerris.dalembert.upmc.fr/gerris/examples/examples/plateau.html)
*/
