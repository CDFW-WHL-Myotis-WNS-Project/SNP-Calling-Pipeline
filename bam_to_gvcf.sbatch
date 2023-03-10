#!/bin/bash

#SBATCH --job-name=GATK4hapcall
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

sample=`sed "${SLURM_ARRAY_TASK_ID}q;d" $1/indiv_scaff.tsv`
lib=`sed "${SLURM_ARRAY_TASK_ID}q;d" $2`
ref=$3
refdir=$(echo ${ref%/*})
samp=$(echo ${sample} | awk '{print $1}')
scaff=$(echo ${sample} |  awk '{print $2}')
if [[ $4 ]] && [[ ! -f $1/${scaff}.bed ]]
then
    cat $4 | grep -w ${scaff} > $1/${scaff}.bed
elif [[ ! -f $1/${scaff}.bed ]]
    cat $3.fai | grep -w ${scaff} | awk '{print $1"\t0\t"$2-1}' > $1/${scaff}.bed
fi
[[ -d $1/${samp}_${scaff} ]] || mkdir -p $1/${samp}_${scaff}
[[ -d $7/${lib} ]] || mkdir -p $7/${lib}

start=`date +%s`
echo $HOSTNAME
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "${sample} ${lib}"

echo "Calibrating DRAGEN STR model for haplotype calling..."
java -jar -Xmx4G $5 CalibrateDragstrModel \
     -R $3 \
     -I $6${lib}/${samp}/*bam \
     -L $1/${scaff}.bed \
     -str $refdir/str_table.tsv \
     -O $7/dragstr_model/${samp}_${scaff}.dragstr_model.txt

if [ $4 ]
then
    echo "Calling individual haplotypes over specified intervals..."
else
    echo "Calling individual haplotypes..."
fi
java -jar -Xmx4G $5 HaplotypeCaller \
     -R $3 \
     -I $6/${lib}/${samp}/*bam \
     -O $7/${samp}_${scaff}.g.vcf.gz \
     -L $1/${scaff}.bed \
     -ERC GVCF \
     --dragen-mode true \
     --dragstr-params-path $7/dragstr_model/${samp}_${scaff}.dragstr_model.txt \
     --use-jdk-deflater \
     --use-jdk-inflater \
     --tmp-dir $1/${samp}_${scaff}
rm -rf $1/${samp}_${scaff}

echo "Compressing gvcf..."
java -jar -Xmx4G $5 ReblockGVCF \
     -R $3 \
     -V $7/${samp}_${scaff}.g.vcf.gz \
     -O $7/${samp}_${scaff}.rb.g.vcf.gz \
     --use-jdk-deflater \
     --use-jdk-inflater
rm $7/${samp}_${scaff}.g.vcf.g*

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
