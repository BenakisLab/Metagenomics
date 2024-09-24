#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "ahrur90"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=48:00:00

module load slurm_setup
export OMP_NUM_THREADS=64
source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate biobakery3 

study="ahr_project_2023"
data_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/shotgun_data/AhR_project/fastq/clean"
analysis_folder="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/analysis"
metaphlan_profiles="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis/ahr_project_2023/metaphlan/profiles"
#uniref90 or uniref50
search_mode="uniref90" 

echo "study folder: " ${study}
/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_config --print
echo "Metaphlan profiles location : " ${metaphlan_profiles}
echo "FASTQ directory: " ${data_dir}
echo "UNIREF search mode: " ${search_mode}

start=$(date "+%Y-%m-%d %T")
echo "starting analysis: " ${start}

main(){
  
  run_humann
  normalize
  merge_tables
  regroup_tables
  generate_summed_tables
  move_tables

}

run_humann(){

# make HUMAnN folder
mkdir -p ${analysis_folder}/${study}/humann/{profiles,merged_table} 

cd ${analysis_folder}/${study}/humann || exit

echo "Running" $(/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann --version)

filelist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${filelist};
do
  sample=$(basename ${read} | cut -f1 -d"_") 
  echo "running HUMAnN on sample: ${sample}"
# run humann 
  /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann --input $read --output ${analysis_folder}/${study}/humann/profiles/ \
  --taxonomic-profile ${metaphlan_profiles}/${sample}_profile.txt --search-mode $search_mode \
  --threads 64 --remove-temp-output --o-log ${analysis_folder}/${study}/humann/${sample}.log --verbose
done

}

normalize(){

genefamilies=$(ls -d ${analysis_folder}/${study}/humann/profiles/*genefamilies* | awk '{print $NF}')

for i in $genefamilies;
do 
  sample=$(basename ${i} | cut -f1 -d"_") 
  /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_renorm_table --input $i --output ${analysis_folder}/${study}/humann/profiles/${sample}_genefamilies_relab.tsv --units relab
done

pathabundance=$(ls -d ${analysis_folder}/${study}/humann/profiles/*pathabundance* | awk '{print $NF}')

for i in $pathabundance;
do 
  sample=$(basename ${i} | cut -f1 -d"_") 
  /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_renorm_table --input $i --output ${analysis_folder}/${study}/humann/profiles/${sample}_pathabundance_relab.tsv --units relab
done


}

merge_tables(){

echo "Merging HUMAnN output"
/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_join_tables --input ${analysis_folder}/${study}/humann/profiles/ --output ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_relab.tsv --file_name genefamilies_relab
/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_join_tables --input ${analysis_folder}/${study}/humann/profiles/ --output ${analysis_folder}/${study}/humann/merged_table/humann_pathcoverage_relab.tsv --file_name pathcoverage
/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_join_tables --input ${analysis_folder}/${study}/humann/profiles/ --output ${analysis_folder}/${study}//humann/merged_table/humann_pathabundance_relab.tsv --file_name pathabundance_relab

}

regroup_tables(){
  echo "Regrouping HUMAnN output"

  if [ $search_mode = "uniref90" ] ; then
    uniref_ko="uniref90_ko"
    uniref_ec="uniref90_level4ec"
  else 
    uniref_ko="uniref50_ko"
    uniref_ec="uniref50_level4ec"
  fi 
 
  /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_regroup_table --input ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_relab.tsv --groups $uniref_ko  --output ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_ko.tsv
  /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_regroup_table --input ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_relab.tsv --groups $uniref_ec --output ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_ec.tsv
}

generate_summed_tables(){
 echo "Creating unstratified tables"
 /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_split_stratified_table -i ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_ko.tsv -o ${analysis_folder}/${study}/humann/merged_table/unstrat
 /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_split_stratified_table -i ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_ec.tsv -o ${analysis_folder}/${study}/humann/merged_table/unstrat
 /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_split_stratified_table -i ${analysis_folder}/${study}/humann/merged_table/humann_pathabundance_relab.tsv -o ${analysis_folder}/${study}/humann/merged_table/unstrat
 /dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_split_stratified_table -i ${analysis_folder}/${study}/humann/merged_table/humann_genefamilies_relab.tsv -o ${analysis_folder}/${study}/humann/merged_table/unstrat
 # remove stratified copies
 rm -rf ${analysis_folder}/${study}/humann/merged_table/unstrat/*_stratified.tsv 
}

move_tables(){
    mv ${analysis_folder}/${study}/humann/ /dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis/${study}
}

main

end=$(date "+%Y-%m-%d %T")
echo "Analysis complete: " ${end}

echo "Job information: " 
echo $SLURM_JOB_PARTITION
scontrol show job $SLURM_JOB_ID
sacct -l -j $SLURM_JOB_ID

