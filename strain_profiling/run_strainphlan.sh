#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "prob_strain"
#SBATCH --get-user-env
#SBATCH --clusters=inter
#SBATCH --partition=cm4_inter_large_mem
#SBATCH --nodes=1-1
#SBATCH --cpus-per-task=48
#SBATCH --mem=120gb
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=20:00:00


module load slurm_setup 
export OMP_NUM_THREADS=48

module load anaconda3/
eval "$(conda shell.bash hook)"
conda activate biobakery3

study="probiotics_2023"
db="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/metaphlan_db" 
data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Hammond_et_al_2022/fastq/clean"
index="mpa_vOct22_CHOCOPhlAnSGB_202212"
samdir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/temp/probiotics/sam"
marker_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/temp/probiotics/markers"
analysis_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis"
species="species.txt"
# scratch here for bowtie2 db 

main(){

    run_metaphlan
    consensus_markers
    run_strainphlan

}


run_metaphlan(){

echo "Running" $(metaphlan --v)

# make study and metaphlan folders
mkdir -p ${analysis_folder}/${study}/strainphlan/{profiles,merged_table} 

inputdatalist=$(ls -d ${data_dir}/*.fastq | awk '{print $NF}')

for read in ${inputdatalist};
do
sample=$(basename ${read} | cut -f1 -d"_")
echo "Running MetaPhlAn on sample ${sample}"
 
metaphlan $read --input_type fastq --bowtie2out $db/${sample}.bowtie2.bz2 -s ${samdir}/${sample}.sam.bz2 --index $index --bowtie2db $db -o ${analysis_folder}/${study}/strainphlan/profiles/${sample}_profile.txt --nproc 48 &> ${analysis_folder}/${study}/${sample}_strainphlan.log
done
 
}

consensus_markers(){
  sample2markers.py -i $samdir/*sam.bz2 -o $marker_dir -n 48
  while read line; 
  do 
    species=$line
    extract_markers.py -c $species -o ${marker_dir}/db_marker
  done < ${analysis_folder}/${study}/$species
}

run_strainphlan(){
  # add for loop for different strains
  strainphlan -s consensus_markers/*.pkl -m db_markers/t__SGB1877.fna -r reference_genomes/G000273725.fna.bz2 -o output -n 8 -c t__SGB1877 --mutation_rates
}

echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"
main
echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"
