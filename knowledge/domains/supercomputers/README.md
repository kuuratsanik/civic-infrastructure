# Supercomputers & HPC Knowledge Domain

**Domain**: High-Performance Computing  
**Last Updated**: October 17, 2025

## Overview

This domain covers high-performance computing systems, parallel processing, cluster management, and scientific computing.

## Key Topics

### 1. HPC Architecture
- Cluster computing
- Supercomputer design
- Interconnect technologies (InfiniBand, Omni-Path)
- Memory hierarchies
- Storage systems (parallel filesystems)

### 2. Parallel Computing
- Message Passing Interface (MPI)
- OpenMP
- CUDA and GPU computing
- Distributed computing
- Task parallelism vs data parallelism

### 3. Job Scheduling
- Slurm
- PBS/Torque
- SGE (Sun Grid Engine)
- LSF (Load Sharing Facility)
- Resource allocation strategies

### 4. Performance Optimization
- Profiling and benchmarking
- Code optimization techniques
- Compiler optimizations
- Memory access patterns
- Cache optimization

### 5. Scientific Computing
- Numerical methods
- Simulation and modeling
- Computational fluid dynamics (CFD)
- Molecular dynamics
- Climate modeling

### 6. HPC Software Stack
- Compilers (GCC, Intel, Clang)
- Math libraries (MKL, OpenBLAS, FFTW)
- Parallel I/O libraries
- Visualization tools
- Debugging and profiling tools

### 7. Cloud HPC
- Elastic compute clusters
- Spot instances for HPC
- Hybrid HPC (on-prem + cloud)
- Container-based HPC
- Serverless HPC

### 8. AI & HPC Convergence
- Deep learning on HPC systems
- GPU clusters for AI
- Distributed training
- Large-scale inference
- AI-optimized hardware

## Current Focus Areas

1. **Budget HPC**: Building HPC capabilities on limited budget
2. **GPU Computing**: CUDA and parallel processing
3. **Cluster Management**: Small-scale cluster automation
4. **Performance Analysis**: Profiling and optimization

## HPC System Components

### Compute Nodes
- High core count CPUs
- Large memory capacity
- Fast local storage
- High-bandwidth network

### Storage Systems
- Parallel filesystems (Lustre, GPFS, BeeGFS)
- Object storage
- High-performance NVMe
- Tiered storage

### Network Infrastructure
- Low-latency interconnects
- High bandwidth (100+ Gbps)
- RDMA capabilities
- Non-blocking topology

### Management Infrastructure
- Head nodes
- Login nodes
- Monitoring systems
- Job scheduling

## Performance Metrics

### FLOPS (Floating Point Operations Per Second)
- Peak performance
- Sustained performance
- Linpack benchmark

### Efficiency Metrics
- Power Usage Effectiveness (PUE)
- FLOPS per watt
- Memory bandwidth
- Network bandwidth

### Parallel Performance
- Speedup
- Efficiency
- Scalability
- Amdahl's Law implications

## Building a Budget HPC System

### Phase 1: Single Workstation ($2000-5000)
- High core count CPU (Threadripper, Xeon)
- 64-128 GB RAM
- GPU for compute (used Tesla/Quadro)
- Fast NVMe storage

### Phase 2: Small Cluster ($5000-15000)
- 4-8 compute nodes
- Shared storage
- 10 GbE networking
- Basic job scheduler

### Phase 3: Production Cluster ($15000+)
- 10+ compute nodes
- GPU nodes
- High-speed interconnect
- Parallel filesystem
- Professional cooling

## HPC Software Tools

### Job Scheduling
```bash
# Slurm example
sbatch job_script.sh
squeue -u $USER
scancel <job_id>
```

### Parallel Execution
```bash
# MPI example
mpirun -np 16 ./parallel_app
```

### Profiling
- Intel VTune
- NVIDIA Nsight
- GNU gprof
- Valgrind

### Benchmarking
- HPL (High-Performance Linpack)
- HPCG (High-Performance Conjugate Gradient)
- Stream benchmark
- IOR (parallel I/O benchmark)

## Best Practices

### Code Optimization
1. Profile before optimizing
2. Focus on hotspots
3. Vectorize inner loops
4. Minimize memory allocations
5. Use appropriate data structures

### Resource Management
- Request only needed resources
- Use job arrays for parameter sweeps
- Monitor resource usage
- Clean up completed jobs

### Data Management
- Stage data efficiently
- Use parallel I/O
- Minimize small file operations
- Compress when appropriate

## Related Blueprints

- [To be added]

## Related Lessons

- [To be added]

## Resources

### Top500 Supercomputers
- www.top500.org
- Current HPC trends
- Architecture analysis

### Learning Resources
- Introduction to HPC (XSEDE)
- Parallel Programming in C (book)
- CUDA by Example
- MPI tutorials

### Communities
- r/HPC
- HPC Wire
- InsideHPC
- ACM SIGHPC

### Software
- OpenHPC distribution
- Rocks Cluster Distribution
- Bright Cluster Manager
- Warewulf

### Access Programs
- XSEDE (US)
- NSF computing resources
- Cloud HPC credits
- University HPC facilities

## Integration Points

- **AI Systems**: Compute for large-scale AI training
- **Scientific Computing**: Research workloads
- **Big Data**: Large-scale data processing
- **Rendering**: Graphics and visualization

---

**Maintained by**: AI Autonomous System  
**Note**: HPC requires significant expertise and resources
