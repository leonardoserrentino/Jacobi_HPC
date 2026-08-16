#!/usr/bin/env python3
import matplotlib.pyplot as plt
import re

# Dati di esempio simulati (in un caso reale, parsare l'output SLURM)
implementations = ['Serial (Baseline)', 'OpenMP (32 Threads)', 'CUDA (Ampere/Hopper)']
gflops = [1.2, 28.5, 315.0]  # Esempio di scaling memory-bound

plt.style.use('ggplot')
fig, ax = plt.subplots(figsize=(10, 6))
bars = ax.bar(implementations, gflops, color=['#e74c3c', '#3498db', '#2ecc71'])

# Aggiungiamo i valori in cima alle barre
for bar in bars:
    yval = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, yval + 5, f"{yval} GFLOPS", ha='center', va='bottom', fontweight='bold')

ax.set_ylabel('Performance (GFLOPS)')
ax.set_title('Jacobi Heat Diffusion: Roofline Paradigm & Implementation Scaling')
ax.set_ylim(0, max(gflops) * 1.15)

plt.tight_layout()
plt.savefig('performance_scaling.png', dpi=300)
print("Performance plot saved as performance_scaling.png")