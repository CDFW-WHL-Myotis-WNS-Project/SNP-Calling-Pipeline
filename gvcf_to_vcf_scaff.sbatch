#!/bin/bash

#SBATCH --job-name=GATK4genotype
#SBATCH --nodes=1

scaff=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1/scaffolds.txt`
ls -d $2/*rb.g.vcf.gz | sed -E 's/(.+\/)(.+)\.rb.g.vcf.gz/\2\t\1\2.rb.g.vcf.gz/' > $1/samples.gvcf.txt

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"
echo ${scaff}

# GenomicsDBImport
echo "Importing single-sample gvcfs into database..."
java -jar -Xmx4G $3 GenomicsDBImport \
     --genomicsdb-workspace-path $2/genomicDB/${scaff}.gvcf.db \
     --intervals $1/${scaff}.bed \
     --sample-name-map $1/samples.gvcf.txt \
     --use-jdk-deflater \
     --use-jdk-inflater \
     --tmp-dir $1 \
     --batch-size 26

# GenotypeGVCFs
echo "Joint genotyping all individuals..."
java -jar -Xmx4G $3 GenotypeGVCFs \
     --reference $4 \
     --variant gendb://$2/genomicDB/${scaff}.gvcf.db \
     --output $2/${scaff}.gatk.vcf.gz \
     --tmp-dir $1
rm $2/*.rb.g.vcf.g*

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
