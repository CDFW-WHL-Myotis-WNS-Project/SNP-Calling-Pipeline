#!/bin/bash

#SBATCH --job-name=callSNPs_pipeline
#SBATCH --time=20-00:00:00
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --output=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/00_CLARCS_pipeline_%A.out
#SBATCH --error=/share/cdfwwildlife/MYLU_NovaSeq/SCRIPTS/slurmout/00_CLARCS_pipeline_%A.err

# by Samantha L.R. Capel <Samantha.Capel@Wildlife.ca.gov> <slr.capel2@gmail.com>

###############
# DESCRIPTION #
###############
# This pipeline performs whole-genome SNP calling of whole genome resequencing data following the DRAGEN-GATK best practices protocol (https://gatk.broadinstitute.org/hc/en-us/articles/4407897446939)
# with the exception of extra preprocessing utilizing HTStream. Preprocessing laregely follows the recommendations of the UC Davis Bioinformatics Core (https://ucdavis-bioinformatics-training.github.io/2020-mRNA_Seq_Workshop/data_reduction/01-preproc_htstream_mm) 
# with the addition of filtering reads with short (< 100bp) insert lengths, a necessary step for avoidance of segmenation fault errors for DRAGMAP v1.2.1. This pipeline works with samples sequenced on 
# individual lanes or samples sequenced across multiple lanes. Restriction of SNP-calling to specific genomic intervals as well as masking of unwanted regions is also possible by specifying whitelist or 
# blacklist files (see below). This pipeline was developed using the job scheduling manager SLURM on an HPC cluster.


################
# DEPENDENCIES #
################
# HTStream       (https://s4hts.github.io/HTStream/#hts_QWindowTrim; conda install -c bioconda htstream)
# DRAGMAP v1.2.1 (https://github.com/Illumina/DRAGMAP; conda install -c bioconda dragmap=1.2.1)
# picard         (https://github.com/broadinstitute/picard; conda install -c bioconda picard)
# GATK4          (https://github.com/broadinstitute/gatk; conda install -c bioconda gatk4)
# samtools       (https://github.com/samtools/samtools; conda install -c bioconda samtools)
# bedtools       (https://github.com/arq5x/bedtools2; conda install -c bioconda bedtools)
# bcftools       (https://github.com/samtools/bcftools; conda install -c bioconda bcftools)
## NOTE: conda used to load DRAGMAP & picard


##################
# REQUIRED FILES #
##################
# raw fastq files
# reference genome fasta
# sample list(s): file containing sample prefixes (one per line); if reads need to be merged across lanes create two separate prefix lists - one with and one without lane designation
# read group information file: tab delimited file containing the following read group information for each (unmerged) sample (one per line) in the following order - ID SM LB PL PU
## ID = sample read group ID (e.g. sample prefix including lane designation; identical to SM if sequenced on a single lane)
## SM = sample name (excluding lane designation)
## LB = DNA prep library identifyier (only imporatant if multiple libraries were sequenced)
## PU = platform uint coded as {flowcell_barcode}.{lane_number}.{sample_name}; flowcell barcodes can be found at the begining of most fastq headers formated as @<instrument>:<run number>:<flowcell ID>
# OPTIONAL: text file of subdirectory designations for each sample (one line per sample); e.g. sample library, population, etc.
# OPTIONAL: bed specifying genomic interval(s) to include OR bed file specifying genomic interval(s) to exclude/mask


#################
# SET VARIABLES #
#################
dir=""  # path to root directory for all input and output files
std=""  # desired path for standard output and error files for each job (will be created)

dirconda=""  # path to directory containing conda.sh
envconda=""  # name of conda environment containing DRAGMAP & picard (& fastq-filter?)
gatkjar=""  # path and name of gatk jar file

ref="${dir}/"  # path to reference genome
include=""  # OPTIONAL bed file with intervals to detect SNPs within; for whole genome leave blank
exclude=""  # OPTIONAL path to masking bed file for SNP calling

raw="${dir}/"  # directory containing raw reads
samples="${dir}/"  # path to file containing fastq sample prefixes (including individual lane designations if applicable)
samples_merged="${dir}/"  # path to file containing merged sample prefixes (i.e. excluding lane designations); if samples sequenced on single lane set to same file path as ${samples} 
lib="${dir}/"  # OPTIONAL group designations (one line per sample) for sample group subdirectory organization; leave blank if not applicable/desired
rg="${dir}/"  # read group information file

# IF READS NEED TO BE MERGED ACROSS LANES ##
merge=""  # set to any string if fastqs need to be merged across multiple lanes, if not leave empty
lane=""  # shared lane designation prefix (e.g. "_L00" for sample_prefix_L001, sample_prefix_L002, etc.)

## NOTE: time limits and/or memory allocation may need to be adjusted depending on fastq size


############
# PIPELINE #
############
temp="${dir}/temp"
preproc="${dir}/01_HTS_PreProc"
align="${dir}/02_AlignDRAGMAP"
stats="${dir}/03_AlignStats"
vcfs="${dir}/04_GATKvcfs"
[[ -d ${std} ]] || mkdir -p ${std}
[[ -d ${dir}/temp ]] || mkdir -p ${dir}/temp
[[ -d ${preproc} ]] || mkdir -p ${preproc}
[[ -d ${align} ]] || mkdir -p ${align}
[[ -d ${stats} ]] || mkdir -p ${stats}
[[ -d ${vcfs} ]] || mkdir -p ${vcfs}
[[ -d ${vcfs}/dragstr_model ]] || mkdir -p ${vcfs}/dragstr_model
[[ -d ${vcfs}/genomicDB ]] || mkdir -p ${vcfs}/genomicDB

