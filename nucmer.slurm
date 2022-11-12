#!/bin/bash

#SBATCH --time=80:00:00
#SBATCH --job-name=nucmer
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/nucmer_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/nucmer_%A.err

dir="/share/cdfwwildlife/MYLU_NovaSeq/REF"
pre="ENS_HiC_nucmer"

module load mummer

# Align genomes
#nucmer -c 100 -p ${dir}/${pre} ${dir}/mMyoLuc1.fa ${dir}/Old_Genome/GCF_000147115.1_Myoluc2.0_genomic.fna > ${dir}/nucmer.log

# Create summary of all alignments
#show-coords -r -c -l ${dir}/${pre}.delta > ${dir}/${pre}.coords

# Summarize all SNPs and indels
show-snps -C ${dir}/${pre}.delta > ${dir}/${pre}.snps

# Produce a minimal tiling of contigs across reference
#show-tiling ${dir}/${pre}.delta > ${dir}/${pre}.tiling

# View output
#mummerplot -x "[0,150000]" -y "[0,150000]" -postscript -p ${dir}/${pre} ${dir}/${pre}.tiling
