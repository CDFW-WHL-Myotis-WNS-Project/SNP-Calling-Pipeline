#!/bin/bash

#SBATCH --job-name=htstream
#SBATCH --nodes=1
#SBATCH --ntasks=9
#SBATCH --cpus-per-task=1
#SBATCH --mem=15GB
#SBATCH --partition=production
#SBATCH --array=1-153  # set to total number of forward read fastq files (LowCov = 1-153; HiCov = 1-8)
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/01_htstream_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/01_htstream_%A_%a.err

echo "Cleaning raw sequences..."

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
[[ -d $3 ]] || mkdir -p $3
[[ -d $3/${sample} ]] || mkdir -p $3/${sample}

echo "SAMPLE: ${sample}"

module load htstream

hts_Stats -L $3/${sample}/${sample}.json -N 'initial stats' \
	  -1 $2/${sample}_R1_001.fastq.gz \
	  -2 $2/${sample}_R2_001.fastq.gz | \
    hts_SeqScreener -A $3/${sample}/${sample}.json -N 'screen phix' | \
    hts_SuperDeduper -A $3/${sample}/${sample}.json -N 'remove PCR duplicates' | \
    hts_AdapterTrimmer -A $3/${sample}/${sample}.json -N 'trim adapters' | \
    hts_QWindowTrim -A $3/${sample}/${sample}.json -N 'quality trim the ends of reads' | \
    hts_NTrimmer -A $3/${sample}/${sample}.json -N 'remove any remaining N characters' | \
    hts_Stats -A $3/${sample}/${sample}.json -N 'final stats' -f $3/${sample}/${sample}_preproc

end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
