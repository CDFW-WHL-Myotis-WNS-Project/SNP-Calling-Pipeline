#!/bin/bash

#SBATCH --job-name=read_preproc_align
#SBATCH --time=03-00:00:00
#SBATCH --nodes=1
#SBATCH --mem=1MB
#SBATCH --partition=production
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/00_read_preproc_align_test_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/00_read_preproc_align_test_%A.err

################
# DEPENDENCIES #
################
# htstream
# bwa
# samtools
# bedtools

#################
# SET VARIABLES #
#################
set="test"  # specify sample set

dir="/share/cdfwwildlife/MYLU_NovaSeq"  # root directory for input and output files
raw="${dir}/00_Raw/${set}_Samples" #_SL"  # directory containing raw reads
preproc="${dir}/01_HTS_PreProc/${set}"  # directory for preprocessed reads
align="${dir}/02_AlignBWA/${set}"  # directory for aligned reads
stats="${dir}/03_AlignStats/${set}"  # directory for alignment statistic output files
ref="${dir}/REF/HiC_Genome/mMyoLuc1.fa"  # path to reference genome
samples="${dir}/Sample_Lists/${set}_samples.txt"  # path to files containing fastq sample prefixes (including individual lane designations if applicable)

## IF READS NEED TO BE MERGED ACROSS LANES ##
merge="T"  # set to any string if fastqs need to be merged across multiple lanes, if not leave empty
samples_merged="${dir}/Sample_Lists/${set}_samples.merge.txt"  # path to file containing merged sample prefixes (i.e. excluding lane designations)
lane="_L00"  # universal lane designation in sample prefix (used to distiguish between merged and non-merged files)

# !! set array lenghts for each pipeline component !!


################
# RUN PIPELINE #
################
[[ -d ${preproc} ]] || mkdir -p ${preproc}
[[ -d ${align} ]] || mkdir -p ${align}
[[ -d ${stats} ]] || mkdir -p ${stats}

echo "Preprocessing raw reads..."
sbatch -t 02-00:00:00 --wait HTS_preproc.slurm ${samples} ${raw} ${preproc}

echo "Aligning reads to genome..."
sbatch --wait indexBWA.slurm ${ref}
sbatch -t 02-00:00:00 --wait alignBWA.slurm ${samples} ${preproc} ${align} ${ref}

if [ ${merge} ]
then
    echo "Merging files across lanes..."
    sbatch -t 02:00:00 --wait samtools_merge.slurm ${samples_merged} ${align} ${lane}

    echo "Calculating alignment statistics..."
    sbatch -t 02:00:00 samtools_stats.slurm ${samples_merged} ${align} ${stats}
    sbatch -t 02:00:00 bedtools_wincov.slurm ${samples_merged} ${ref} ${align} ${stats}
else
    echo "Calculating alignment statistics..."
    sbatch -t 02:00:00 samtools_stats.slurm ${samples} ${align} ${stats}
    sbatch -t 02:00:00 bedtools_wincov.slurm ${samples} ${ref} ${align} ${stats}
fi
