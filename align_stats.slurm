#!/bin/bash

#SBATCH --job-name=align_stats
#SBATCH --nodes=1
#SBATCH --ntasks=7

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
lib=`sed "${SLURM_ARRAY_TASK_ID}q;d" $2`
[[ -d $3/${lib}/${sample} ]] || mkdir -p $3/${lib}/${sample}
ref=$4
refpre=$(echo ${ref%.*})

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "${sample} ${lib}"

module load samtools
module load bedtools2

echo "indexing bam..."
samtools index $5/${lib}/${sample}/${sample}*.bam &&

echo "Calculating samtools stats:"
echo "  flagstat..."
samtools flagstat $5/${lib}/${sample}/${sample}*.bam > $3/${lib}/${sample}/${sample}.dragmap_flagstat.txt
echo "  stats..."
samtools stats -c 1,10000,100 $5/${lib}/${sample}/${sample}*.bam > $3/${lib}/${sample}/${sample}.dragmap_stats.txt
echo "  idxstats..."
samtools idxstats $5/${lib}/${sample}/${sample}*.bam > $3/${lib}/${sample}/${sample}.dragmap_IDstats.tsv
echo "  depth..."
samtools depth $5/${lib}/${sample}/${sample}*.bam | awk '{sum+=$3; cnt++}END{print "no_positions\tmean_depth"; print sum"\t"sum/cnt}' > $3/${lib}/${sample}/${sample}.dragmap_depth.txt
echo "  coverage..."
samtools coverage $5/${lib}/${sample}/${sample}*.bam > $3/${lib}/${sample}/${sample}.dragmap_coverage.tsv

echo "Calculating GATK metrics..."
echo "checking mapping quality"
java -jar -Xmx4G $4 CollectAlignmentSummaryMetrics \
    -R $4 \
    -I $5/${lib}/${sample}/${sample}*.bam \
    -O $3/${lib}/${sample}/${sample}.dragmap.gatk.stat.txt

echo "Calculating coverage for 50Kb windows..."
echo -e "scaff\twin_start\twin_end\tmean_depth" > $3/${lib}/${sample}/${sample}.dragmap_50kbwin_meancov.tsv
bedtools coverage -mean -sorted -a ${refpre}_50kb_win.bed -b $5/${lib}/${sample}/${sample}*.bam >> $3/${lib}/${sample}/${sample}.dragmap_50kbwin_meancov.tsv

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime seconds"
