#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "metaSNV_h"
#SBATCH --get-user-env
#SBATCH --clusters=cm2_tiny
#SBATCH --nodes=1-1
#SBATCH --cpus-per-task=32
#SBATCH --mem=50gb
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=48:00:00


module load slurm_setup 
export OMP_NUM_THREADS=32

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate motusv2.5

study="probiotics_2023"
#db="/dss/dsshome1/lxc05/ra52noz2/.conda/envs/motusv2.5/share/motus-2.5.0/db_mOTU" 
#data_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/shotgun_data/Liesz_melton_probiotics/human/fastq/clean"
# For jobs running on Cool-Muc2 clusters
data_dir="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/Liesz_melton_probiotics/human/fastq/clean"
analysis_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis"

main(){

    map_snvs
    call_snvs
	
}


map_snvs(){

echo "Running" $(motus --v)

# make study and metaSNV folders
mkdir -p ${data_dir}/bam_files

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Mapping SNVs for sample ${sample}"
  motus map_snv -s $read  -n $sample -o ${analysis_folder}/${study}/motus/profiles/${sample}_profile.txt -l 45 -t 32 -v 3 > ${data_dir}/bam_files/${sample}.bam 
done

} 

call_snvs(){
    # make study and metaSNV folder
    mkdir -p ${analysis_folder}/${study}/motus_metaSNV
    echo "Calling SNVs"
    motus snv_call -d ${data_dir}/bam_files -o ${analysis_folder}/${study}/motus_metaSNV/strain_profile -t 32 -v 3 
}

echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"
main
echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"
