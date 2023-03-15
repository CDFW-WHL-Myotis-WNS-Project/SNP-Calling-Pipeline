# SNP-Calling Pipeline
This pipeline performs whole-genome SNP calling of paired-end whole genome resequencing data following the [DRAGEN-GATK best practices protocol](https://gatk.broadinstitute.org/hc/en-us/articles/4407897446939) with the exception of extra preprocessing utilizing HTStream. Preprocessing laregely follows the [recommendations of the UC Davis Bioinformatics Core](https://ucdavis-bioinformatics-training.github.io/2020-mRNA_Seq_Workshop/data_reduction/01-preproc_htstream_mm) with the addition of filtering reads with short (< 100bp) insert lengths, necessary for avoiding segmenation fault errors in DRAGMAP v1.2.1. This pipeline works with samples sequenced on a single lane or samples sequenced across multiple lanes. Restriction of SNP-calling to specific genomic intervals as well as masking of unwanted regions is also possible by specifying whitelist or blacklist files. This pipeline was developed on an HPC cluster utilizing [SLURM](https://slurm.schedmd.com/quickstart.html).

<p align="center">
<img src="https://user-images.githubusercontent.com/49217218/225173126-c5fe9e7b-7b9a-4e17-8845-34b24842baba.png" width=75% height=75%>
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
- sample list(s): file containing sample prefixes (one per line); if individuals were sequenced across multiple lanes create two separate prefix lists - one with and one without lane designations
- read group information file: tab delimited file containing the following read group information for each pair of FASTQ files (one per line) in the following order - ID SM LB PL PU
    - ID = sample read group ID (e.g. sample prefix including lane designation; identical to SM if sequenced on a single lane)
    - SM = sample name (excluding lane designation)
    - LB = DNA library identifyier (only imporatant if multiple libraries were sequenced)
    - PU = platform uint coded as {flowcell_barcode}.{lane_number}.{sample_name}; flowcell barcodes can be found at the begining of most fastq headers formated as @<instrument>:<run number>:<flowcell ID>
- OPTIONAL: text file of subdirectory designations for each sample (one line per sample); e.g. sample library, population, etc.
- OPTIONAL: bed specifying genomic interval(s) to include OR bed file specifying genomic interval(s) to exclude/mask

## Instructions:
Download all 11 scripts into a single directory. Open `clean_align_callSNPs.sbatch` in a text editor and set all required variables in the designated section (starting on line 53). Execute the pipeline by running `sbatch clean_align_callSNPs.sbatch`.
