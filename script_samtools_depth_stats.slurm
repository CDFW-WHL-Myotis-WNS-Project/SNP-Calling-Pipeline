#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=1500:00
#SBATCH --mem=4000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production
#SBATCH --array=1-51
#SBATCH --output=slurmout/depth_%A_%a.out # File to which STDOUT will be written
#SBATCH --error=slurmout/depth_%A_%a.err # File to which STDERR will be written

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
aklog

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" Samples_LowCov.txt`
echo "SAMPLE: ${sample}"

path="/share/cdfwwildlife/MYLU_NovaSeq/03_Merge"

echo "OUTPUT DIR: ${path}"
#[[ -d ${outpath} ]] || mkdir -p ${outpath}
#[[ -d ${outpath}/${sample} ]] || mkdir -p ${outpath}/${sample}
module load samtools


#call="samtools index ${path}/${sample}/${sample}.sorted.bam"
#call="samtools flagstat ${path}/${sample}/${sample}.sorted.bam > ${path}/00_STATS/${sample}_flagstat.log"
#call="samtools coverage ${path}/${sample}/${sample}.sorted.bam -o ${path}/00_STATS/${sample}_coverage.txt"
call="samtools depth ${path}/${sample}/${sample}.sorted.bam  > ${path}/00_STATS/${sample}_depth.txt"


echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo $runtime
