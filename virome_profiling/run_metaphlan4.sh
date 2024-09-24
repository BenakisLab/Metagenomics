#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "ahrsens"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --cpus-per-task=64
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=10:00:00


module load slurm_setup 
export OMP_NUM_THREADS=64

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate biobakery3.9

study="mouse_stool_2023"
# lxclscratch for CoolMuc3 and teramem compute nodes only 
db="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/metaphlan_db" 
#db="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/metaphlan_db"
data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Delgado_bile_acids/fastq/clean"
index="mpa_vJun23_CHOCOPhlAnSGB_202307"
analysis_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis"
# scratch here for bowtie2 db 
main(){

    run_metaphlan
    merge_tables
	
}


run_metaphlan(){

if ! metaphlan --version | grep -q "4.1"; 
  then
  echo "MetaPhlAn version 4.1.0 is required for virome profiling" 
  exit
fi 

echo "Running" $(metaphlan --version)

# make study and metaphlan folders
mkdir -p ${analysis_folder}/${study}/metaphlan/{profiles,merged_table} 

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metaphlan $read --input_type fastq --profile_vsc --vsc_breadth 0.4 --bowtie2out $db/${sample}.bowtie2.bz2 --index $index --bowtie2db $db --vsc_out ${analysis_folder}/${study}/metaphlan/profiles/${sample}_profile_vsc.txt -o ${analysis_folder}/${study}/metaphlan/profiles/${sample}_profile.txt --nproc 64 &> ${analysis_folder}/${study}/metaphlan/profiles/${sample}.log 

done
 
}

merge_tables(){

echo "Merging MetaPhlAn output"
merge_metaphlan_tables.py ${analysis_folder}/${study}/metaphlan/profiles/*.txt > ${analysis_folder}/${study}/metaphlan/merged_table/merged_table.txt
echo "Merging MetaPhlAn virome output"
merge_vsc_tables.py -o ${analysis_folder}/${study}/metaphlan/merged_table/merged_table_vsc.txt ${analysis_folder}/${study}/metaphlan/profiles/*_vsc.txt
}

echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"
main
echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"
