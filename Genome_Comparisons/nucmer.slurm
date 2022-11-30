#!/bin/bash

#SBATCH --time=80:00:00
#SBATCH --job-name=nucmer
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --mem=50000
#SBATCH --partition=production
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/nucmer_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/nucmer_%A.err

dir="/share/cdfwwildlife/MYLU_NovaSeq/REF"
pre="ENS_HiC_nucmer"

module load mummer

# Align genomes
echo "Aligning genomes using nucmer..."
nucmer -t 32 -p ${dir}/nucmer_output/${pre} --mum -c 1000 -l 50 ${dir}/HiC_Genome/mMyoLuc1.fa ${dir}/Old_Genome/GCF_000147115.1_Myoluc2.0_genomic.fna

# Filter to longest alignments
echo "Filtering delta file..."
delta-filter -1 -q -i 90 ${dir}/nucmer_output/${pre}.delta > ${dir}/nucmer_output/${pre}.1-to-1.delta &&

echo "!! To convert .delta to .sam:"
echo "conda activate svanalyzer; perl delta2perl.py --delta ${pre}.filter.delta --out ${pre}.sam"
    
# Create summary of all alignments
#echo "Creating summary of alignments..."
#show-coords -r -c -l ${dir}/nucmer_output/${pre}.1-to-1.delta > ${dir}/nucmer_output/${pre}.1-to-1.coords

# Produce a minimal tiling of contigs across reference
#echo "Producing minimal tiling of contigs..."
#show-tiling ${dir}/nucmer_output/${pre}.1-to-1.delta > ${dir}/nucmer_output/${pre}.1-to-1.tiling

# Summarize all SNPs and indels
# echo "Summarizing SNPs and indels..."
# show-snps -C ${dir}/nucmer_output/${pre}.1-to-1.delta > ${dir}/nucmer_output/${pre}.1-to-1.snps

# View output
#mummerplot -x [0:150000] -y [0:150000] -t x11 -p ${dir}/nucmer_output/${pre} ${dir}/nucmer_output/${pre}.global.delta
