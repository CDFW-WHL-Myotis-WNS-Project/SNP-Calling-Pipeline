#!/bin/bash

#SBATCH --job-name=htstream
#SBATCH --nodes=1
#SBATCH --ntasks=9
#SBATCH --cpus-per-task=1

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1`
lib=`sed "${SLURM_ARRAY_TASK_ID}q;d" $2`
[[ -d $3 ]] || mkdir -p $3
[[ -d $3/${lib}/${sample} ]] || mkdir -p $3/${lib}/${sample}

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "${sample} ${lib}"

module load htstream

echo "Cleaning raw sequences..."
hts_Stats -L $3/${lib}/${sample}/${sample}.json -N 'initial stats' \
	  -1 $4/${sample}_R1_001.fastq.gz \
	  -2 $4/${sample}_R2_001.fastq.gz | \
    hts_SeqScreener -A $3/${lib}/${sample}/${sample}.json -N 'screen phix' | \
        hts_AdapterTrimmer -A $3/${lib}/${sample}/${sample}.json -N 'trim adapters' | \
    hts_QWindowTrim -A $3/${lib}/${sample}/${sample}.json -N 'quality trim the ends of reads' | \
    hts_NTrimmer -A $3/${lib}/${sample}/${sample}.json -N 'remove any remaining N characters' | \
    hts_LengthFilter -A $3/${lib}/${sample}/${sample}.json -N "remove reads < 100bp" -n -m 100 | \
    hts_Stats -A $3/${lib}/${sample}/${sample}.json -N 'final stats' -F -f $3/${lib}/${sample}/${sample}_preproc

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
