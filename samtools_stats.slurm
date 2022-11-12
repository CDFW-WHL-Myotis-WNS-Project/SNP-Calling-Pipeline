#!/bin/bash

#SBATCH --nodes=1
#SBATCH --job-name=samtools_stats
#SBATCH --ntasks=8
#SBATCH --mem=5000
#SBATCH --array=1-52
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/04_stats_LowCov_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/04_stats_LowCov_%A_%a.err

dir="/share/cdfwwildlife/MYLU_NovaSeq"

echo "Calculating samtools stats..."
start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

outpath="${dir}/03_Merge"

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" ${dir}/Sample_Lists/LowCov_samples.merge.txt`
echo "SAMPLE: ${sample}"

module load samtools

samtools index ${outpath}/${sample}/${sample}.sorted.bam && \
samtools flagstat ${outpath}/${sample}/${sample}.sorted.bam > ${outpath}/${sample}/${sample}_flagstat.txt && \
samtools stats -c 1,10000,100 ${outpath}/${sample}/${sample}.sorted.bam > ${outpath}/${sample}/${sample}_stats.txt && \
samtools idxstats ${outpath}/${sample}/${sample}.sorted.bam > ${outpath}/${sample}/${sample}_IDstats.tsv && \
samtools coverage ${outpath}/${sample}/${sample}.sorted.bam > ${outpath}/${sample}/${sample}_coverage.tsv && \
samtools depth ${outpath}/${sample}/${sample}.sorted.bam | awk '{sum+=$3; cnt++}END{print "no_positions\tmean_depth"; print sum"\t"sum/cnt}' > ${outpath}/${sample}/${sample}_depth.txt

end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime seconds"
echo "END ${sample}"
