#!/bin/bash 

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "mpa3"
#SBATCH --get-user-env
#SBATCH --clusters=cm2_tiny
#SBATCH --nodes=1-1
#SBATCH --cpus-per-task=48
#SBATCH --mem=50gb
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=48:00:00


module load slurm_setup 
export OMP_NUM_THREADS=48

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate metawrap

studies_folder="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis/stroke_signature"
db="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/metaphlan3_db/" 
index="mpa_v30_CHOCOPhlAn_201901"
base_data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data"

main(){
    cd $studies_folder || exit 
    studies=$(ls -d */)
    
    for i in $studies;
    do 
      cd "$i" || exit 
      data_dir="$base_data_dir/${i}/fastq/clean"
      mkdir -p metaphlan/{profiles,merged_table} 
      run_metaphlan
      merge_tables
      cd ..
    done
}

# co-assembly - if yes cat all f and all r reads

metawrap_assembly(){

echo "Running $(metaphlan --v)"

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metawrap assembly -1 CLEAN_READS/ALL_READS_1.fastq -2 CLEAN_READS/ALL_READS_2.fastq -m 200 -t 96 --use-metaspades -o ASSEMBLY
done
 
}

metawrap_binning(){

echo "Running $(metaphlan --v)"

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metaphlan $read --input_type fastq --bowtie2out $db/${sample}.bowtie2.bz2 --index $index --bowtie2db $db -o metaphlan/profiles/${sample}_profile.txt --nproc 48 &> metaphlan/${sample}.log 
done
 
}

metawrap_checkM(){

echo "Running $(metaphlan --v)"

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metaphlan $read --input_type fastq --bowtie2out $db/${sample}.bowtie2.bz2 --index $index --bowtie2db $db -o metaphlan/profiles/${sample}_profile.txt --nproc 48 &> metaphlan/${sample}.log 
done
 
}

gtdb_taxonomy(){

echo "Running $(metaphlan --v)"

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metaphlan $read --input_type fastq --bowtie2out $db/${sample}.bowtie2.bz2 --index $index --bowtie2db $db -o metaphlan/profiles/${sample}_profile.txt --nproc 48 &> metaphlan/${sample}.log 
done
 
}

# or prodigal? 
prokka_annotate(){

echo "Running $(metaphlan --v)"

inputdatalist=$(ls -d ${data_dir}/*.fastq.gz | awk '{print $NF}')

for read in ${inputdatalist};
do
  sample=$(basename ${read} | cut -f1 -d"_")
  echo "Running MetaPhlAn on sample ${sample}"
  metaphlan $read --input_type fastq --bowtie2out $db/${sample}.bowtie2.bz2 --index $index --bowtie2db $db -o metaphlan/profiles/${sample}_profile.txt --nproc 48 &> metaphlan/${sample}.log 
done
 
}


echo "Starting analysis: $(date +"%m/%d/%Y %H:%M")"
main
echo "Analysis complete: $(date +"%m/%d/%Y %H:%M")"
