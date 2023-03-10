# SNP-Calling Pipeline
This pipeline performs whole-genome SNP calling of whole genome resequencing data following the DRAGEN-GATK best practices protocol (https://gatk.broadinstitute.org/hc/en-us/articles/4407897446939) with the exception of extra preprocessing utilizing HTStream. Preprocessing laregely follows the recommendations of the UC Davis Bioinformatics Core (https://ucdavis-bioinformatics-training.github.io/2020-mRNA_Seq_Workshop/data_reduction/01-preproc_htstream_mm) with the addition of filtering reads with short (< 100bp) insert lengths, a necessary step for avoidance of segmenation fault errors for DRAGMAP v1.2.1. This pipeline works with samples sequenced on a single lane or samples sequenced across multiple lanes. Restriction of SNP-calling to specific genomic intervals as well as masking of unwanted regions is also possible by specifying whitelist or blacklist files (see below). This pipeline was developed using the job scheduling manager SLURM on an HPC cluster.


## Dependencies:
- [HTStream](https://s4hts.github.io/HTStream/#hts_QWindowTrim)
- [DRAGMAP v1.2.1](https://github.com/Illumina/DRAGMAP)
- [picard](https://github.com/broadinstitute/picard)
- [GATK4](https://github.com/broadinstitute/gatk)
- [samtools](https://github.com/samtools/samtools)
- [bedtools](https://github.com/arq5x/bedtools2)
- [bcftools](https://github.com/samtools/bcftools)
NOTE: conda used to load DRAGMAP & picard
