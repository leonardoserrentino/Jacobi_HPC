#include "common.h"
#include <omp.h>

void jacobi_update_omp(double *restrict grid_new, const double *restrict grid) {
    // Thread Parallelism: Suddivisione rigida (static) lungo le righe per minimizzare 
    // l'overhead di sincronizzazione e mantenere la cache calda.
    #pragma omp parallel for schedule(static)
    for (int i = 1; i < GY - 1; i++) {
        // SIMD vettorizzazione esplicita abilitata implicitamente dai compilatori moderni
        for (int j = 1; j < GX - 1; j++) {
            grid_new[i * GX + j] = (grid[i * GX + j] + 
                                    grid[(i - 1) * GX + j] + 
                                    grid[(i + 1) * GX + j] + 
                                    grid[i * GX + (j - 1)] + 
                                    grid[i * GX + (j + 1)]) / 5.0;
        }
    }
}

int main() {
    // Disabilita il buffering dell'output: ogni printf andrà SUBITO nel file .out di SLURM
    setvbuf(stdout, NULL, _IONBF, 0);
    
    char myfile[64];

    size_t mem_size = GX * GY * sizeof(double);
    double *grid = (double*) malloc(mem_size);
    double *grid_new = (double*) malloc(mem_size);
    
    init(grid);
    memcpy(grid_new, grid, mem_size);

    #if DUMP == 1
    sprintf(myfile, "video/grid-%07d", 0);
    dump(grid, myfile);
    #endif

    double start_time = omp_get_wtime();
    
    for (int iter = 1; iter <= MAXITER; iter++) {
        jacobi_update_omp(grid_new, grid);

        #if DUMP == 1
        if (iter % DUMPSTEP == 0) {
            sprintf(myfile, "video/grid-%07d", iter);
            dump(grid_new, myfile);
        }
        #endif
        
        // Swap dei puntatori (zero-copy overhead)
        double *temp = grid;
        grid = grid_new;
        grid_new = temp;
    }
    
    double dT = (omp_get_wtime() - start_time) * 1e3;
    
    // Metriche architetturali
    printf("[statistics] %dx%d %d iter dT: %.2f msec dT/iter: %.2f usec GFLOPS: %.2f\n",
           GLX, GLY, MAXITER, dT, (dT * 1000.0) / (double)MAXITER, 
           (5.0 * (double)MAXITER * (double)GLX * (double)GLY) / (dT * 1e6));
           
    free(grid); free(grid_new);
    return 0;
}