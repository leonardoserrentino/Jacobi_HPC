#include "common.h"
#include <omp.h>

__global__ void jacobi_kernel(double *grid_new, const double *grid) {
    int j = blockIdx.x * blockDim.x + threadIdx.x; // Indice Colonna
    int i = blockIdx.y * blockDim.y + threadIdx.y; // Indice Riga

    // Controllo dei boundary (ghost cells intatte)
    if (i > 0 && i < GY - 1 && j > 0 && j < GX - 1) {
        grid_new[i * GX + j] = (grid[i * GX + j] + 
                                grid[(i - 1) * GX + j] + 
                                grid[(i + 1) * GX + j] + 
                                grid[i * GX + (j - 1)] + 
                                grid[i * GX + (j + 1)]) / 5.0;
    }
}

int main() {
    // Disabilita il buffering dell'output, ogni printf andrà SUBITO nel file .out di SLURM
    setvbuf(stdout, NULL, _IONBF, 0);
    
    size_t mem_size = GX * GY * sizeof(double);
    double *h_grid = (double*) malloc(mem_size);
    init(h_grid);

    double *d_grid, *d_grid_new;
    cudaMalloc(&d_grid, mem_size);
    cudaMalloc(&d_grid_new, mem_size);
    cudaMemcpy(d_grid, h_grid, mem_size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_grid_new, h_grid, mem_size, cudaMemcpyHostToDevice);

    dim3 threadsPerBlock(16, 16);
    dim3 numBlocks((GX + threadsPerBlock.x - 1) / threadsPerBlock.x,
                   (GY + threadsPerBlock.y - 1) / threadsPerBlock.y);

    char myfile[64];
    
    // Dump iniziale
    #if DUMP == 1
    sprintf(myfile, "video/grid-%07d", 0);
    dump(h_grid, myfile);
    #endif

    double start_time = omp_get_wtime();
    
    // Loop unrolling: iter += 2
    for (int iter = 1; iter <= MAXITER; iter += 2) { 
        
        // 1. Compute iter (grid_new <-- grid)
        jacobi_kernel<<<numBlocks, threadsPerBlock>>>(d_grid_new, d_grid); 
        
        // 2. Compute iter + 1 (grid <-- grid_new)
        jacobi_kernel<<<numBlocks, threadsPerBlock>>>(d_grid, d_grid_new); 

        // 3. Gestione del Dump Periodico (Penalità I/O + PCIe)
        #if DUMP == 1
        if ((iter + 1) % DUMPSTEP == 0) {
            // a. Sincronizziamo la GPU per essere certi che il calcolo sia finito
            cudaDeviceSynchronize(); 
            
            // b. Trasferimento Device-to-Host per riportare i dati in RAM 
            cudaMemcpy(h_grid, d_grid, mem_size, cudaMemcpyDeviceToHost); 
            
            // c. Scrittura su disco tramite l'Host
            sprintf(myfile, "video/grid-%07d", iter + 1);
            dump(h_grid, myfile);
        }
        #endif
    }
    cudaDeviceSynchronize();
    
    double dT = (omp_get_wtime() - start_time) * 1e3;
    
    cudaMemcpy(h_grid, d_grid, mem_size, cudaMemcpyDeviceToHost); // Update host finale prima del dump
    
    printf("[statistics] %dx%d %d iter dT: %.2f msec dT/iter: %.2f usec GFLOPS: %.2f\n",
           GLX, GLY, MAXITER, dT, (dT * 1000.0) / (double)MAXITER, 
           (5.0 * (double)MAXITER * (double)GLX * (double)GLY) / (dT * 1e6));

    cudaFree(d_grid); cudaFree(d_grid_new); free(h_grid);
    return 0;
}