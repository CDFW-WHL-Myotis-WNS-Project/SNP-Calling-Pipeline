#!/bin/bash

#SBATCH --job-name=merge
#SBATCH --nodes=1

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
lib=`sed "${SLURM_ARRAY_TASK_ID}q;d" $2`

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo ${sample}

module load samtools
echo "Merging sample reads across lanes..."
samtools merge -f -o $3/${lib}/${sample}/${sample}.sorted.rg.md.bam $3/${lib}/${sample}/${sample}*$4*.sorted.rg.md.bam
rm $3/${lib}/${sample}/*$4*.bam

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime seconds"

