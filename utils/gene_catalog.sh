#!/bin/bash 

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "stool_mags"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --cpus-per-task=64
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=40:00:00


data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Delgado_bile_acids/fastq/clean"
output="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/gene_catalog/data"

module load slurm_setup 
export OMP_NUM_THREADS=64

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate mags

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')


iMGCM_data="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/gene_catalog/reference/iMGMC-data"

## build gene catalog 
for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  bbmap.sh -Xmx30g unpigz=t threads=64 minid=0.90 \
path=${iMGCM_data} nodisk \
statsfile="${sample}".statsfile \
scafstats="${sample}".scafstats \
covstats="${sample}".covstat \
rpkm="${sample}".rpkm \
sortscafs=f nzo=f \
in="$read"

done

#for read in ${inputdatalist};
#do
#  sample=$(basename ${read} | cut -f1 -d"_")
#  make-GeneID-TPM-fromCovStats.sh ${sample}.covstat
#done

# TPM normalization - copy into make-GeneID-TPM-fromCovStats.sh from iMGMC
#SampleID=$1


#echo "Making TPM from ${SampleID}"

#tail -n+2 ${SampleID}.covstats | gawk -v OFS='\t' -v FS='\t' '{print $1, $3, ($7+$8)/(($3-50)/1000)}' > temp-RPK-${SampleID}.tmp
#PerMillionScalingFactor=$(gawk -v OFS='\t' -v FS='\t' '{sum+=$3} END {print sum/1000000}' temp-RPK-${SampleID}.tmp) 
#echo "Sample: "${SampleID}" PerMillionScalingFactor: "${PerMillionScalingFactor}

#gawk -v PMSF=${PerMillionScalingFactor} -v OFS='\t' -v FS='\t' '{print $3/PMSF}' temp-RPK-${SampleID}.tmp >> temp-TPM-${SampleID}.tmp



#paste <(tail -n+2 ${SampleID}.covstats | cut -f1) temp-TPM-${SampleID}.tmp | sort -k1,1 -n | sed "s/^/gene/" | grep -w -v "0$" > TPM-${SampleID}.txt

#rm temp-RPK-${SampleID}.tmp
#rm temp-TPM-${SampleID}.tmp


