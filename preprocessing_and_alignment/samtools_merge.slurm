#!/bin/bash

#SBATCH --job-name=samtools_merge
#SBATCH --nodes=1
#SBATCH --mem=10MB
#SBATCH --array=1-51  # set to number of samples
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/03_merge_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/03_merge_%A_%a.err

echo "Merging sample reads across lanes..."

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
echo "SAMPLE: ${sample}"
[[ -d $2/${sample} ]] || mkdir -p $2/${sample}

module load samtools
cd $2
lanes=$(ls -d */* | grep ${sample})

samtools merge -o $2/${sample}/${sample}.merge.sorted.bam $lanes
rm -r $2/${sample}$3*  # delete non-merged bam files

end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime seconds"
echo "END ${sample}"
