#!/bin/bash

#SBATCH --job-name=bwa_index
#SBATCH --time=02-00:00:00
#SBATCH --nodes=1
#SBATCH --mem=4G
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/bwa_index_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/bwa_index_%A.err

module load bwa

bwa index -b 375000000 $1
