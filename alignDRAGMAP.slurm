#!/bin/bash

#SBATCH --job-name=DRAGMAP
#SBATCH --ntasks-per-node=32

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
ind=$(echo ${sample} | sed -E "s/$2.+//")
lib=`sed "${SLURM_ARRAY_TASK_ID}q;d" $3`
[[ -d $4/${ind} ]] || mkdir -p $4/${ind}
ref=$5
refdir=$(echo ${ref%/*})

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "${sample} ${lib}"

module load samtools
aklog
source $6/conda.sh
conda activate $7
export TMPDIR=$8

echo "Aligning reads..."
dragen-os -v \
    -r $refdir \
    -1 $9/${lib}/${sample}/${sample}_preproc_R1.fastq.gz \
    -2 $9/${lib}/${sample}/${sample}_preproc_R2.fastq.gz \
    --num-threads 32 | \
    samtools view -bh -@ 2 - | \
    samtools sort -@ 2 -O bam -o $4/${lib}/${ind}/${sample}.sorted.bam

echo "Replacing read groups..."
lb=$(cat $10 | grep -w ${sample} | awk '{print $3}')
sm=$(cat $10 | grep -w ${sample} | awk '{print $2}')
pu=$(cat $10 | grep -w ${sample} | awk '{print $4}')
picard AddOrReplaceReadGroups -I $4/${lib}/${ind}/${sample}.sorted.bam -O $4/${lib}/${ind}/${sample}.sorted.rg.bam -PL Illumina -LB ${lb} -SM ${sm} -ID ${sample} -PU ${pu} &&
rm $4/${lib}/${ind}/${sample}.sorted.bam &&

echo "Marking duplicates..."        
java -jar -Xmx4G $11 MarkDuplicates -I $4/${lib}/${ind}/${sample}.sorted.rg.bam \
     -O $4/${lib}/${ind}/${sample}.sorted.rg.md.bam \
     -M $4/${lib}/${ind}/${sample}.sorted.rg.md.metric.txt &&
rm $4/${lib}/${ind}/${sample}.sorted.rg.bam &&

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
