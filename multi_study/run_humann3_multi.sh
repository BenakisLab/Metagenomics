#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "strokemult"
#SBATCH --get-user-env
#SBATCH --clusters=inter
#SBATCH --partition=teramem_inter
#SBATCH --mem=320gb
#SBATCH --cpus-per-task=64
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=6-00:00:00


module load slurm_setup 
export OMP_NUM_THREADS=64

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate humann3

# check if human executable can be found in path if not exit
if ! command -v humann --version &> /dev/null
then
    echo "Humann executable could not be found"
    exit 1
fi

studies_folder="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/analysis/stroke_signature"
db="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/humann3_db" 

echo "study folder: " ${studies_folder}
echo "HUMAnN3 db: " ${db}


main(){
    cd $studies_folder || exit 
    studies=$(ls -d */)
    
    for i in $studies;
    do 
      cd $i || exit 
      metaphlan_profile=${studies_folder}/${i}/metaphlan/profiles/
      echo "Metaphlan profiles location : " ${metaphlan_profile}
      data_dir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/shotgun_data/${i}/fastq/clean"
      echo "FASTQ directory: " ${data_dir}


      mkdir -p humann/{profiles,merged_table} 
      ## check if database exists 
      
      run_humann
      normalize
      merge_tables
      regroup_tables
      generate_summed_tables 
      cd ..
    done
}


get_db(){

  humann_databases --download chocophlan full $db
  humann_databases --download uniref uniref90_diamond $db
  humann_databases --download uniref uniref50_diamond $db
}


run_humann(){

# make HUMAnN folder
echo "Running" $(humann --version)

filelist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${filelist};
do
  sample=$(basename ${read} | cut -f1 -d"_") 
  echo "running HUMAnN on sample: ${sample}"
# run humann 
  humann --input $read --output humann/profiles \
  --taxonomic-profile ${metaphlan_profile}/${sample}_profile.txt --search-mode uniref90 --threads 64 --remove-temp-output \
  --o-log humann/${sample}.log --verbose
done

}

normalize(){

genefamilies=$(ls -d humann/profiles/*genefamilies* | awk '{print $NF}')

for i in $genefamilies;
do 
  sample=$(basename ${i} | cut -f1 -d"_") 
  humann_renorm_table --input $i --output humann/profiles/${sample}_genefamilies_relab.tsv --units relab
done

pathabundance=$(ls -d humann/profiles/*pathabundance* | awk '{print $NF}')

for i in $pathabundance;
do 
  sample=$(basename ${i} | cut -f1 -d"_") 
  humann_renorm_table --input $i --output humann/profiles/${sample}_pathabundance_relab.tsv --units relab
done


}

merge_tables(){

echo "Merging HUMAnN output"
humann_join_tables --input humann/profiles/ --output humann/merged_table/humann_genefamilies_relab.tsv --file_name genefamilies_relab
humann_join_tables --input humann/profiles/ --output humann/merged_table/humann_pathcoverage_relab.tsv --file_name pathcoverage
humann_join_tables --input humann/profiles/ --output humann/merged_table/humann_pathabundance_relab.tsv --file_name pathabundance_relab

}

regroup_tables(){
  echo "Regrouping HUMAnN output"
  humann_regroup_table --input /humann/merged_table/humann_genefamilies_relab.tsv --groups uniref50_ko  --output humann/merged_table/humann_genefamilies_ko.tsv
  humann_regroup_table --input humann/merged_table/humann_genefamilies_relab.tsv --groups uniref50_level4ec --output humann/merged_table/humann_genefamilies_ec.tsv
}

generate_summed_tables(){
 echo "Creating unstratified tables"
 humann_split_stratified_table -i humann/merged_table/humann_genefamilies_ko.tsv -o humann/merged_table/unstrat
 humann_split_stratified_table -i humann/merged_table/humann_genefamilies_ec.tsv -o humann/merged_table/unstrat
 humann_split_stratified_table -i humann/merged_table/humann_pathabundance_relab.tsv -o humann/merged_table/unstrat
 # remove stratified 
 rm -rf humann/merged_table/unstrat/*_stratified.tsv 
}

main
echo "Analysis complete"
