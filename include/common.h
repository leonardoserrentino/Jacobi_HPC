#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Dimensioni della griglia fisica e ghost borders
#ifndef GLX
#define GLX 512 
#endif
#ifndef GLY
#define GLY 512
#endif
#define HX 1
#define HY 1

// Dimensione totale in memoria
#define GX (HX+GLX+HX)
#define GY (HY+GLY+HY)

#ifndef MAXITER
#define MAXITER 10000
#endif

// Costanti termiche
#define TB 72.0  
#define TH 212.0 
#define TC 32.0  
#define K 16

// Inizializzazione della griglia
void init(double *grid) {
    int GLYH2 = (int)(GLY / 2);
    
    // Inizializzazione a temperatura fredda TC
    for(int i = 0; i < GY; i++){
        for(int j = 0; j < GX; j++){
            int index = i * GX + j;
            grid[index] = TC;
        }
    }

    // Inizializzazione del gradiente termico a destra
    for (int i = HY; i < HY + GLYH2; i++) {
        for (int j = (GX - HX - 1 - K); j < (GX - HX); j++) {
            grid[i * GX + j] = TC + ((double)(TH * 2 * (i - HY)) / (double)(GLY));
        }
    }
    
    for (int i = HY + GLYH2; i < HY + GLY; i++) {
        for (int j = (GX - HX - 1 - K); j < (GX - HX); j++) {
            grid[i * GX + j] = TC + ((double)(TH * 2 * (GY - (i - HY))) / (double)(GLY));
        }
    }
}

#ifndef DUMPSTEP
#define DUMPSTEP 500 // Salva un frame ogni 500 iterazioni
#endif
#ifndef DUMP
#define DUMP 1       // Abilita il dump di default per ora
#endif

void dump(double *grid, const char *filename) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        fprintf(stderr, "Error opening output file\n");
        exit(EXIT_FAILURE);
    }
    for (int i = 1; i < GY - 1; i++) {
        // Scrive solo la griglia fisica, escludendo i ghost borders (HX)
        fwrite((grid + (i * GX) + HX), sizeof(double), GLX, file); 
    }
    fclose(file);
}
#endif