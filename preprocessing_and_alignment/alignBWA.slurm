#!/bin/bash

#SBATCH --job-name=bwamem
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=25GB
#SBATCH --array=1-153  # set to total number of forward read fastq files (LowCov = 1-153; HiCov = 1-8)
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/02_bwa_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/02_bwa_%A_%a.err

echo "Aligning to Mlc HiC genome with bwa mem..."
start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
[[ -d $3/${sample} ]] || mkdir -p $3/${sample}
echo "SAMPLE: ${sample}"

module load bwa
module load samtools

bwa mem -t 8 -R '@RG\tID:'${sample}'\tSM:'${sample} $4 \
    $2/${sample}/${sample}_preproc_R1.fastq.gz \
    $2/${sample}/${sample}_preproc_R2.fastq.gz |
    samtools view -bh -@ 2 -m 3G - | \
    samtools sort -@ 2 -m 3G -O bam -o $3/${sample}/${sample}.sorted.bam

end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"

## NOTES:
# samtools -@ -- allocate additional threads
# samtools -m -- only output alignments with given number of CIGAR bases consuming query sequence >= X
