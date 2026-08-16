# --- Toolchain e Flags ---
CC = gcc
NVCC = nvcc
CFLAGS = -Wall -Ofast -fopenmp -lm -march=native
NVFLAGS = -O3 -arch=sm_80 -Xcompiler -fopenmp
PYTHON = python3

# --- Directory ---
SRC_DIR = src
INC_DIR = include
SCRIPTS_DIR = scripts
VIDEO_DIR = video

# --- Target Principali ---
.PHONY: all check venv build submit clean post-process

all: check build

# 1. Controllo prerequisiti (esegue comandi fittizi per verificare che i tool esistano nel PATH)
check:
	@echo "==> Controllo Prerequisiti HPC..."
	@which $(CC) > /dev/null || (echo "GCC non trovato! Fai 'module load gcc'" && exit 1)
	@which $(NVCC) > /dev/null || (echo "NVCC non trovato! Fai 'module load cuda'" && exit 1)
	@which gnuplot > /dev/null || (echo "Gnuplot non trovato!" && exit 1)
	@which convert > /dev/null || (echo "ImageMagick (convert) non trovato!" && exit 1)
	@echo "==> Tutti i tool di base sono disponibili."

# 2. Creazione dell'ambiente Python isolato (se non esiste)
venv:
	@echo "==> Configurazione Virtual Environment Python..."
	@if [ ! -d "venv" ]; then \
		$(PYTHON) -m venv venv; \
		./venv/bin/pip install --upgrade pip; \
		./venv/bin/pip install matplotlib; \
	fi
	@echo "==> Ambiente Python pronto."

# 3. Compilazione
build: $(SRC_DIR)/jacobi_serial.c $(SRC_DIR)/jacobi_omp.c $(SRC_DIR)/jacobi_cuda.cu
	@echo "==> Compilazione dei sorgenti..."
	$(CC) $(CFLAGS) -I$(INC_DIR) -o jacobi-serial $(SRC_DIR)/jacobi_serial.c
	$(CC) $(CFLAGS) -I$(INC_DIR) -o jacobi-omp $(SRC_DIR)/jacobi_omp.c
	$(NVCC) $(NVFLAGS) -I$(INC_DIR) -o jacobi-cuda $(SRC_DIR)/jacobi_cuda.cu
	@mkdir -p $(VIDEO_DIR)
	@echo "==> Build completata con successo."

# 4. Sottomissione automatica a SLURM
submit: build venv
	@echo "==> Sottomissione del Job a SLURM..."
	sbatch $(SCRIPTS_DIR)/JACOBI.slurm

# 5. Generazione Grafici e Video (chiamato automaticamente dallo script SLURM alla fine)
post-process:
	@echo "==> Generazione Video Animazione..."
	@$(SCRIPTS_DIR)/mkvideo.sh 0 10000 500
	@echo "==> Generazione Plot Prestazionali..."
	@./venv/bin/python $(SCRIPTS_DIR)/plot_performance.py

# Pulizia
clean:
	@echo "==> Pulizia repository..."
	/bin/rm -f jacobi-serial jacobi-omp jacobi-cuda
	/bin/rm -f jacobi-*.out
	/bin/rm -rf $(VIDEO_DIR)/*
	/bin/rm -f performance_scaling.png video.gif