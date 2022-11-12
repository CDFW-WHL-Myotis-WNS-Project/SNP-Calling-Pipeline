#!/bin/bash

#SBATCH --job-name=htstream # Job name
#SBATCH --nodes=1
#SBATCH --ntasks=9
#SBATCH --mem=5000
#SBATCH --partition=production
#SBATCH --array=1-51
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/01_htstream_LowCov_%A_%a.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/01_htstream_LowCov_%A_%a.err

echo "Cleaning raw sequences..."

dir="/share/cdfwwildlife/MYLU_NovaSeq"

start=`date +%s`
echo $HOSTNAME
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" ${dir}/Sample_Lists/LowCov_samples.merge.txt`

inpath="${dir}/00_Raw/LowCov_Samples_SL"
outpath="${dir}/01_HTS_PreProc/LowCov"
[[ -d ${outpath} ]] || mkdir -p ${outpath}
[[ -d ${outpath}/${sample} ]] || mkdir -p ${outpath}/${sample}

echo "SAMPLE: ${sample}"

echo "Combining raw fastq's across lanes..."
## or zcat file file file | gzip > file

cat ${inpath}/${sample}_L001_R1_001.fastq.gz ${inpath}/${sample}_L002_R1_001.fastq.gz ${inpath}/${sample}_L003_R1_001.fastq.gz > ${inpath}/${sample}_R1_001.fastq.gz
cat ${inpath}/${sample}_L001_R2_001.fastq.gz ${inpath}/${sample}_L002_R2_001.fastq.gz ${inpath}/${sample}_L003_R2_001.fastq.gz > ${inpath}/${sample}_R2_001.fastq.gz

module load htstream

hts_Stats -L ${outpath}/${sample}/${sample}.json -N 'initial stats' \
          -1 ${inpath}/${sample}/${sample}.R1_001.fastq.gz \
          -2 ${inpath}/${sample}/${sample}.R2_001.fastq.gz | \
      hts_SeqScreener -A ${outpath}/${sample}/${sample}.json -N 'screen phix' | \
      hts_SuperDeduper -A ${outpath}/${sample}/${sample}.json -N 'remove PCR duplicates' | \
      hts_AdapterTrimmer -A ${outpath}/${sample}/${sample}.json -N 'trim adapters' | \
      hts_QWindowTrim -A ${outpath}/${sample}/${sample}.json -N 'quality trim the ends of reads' | \
      hts_NTrimmer -A ${outpath}/${sample}/${sample}.json -N 'remove any remaining N characters' | \
      hts_Stats -A ${outpath}/${sample}/${sample}.json -N 'final stats' \
          -f ${outpath}/${sample}/${sample} &&

rm ${inpath}/${sample}_R1_001.fastq.gz


end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
