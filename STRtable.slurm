#!/bin/bash

#SBATCH --job-name=str_table
#SBATCH --nodes=1

ref=$1
refdir=$(echo ${ref%/*})
refpre=$(echo ${ref%.*})

start=`date +%s`
echo $HOSTNAME

source $2/conda.sh
conda activate $3

echo "Composing STR table..."
if [ $4 ]
then
    java -jar -Xmx4G  $5 ComposeSTRTableFile \
	 -R $1 \
	 -O $refdir/str_table.tsv \
	 -L $4
else
    java -jar -Xmx4G  $5 ComposeSTRTableFile \
	 -R $1 \
	 -O $refdir/str_table.tsv
fi

echo "Indexing genome (picard)..."
picard CreateSequenceDictionary -R $1 -O $refpre.dict

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