total=$(cat $samples | wc -l)
nindiv=$(cat $samples_merged | wc -l)
module load samtools
samtools faidx ${ref}
if [ ${include} ]
then
    cat ${include} | cut -f 1 | sort | uniq > ${temp}/scaffolds.txt
else
    cat ${ref}.fai | cut -f 1 > ${temp}/scaffolds.txt
fi
cat $samples_merged | while read indiv
do
    cat ${temp}/scaffolds.txt | while read scaff
    do
	echo -e "${indiv}\t${scaff}"
    done
done > ${temp}/indiv_scaff.tsv
nscaffs=$(cat ${temp}/indiv_scaff.tsv | cut -f 2 | sort | uniq | wc -l)
ind_scaf=$((${nindiv}*${nscaffs}))


## CLEAN & ALIGN ##
echo "Trimming and cleaning raw reads..."
htsid=$(sbatch -t 02-00:00:00 \
       --array=1-${total} \
       --mem=200MB \
       --output=${std}/01_htstream_%A_%a.out \
       --error=${std}/01_htstream_%A_%a.err \
       HTS_preproc.slurm ${samples} ${lib} ${preproc} ${raw} | sed 's/Submitted batch job //')

echo "Aligning reads to genome, assigning read groups, and marking duplicates..."
htid=$(sbatch -t 05-00:00:00 \
       --mem=85GB \
       --output=${std}/dragmap_hash_%A.out \
       --error=${std}/dragmap_hash_%A.err \
       --dependency=afterok:$htsid \
       hashDRAGMAP.slurm ${dirconda} ${envconda} ${ref} | sed 's/Submitted batch job //')
dmid=$(sbatch -t 02-00:00:00 \
       --array=1-${total} \
       --mem=45GB \
       --output=${std}/02_DRAGMAP_%A_%a.out \
       --error=${std}/02_DRAGMAP_%A_%a.err \
       --dependency=afterok:$htid \
       alignDRAGMAP.slurm ${samples} ${lane} ${lib} ${align} ${ref} ${dirconda} ${envconda} ${temp} ${preproc} ${rg} ${gatkjar} | sed 's/Submitted batch job //')

if [ ${merge} ]
then
   echo "Merging files across lanes..."
   mgid=$(sbatch -t 02-00:00:00 \
	  --array=9-${nindiv}%25 \  # 1-${nindiv}%25 for all unmerged samples
	  --mem=2G \
	  --output=${std}/03_merge_%A_%a.out \
	  --error=${std}/03_merge_%A_%a.err \
	  --dependency=afterok:$dmid \
	  samtools_merge.slurm ${samples_merged} ${lib} ${align} ${lane} | sed 's/Submitted batch job //')
   echo "Breaking genome into 50 Kb windows..."
   gwid=$(sbatch -t 05:00:00 \
       --mem=1G \
       --output=${std}/genome_win_%A.out \
       --error=${std}/genome_win_%A.err \
       --dependency=afterok:$mgid \
       genome_wins.slurm ${ref} | sed 's/Submitted batch job //')
else
    echo "Breaking genome into 50 Kb windows..."
   gwid=$(sbatch -t 05:00:00 \
       --mem=1G \
       --output=${std}/genome_win_%A.out \
       --error=${std}/genome_win_%A.err \
       --dependency=afterok:$dmid \
       genome_wins.slurm ${ref} | sed 's/Submitted batch job //')
fi

echo "Calculating alignment statistics..."
asid=$(sbatch -t 2-00:00:00 \
       --array=1-${nindiv} \
       --mem=30G \
       --output=${std}/04_stats_%A_%a.out \
       --error=${std}/04_stats_%A_%a.err \
       --dependency=afterok:$gwid
       align_stats.slurm ${samples_merged} ${lib}  ${stats} ${ref} ${align} ${gatkjar} | sed 's/Submitted batch job //')


## CALL SNPS ##
echo "Calibrating DRAGEN STR model & callig haplotypes..."
stid=$(sbatch -t 02-00:00:00 \
       --mem=200MB \
       --output=${std}/str_table_%A.out \
       --error=${std}/str_table_%A.err \
       --dependency=afterok:$asid \
       STRtable.slurm ${ref} ${dirconda} ${envconda} ${include} ${gatkjar} | sed 's/Submitted batch job //')
htcid=$(sbatch -t 10-00:00:00 \
       --mem=10GB \
       --array=1-${ind_scaf} \
       --error=${std}/05_hapcall_%A_%a.err \
       --output=${std}/05_hapcall_%A_%a.out \
       --dependency=afterok:$stid \
       bam_to_gvcf.sbatch ${temp} ${lib} ${ref} ${include} ${gatkjar} ${align} ${vcfs} | sed 's/Submitted batch job //')

echo "Joint genotyping indidividuals by scaffold..."
gtgid=$(sbatch -t 10-00:00:00 \
       --mem=10GB \
       --array=1-${nscaffs} \
       --error=${std}/06_genotype_%A_%a.err \
       --output=${std}/06_genotype_%A_%a.out \
       --dependency=afterok:$htcid \
       gvcf_to_vcf_scaff.sbatch ${temp} ${vcfs} ${gatkjar} ${ref} | sed 's/Submitted batch job //')

echo "Concatenating vcfs & filtering SNPs..."
sbatch -t 05-00:00:00 \
       --mem=10GB \
       --error=${std}/07_concat_vcfs_filter_SNPs_%A.err \
       --output=${std}/07_concat_vcfs_filter_SNPs_%A.out \
       --dependency=afterok:$gtgid \
       vcf_scaff_to_snp.vcf.slurm ${vcfs} ${gatkjar} ${exclude}
    
(exit) && echo success
