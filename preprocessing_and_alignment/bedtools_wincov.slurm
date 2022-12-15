#!/bin/bash

#SBATCH --job-name=bedtools_wincov
#SBATCH -p production
#SBATCH --nodes=1
#SBATCH --mem=5MB
#SBATCH --array=1-51  # set to number of samples
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/05_bedtools_cov_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/05_bedtools_cov_%A_%a.err

start=`date +%s`
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
echo "SAMPLE: ${sample}"

module load samtools
module load bedtools2

echo "breaking genome into 50kb windows..."
samtools faidx $2
pre=$(echo $2 | sed -E 's/.fa//')
cat $2.fai | awk '{print $1"\t"0"\t"$2-1}' > ${pre}.bed
bedtools makewindows -b ${pre}.bed -w 50000 -s 45000 > ${pre}_50kb_win.bed

echo "calculating coverage for each window across individuals..."
echo -e "scaff\twin_start\twin_end\tmean_depth" > $4/${sample}/${sample}_50kbwin_meancov.tsv
bedtools coverage -mean -sorted -a ${pre}_50kb_win.bed -b $3/${sample}/${sample}*.sorted.bam >> $4/${sample}/${sample}_50kbwin_meancov.tsv

end=`date +%s`
runtime=$((end-start))
echo -e "RUNTIME: $runtime"
