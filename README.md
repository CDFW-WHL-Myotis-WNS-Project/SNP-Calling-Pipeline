# SNP-Calling Pipeline
This pipeline performs whole-genome SNP calling of paired-end whole genome resequencing data following the [DRAGEN-GATK best practices protocol](https://gatk.broadinstitute.org/hc/en-us/articles/4407897446939) with the exception of extra preprocessing utilizing HTStream. Preprocessing laregely follows the [recommendations of the UC Davis Bioinformatics Core](https://ucdavis-bioinformatics-training.github.io/2020-mRNA_Seq_Workshop/data_reduction/01-preproc_htstream_mm) with the addition of filtering reads with short (< 100bp) insert lengths, necessary for avoiding segmenation fault errors in DRAGMAP v1.2.1. This pipeline works with samples sequenced on a single lane or samples sequenced across multiple lanes. Restriction of SNP-calling to specific genomic intervals as well as masking of unwanted regions is also possible by specifying whitelist or blacklist files. This pipeline was developed on an HPC cluster utilizing [SLURM](https://slurm.schedmd.com/quickstart.html).

<p align="center">
<img src="https://user-images.githubusercontent.com/49217218/225173126-c5fe9e7b-7b9a-4e17-8845-34b24842baba.png" width=80% height=80%>
</p>

## Dependencies:
- [HTStream](https://s4hts.github.io/HTStream/#hts_QWindowTrim)
- [DRAGMAP v1.2.1](https://github.com/Illumina/DRAGMAP)
- [picard](https://github.com/broadinstitute/picard)
- [GATK4](https://github.com/broadinstitute/gatk)
- [samtools](https://github.com/samtools/samtools)
- [bedtools](https://github.com/arq5x/bedtools2)
- [bcftools](https://github.com/samtools/bcftools)

NOTE: scripts use conda to load DRAGMAP & picard; HTStream, samtools, bedtools, and bcftools are all called using `module load` but can be incorporated into the conda environment specified

## Required Input Files:
- raw unmapped FASTQ files
- reference genome FASTA
- sample list(s): file containing sample prefixes (one per line)
    - **LISTS MUST BE SORTED USING** `sort` to ensure samples are properly labled in final VCFs
    - if individuals were sequenced across multiple lanes, create two separate prefix lists - one with and one without lane designations
        | Unmerged | Merged |
        |:----------:|:--------:|
        | <pre>sample1_L001<br>sample1_L002<br>sample2_L001<br>sample2_L002<br>sample3_L001<br>sample3_L002<br></pre> | <pre>sample1<br>sample2<br>sample3<br><br><br><br></pre> |
- read group information file: tab delimited file containing the following read group information for each pair of FASTQ files (one per line) in the following order - ID SM LB PL PU
    - ID = sample read group ID (e.g. sample prefix including lane designation; identical to SM if sequenced on a single lane)
    - SM = sample name (excluding lane designation)
    - LB = DNA library identifyier (only imporatant if multiple libraries were sequenced)
    - PU = platform uint; this can indicate if samples were ran on different lanes and/or different sequencing units
- OPTIONAL: text file of subdirectory designations for each sample (one line per sample); e.g. sample library, population, etc.
- OPTIONAL: bed file specifying genomic interval(s) to include OR bed file specifying genomic interval(s) to exclude/mask

## Instructions:
1. Download all 11 scripts into a single directory
2. Open `clean_align_callSNPs.sbatch` in a text editor and set all required variables in the designated section (starting on line 49)
3. Execute the pipeline by running `sbatch clean_align_callSNPs.sbatch`

## Pipeline components:
### 1. HTS_preproc.slurm
Use HTStream to clean raw paired FASTQ files by screening Illumina PhiX library sequences, trimming adapers, quality trimming read ends, removing 'N's, and filtering reads smaller than 100bp.
### 2. hashDRAGMAP.slurm
Build the reference genome hash table for DRAGMAP.
### 3. alignDRAGMAP.slurm
Use DRAGMAP to align cleaned reads, use picard to replace read group information, and use GATK MarkDuplicates to mark and remove PCR duplicate reads.
### 4. samtools_merge.slurm
If samples were sequenced across multiple lanes, use samtools to merge bams by sample. 
### 5. genome_wins.slurm
Use bedtools to create a bed file of the reference genome broken into 50Kb windows with 10% overlap.
### 6. align_stats.slurm
Use samtools, bedtools, and GATK CollectAlignmentSummaryMetrics to alculate alignment statistics for each sample including mean depth of coverage per sample (whole genome, per scaffold, and per 50Kb window), # and % reads aligned, read and insert length mean and distribution, etc.
### 7. STRtable.slurm
Use GATK ComposeSTRTableFile to create a short tandem repeat (STR) location table of the reference genome used for DragSTR model auto-calibration.
### 8. bam_to_gvcf.sbatch
Use GATK to calibrate the DragSTR model (CalibrateDragstrModel), call individual variants (HaplotypeCaller), and compress individual GVCFs (ReblockGVCF).
### 9. gvcf_to_vcf_scaff.sbatch
Use GATK to import single-sample GVCFs into per-scaffold databases (GenomicsDBImport) and joint call variants (GenotypeGVCFs).
### 10. vcf_scaff_to_snp.vcf.slurm
Use bcftools to combine per-scaffold VCFs then use GATK to remove indels (SelectVariants), quality filter SNPs using the DRAGENHardQUAL filter (VariantFiltration), and create a table of quality metrics for all SNPs (VariantsToTable). Minimum allele frequency filters are automatically applied to SNP filtering and internally calculated as $`5/(total * 2)`$ to ensure at least 3 individuals possess a given allele ([Rochette & Catchen 2017](http://dx.doi.org/10.1038/nprot.2017.123)).
