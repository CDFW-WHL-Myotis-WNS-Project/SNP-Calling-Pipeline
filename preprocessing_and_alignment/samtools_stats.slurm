#!/bin/bash

#SBATCH --job-name=samtools_stats
#SBATCH --nodes=1
#SBATCH --ntasks=5
#SBATCH --cpus-per-task=1
#SBATCH --mem=5MB  # LowCov = 5MB; HiCov = 1G
#SBATCH --array=1-51  # LowCov = 1-51; HiCov = 1-8
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/04_stats_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/04_stats_%A_%a.err

echo "Calculating samtools stats..."

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
echo "SAMPLE: ${sample}"
[[ -d $3/${sample} ]] || mkdir -p $3/${sample}

module load samtools

samtools index $2/${sample}/${sample}*.bam &&
samtools flagstat $2/${sample}/${sample}*.bam > $3/${sample}/${sample}_flagstat.txt
samtools stats -c 1,10000,100 $2/${sample}/${sample}*.bam > $3/${sample}/${sample}_stats.txt
samtools idxstats $2/${sample}/${sample}*.bam > $3/${sample}/${sample}_IDstats.tsv
samtools coverage $2/${sample}/${sample}*.bam > $3/${sample}/${sample}_coverage.tsv
samtools depth $2/${sample}/${sample}*.bam | awk '{sum+=$3; cnt++}END{print "no_positions\tmean_depth"; print sum"\t"sum/cnt}' > $3/${sample}/${sample}_depth.txt

end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime seconds"
