#!/bin/bash

#SBATCH --job-name=gvcf2snp
#SBATCH --nodes=1

start=`date +%s`
echo $HOSTNAME

module load bcftools

echo "Concatenating vcfs..."
bcftools concat -o $1/gatk.all_indivs.vcf.gz -O z $1/*.gatk.vcf.gz
rm $1/*.gatk.vcf.g*

echo "Indexing concatenated vcf..."
bcftools index $1/gatk.all_indivs.vcf.gz
echo "Indexing vcf..."
java -jar -Xmx4G $2 IndexFeatureFile \
     -I $1/gatk.all_indivs.vcf.gz

if [ $3 ]
then
    echo "Selecting SNPs and masking..."
    java -jar -Xmx4G $2 SelectVariants \
    -V $1/gatk.all_indivs.vcf.gz \
    -select-type SNP \
    -XL $3
    -O $1/gatk.snp.vcf.gz
else
    echo "Selecting SNPs..."
    java -jar -Xmx4G $2 SelectVariants \
    -V $1/gatk.all_indivs.vcf.gz \
    -select-type SNP \
    -O $1/gatk.snp.vcf.gz
fi

echo "Filtering SNPs..."
java -jar -Xmx4G $2 VariantFiltration \
      -V $1/gatk.snp.vcf.gz \
      --filter-expression "QUAL < 10.4139" \
      --filter-name "DRAGENHardQUAL" \
      -O $1/gatk.filtered.snp.vcf.gz

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
