#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "ahr"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --cpus-per-task=28
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=06:00:00

module load slurm_setup 
export OMP_NUM_THREADS=28

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate biobakery3.9

# options
HIGH_SENSITIVITY=true 
HOST="human"
ANALYSIS_TYPE="rel_ab"
INDEX="mpa_vOct22_CHOCOPhlAnSGB_202212"
# june 2023 version
#INDEX="mpa_vJun23_CHOCOPhlAnSGB_202307"
# mouse specific db
#INDEX="MRGM_20221205"

study="ahr_project_2023"
# lxclscratch for CoolMuc3 and teramem compute nodes only 
if [ $HOST = "human" ] ; then
   #db="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/metaphlan_db/default" 
   db="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/metaphlan_db/default" 
else 
   #db="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/metaphlan_db/mouse_specific"   
   db="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/metaphlan_db/mouse_specific"

fi 

data_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/shotgun_data/AhR_project/fastq/clean"
analysis_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis"

echo "study folder: " ${study}
echo "Metaphlan db: " ${db}
echo "Metaphlan index version: " ${INDEX}
echo "FASTQ directory: " ${data_dir}
echo "High sensitivity: " ${HIGH_SENSITIVITY}
echo "Host: " ${HOST}
echo "Analysis output: " ${ANALYSIS_TYPE}

# scratch here for bowtie2 db 
main(){

    run_metaphlan
    merge_tables
	
}


run_metaphlan(){

echo "Running" $(metaphlan --version)

# make study and metaphlan folders
mkdir -p ${analysis_folder}/${study}/metaphlan/{profiles,merged_table} 


inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
sample=$(basename ${read} | cut -f1 -d"_")
echo "Running MetaPhlAn on sample ${sample}"
  if [ "$HIGH_SENSITIVITY" = true ] ; then
    # very high sensitivity "--min_mapq_val 2 --stat_q 0.05 --perc_nonzero 0.2" high sensitivity "--min_mapq_val 3 --stat_q 0.1 --perc_nonzero 0.3"
    metaphlan $read --input_type fastq -t $ANALYSIS_TYPE --min_mapq_val 2 --stat_q 0.05 --perc_nonzero 0.2 --bowtie2out $db/${sample}.bowtie2.bz2 --index $INDEX --bowtie2db $db -o ${analysis_folder}/${study}/metaphlan/profiles/${sample}_profile.txt --nproc 28 &> ${analysis_folder}/${study}/metaphlan/profiles/${sample}.log  
  else 
    metaphlan $read --input_type fastq -t $ANALYSIS_TYPE --bowtie2out $db/${sample}.bowtie2.bz2 --index $INDEX --bowtie2db $db -o ${analysis_folder}/${study}/metaphlan/profiles/${sample}_profile.txt --nproc 28 &> ${analysis_folder}/${study}/metaphlan/profiles/${sample}.log 
  fi

done
 
}

merge_tables(){

echo "Merging MetaPhlAn output"
if [ "$ANALYSIS_TYPE" = "rel_ab_w_read_stats" ] ; then
  merge_metaphlan_tables_abs.py ${analysis_folder}/${study}/metaphlan/profiles/*.txt > ${analysis_folder}/${study}/metaphlan/merged_table/merged_table.txt
else 
  merge_metaphlan_tables.py ${analysis_folder}/${study}/metaphlan/profiles/*.txt > ${analysis_folder}/${study}/metaphlan/merged_table/merged_table.txt
  
fi 
}

echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"

# check input folder exist
if [ -d "$data_dir" ];  then
    main
else 
    echo "Provided input folder ${data_dir} does not exist, exiting"
    exit 1 
fi 

echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"

echo "Job information: " 
echo $SLURM_JOB_PARTITION
scontrol show job $SLURM_JOB_ID
sacct -l -j $SLURM_JOB_ID
