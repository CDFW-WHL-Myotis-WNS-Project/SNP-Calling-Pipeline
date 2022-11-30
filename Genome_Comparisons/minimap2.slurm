#!/bin/bash

#SBATCH --time=80:00:00
#SBATCH --job-name=minimap
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=50000
#SBATCH --partition=production
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/minimap2_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/minimap2_%A.err

dir="/share/cdfwwildlife/MYLU_NovaSeq/REF"

module load minimap2
module load samtools

echo "Running minimap2 on whole genomes allowing 1% divergence..."
minimap2 -t 6 -ax asm10 ${dir}/HiC_Genome/mMyoLuc1.fa ${dir}/M.septentrionalis.mtDNA.fa | samtools view -bh -@ 2 -m 3G - | samtools sort -@ 2 -m 3G -O bam -o ${dir}/minimap2_output/Msep.mtDNA_HiC_asm10.sorted.bam
minimap2 -t 6 -x asm10 ${dir}/HiC_Genome/mMyoLuc1.fa ${dir}/M.septentrionalis.mtDNA.fa > ${dir}/minimap2_output/Msep.mtDNA_HiC_asm10.paf
echo "asm10 DONE"

echo "Running minimap2 on whole genomes allowing 5% divergence..."
minimap2 -t 6 -ax asm20 ${dir}/HiC_Genome/mMyoLuc1.fa ${dir}/M.septentrionalis.mtDNA.fa | samtools view -bh -@ 2 -m 3G - | samtools sort -@ 2 -m 3G -O bam -o ${dir}/minimap2_output/Msep.mtDNA_HiC_asm20.sorted.bam
minimap2 -t 6 -x asm20 ${dir}/HiC_Genome/mMyoLuc1.fa ${dir}/M.septentrionalis.mtDNA.fa > ${dir}/minimap2_output/Msep.mtDNA_HiC_asm20.paf
echo "asm20 DONE"

#' NOTES:
##' -a -- sam output format
##' -x asm5 preset -- align reference genomes with ~0.1 or less sequence divergence
