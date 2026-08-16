#!/bin/bash
#SBATCH --job-name=jacobi_hpc
#SBATCH --output=jacobi-%j.out
#SBATCH --time=0:15:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --partition=ibm      # O la partizione GPU corretta del tuo server
#SBATCH --gres=gpu:1         # Se il server richiede questo flag per allocare la GPU

# 1. Caricamento dei moduli necessari per l'esecuzione e gli script
module purge
# Carica le librerie a runtime (se necessarie) e i tool per i grafici
module load gnuplot imagemagick python/3.10

# Assicuriamoci che la cartella video esista per i dump della memoria [cite: 380-382]
mkdir -p video

echo "--- RUNNING SERIAL ---"
./jacobi-serial

echo "--- RUNNING OPENMP ---"
OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK ./jacobi-omp

echo "--- RUNNING CUDA ---"
./jacobi-cuda

echo "--- POST-PROCESSING ---"
# Lancia lo script bash che a sua volta chiama mkframe.gpl per generare la GIF [cite: 429-433]
./scripts/mkvideo.sh 0 10000 500

# Esegue lo script Python per il grafico. 
# Nota: richiede che la libreria matplotlib sia installata nel Python del server.
python3 ./scripts/plot_performance.py

echo "--- JOB COMPLETATO ---"
