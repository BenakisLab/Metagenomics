#!/bin/bash 

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "assem_test"
#SBATCH --get-user-env
#SBATCH --clusters=inter
#SBATCH --partition=teramem_inter
#SBATCH --mem=480gb
#SBATCH --cpus-per-task=8
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=04:00:00

export OMP_NUM_THREADS=8

# set directories 
data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/assembly_testing/fastq/clean"
output="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/assembly_testing/megahit_results"

# load modules and activate conda env
module load slurm_setup 
module use /lrz/sys/share/modules/extfiles/
module load genome_assembly/megahit/1.2.9

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate mag_test

if [ -d "$output" ]; then 
  rm -rf $output
fi 

samples=$(ls ${data_dir}/*_S1_L001_R1_001_clean_R1.fastq.gz | tr '\n' '\0' | xargs -0 -n 1 basename | cut -f1 -d"_")

for i in $samples;
do 
  R1=${data_dir}/${i}_S1_L001_R1_001_clean_R1.fastq.gz
  R2=${data_dir}/${i}_S1_L001_R1_001_clean_R2.fastq.gz
  echo "Running MEGAHIT on sample ${sample}"
  megahit -1 $R1 -2 $R2 -o $output --min-contig-len 1000
done

 
