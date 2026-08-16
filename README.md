# High-Performance Heat Diffusion: A Hardware-Aware Jacobi Implementation

This repository contains an implementation of the 2D Heat Diffusion simulation solving the Laplace equation via the iterative Jacobi method. It provides three progressive implementations (Serial, OpenMP, and CUDA) specifically engineered to demonstrate the critical interplay between algorithmic patterns and hardware architectural constraints.

## Syllabus & Architectural Concepts

### 1. Metrics and Models (The GFLOPS & Roofline Paradigm)
The Jacobi stencil computes 5 double-precision Floating Point Operations (4 additions, 1 division) per grid point. The performance is reported natively in the code using the metric: `(5.0 * MAXITER * GLX * GLY) / (dT * 1e6)` GFLOPS.

In the context of the Roofline Model, the Jacobi method represents a classic Memory-Bound algorithm. It has extremely low Arithmetic Intensity: for every 5 computations, the CPU/GPU must fetch 5 `double` elements (40 bytes) and write 1 `double` (8 bytes). Because it is constrained by Memory Bandwidth rather than Compute Capabilities, optimizing cache hit rates is more vital than raw CPU clock speeds.

### 2. Instruction & Data Level Parallelism (Row-Major Optimizations)
In the C versions, multi-dimensional array mapping is executed via `index = i * GX + j`. The explicit nesting where the X-axis (`j`) is the innermost loop guarantees Spatial Locality. By iterating contiguously, the prefetcher eagerly loads continuous blocks into the L1/L2 Cache Lines. Reversing this loop would cause cache thrashing, evicting data before it can be effectively reused.

### 3. OpenMP and Memory Consistency (Thread Level Parallelism)
The OpenMP implementation assigns slices along the Y-direction to different threads using `schedule(static)`. This prevents False Sharing, ensuring that individual threads mutate memory mapped to independent Cache Lines, avoiding cache-coherency ping-pong latency across CPU dies.

### 4. GPU Many-Core Architecture (SIMT & Host-to-Device Mitigation)
The CUDA implementation maps the calculation onto a 2D Block/Grid structure leveraging the Single Instruction Multiple Thread (SIMT) paradigm. Key architectural choices include:
* Memory Coalescing: Threads within a warp read contiguous memory addresses.
* H2D/D2H Bottleneck Avoidance: The pointer swap mechanism is unrolled directly inside the kernel execution sequence loop, which eliminates expensive PCIe bus data transfers entirely until the final iteration dump is required.

## Compilation and Execution

The project relies on a comprehensive Makefile to manage the toolchain, virtual environments, and cluster submission. The C compilation utilizes GCC with `-Ofast`, `-fopenmp`, and `-march=native` flags, while the CUDA compilation uses NVCC targeting the `sm_80` architecture with `-O3`.

### Prerequisites
Ensure that the necessary modules are loaded in your HPC environment. You can verify the availability of the required tools by running:
`make check`
This target verifies the presence of GCC, NVCC, Gnuplot, and ImageMagick (`convert`) in your system PATH.

### Build Instructions
To compile the three implementations (Serial, OpenMP, CUDA), run:
`make build`
This command generates the `jacobi-serial`, `jacobi-omp`, and `jacobi-cuda` executables and creates the necessary output directories.

To prepare the Python environment required for generating performance graphs, run:
`make venv`
This sets up an isolated virtual environment and installs `matplotlib`. 

### Job Submission
To automatically build the project, prepare the environment, and submit the simulation to the SLURM workload manager, execute:
`make submit`
This triggers the `sbatch` command using the provided `JACOBI.slurm` script.

### Post-Processing
After the SLURM job completes, you can generate the simulation animation and the performance scaling plots by running:
`make post-process`
This executes the `mkvideo.sh` script to render the heat maps and the `plot_performance.py` script to output the GFLOPS graphs.

### Clean Workspace
To remove compiled binaries, SLURM output logs, generated videos, and plots, use:
`make clean`.
