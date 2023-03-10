#!/bin/bash

#SBATCH --job-name=drgmp_hash
#SBATCH --ntasks-per-node=32

start=`date +%s`
echo $HOSTNAME

source $1/conda.sh
conda activate $2
ref=$3
refdir=$(echo ${ref%/*})

echo "Creating hash tables for DRAGMAP..."
dragen-os \
    --build-hash-table true \
    --ht-reference $3 \
    --output-directory $refdir \
    --ht-num-threads 32

(exit) && echo success
end=`date +%s`
runtime=$((end-start))
echo "RUNTIME: $runtime"
