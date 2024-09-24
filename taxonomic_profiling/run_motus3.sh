#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "probiomous"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --cpus-per-task=32
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=02:00:00


module load slurm_setup 
export OMP_NUM_THREADS=32


source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate motus

# options
HIGH_SENSITIVITY=true

study="probiotics_mouse/ileum"
db="/dss/dsshome1/lxc05/ra52noz2/.conda/envs/motus/lib/python3.9/site-packages/motus/db_mOTU" 
data_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/probiotics_mouse/fastq/clean/ileum"
analysis_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis"

echo "study folder: " ${study}
echo "mOTUs db: " ${db}
echo "FASTQ directory: " ${data_dir}
echo "High sensitivity: " ${HIGH_SENSITIVITY}

main(){

    run_motus
    merge_tables
	
}


run_motus(){

echo "Running" $(motus --v)

# make study and metaphlan folders
mkdir -p ${analysis_folder}/${study}/motus/{profiles,merged_table} 

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running mOTUs on sample ${sample}"
  if [ "$HIGH_SENSITIVITY" = true ] ; then
    motus profile -s $read -db $db -n $sample -g 2 -l 45 -o ${analysis_folder}/${study}/motus/profiles/${sample}_profile.txt -c -A -t 32 &> ${analysis_folder}/${study}/${sample}.log 
  else 
    motus profile -s $read -db $db -n $sample -o ${analysis_folder}/${study}/motus/profiles/${sample}_profile.txt -c -A -t 32 &> ${analysis_folder}/${study}/${sample}.log 
  fi
done
 
}

merge_tables(){

echo "Merging mOTUs output"
motus merge -d ${analysis_folder}/${study}/motus/profiles > ${analysis_folder}/${study}/motus/merged_table/merged_table.txt

}

echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"
main
echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"

echo "Job information: " 
srun hostname
scontrol show job $SLURM_JOB_ID
sacct -l -j $SLURM_JOB_ID