#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "rename_seqs"
#SBATCH --get-user-env
#SBATCH --clusters=cm2_tiny
#SBATCH --partition=cm2_tiny
#SBATCH --mem=32gb
#SBATCH --cpus-per-task=8
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=01:40:00

export OMP_NUM_THREADS=8

module load anaconda3
#module load python/3.6_intel
eval "$(conda shell.bash hook)"
conda activate qc
#source activate qc

fqdir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Liesz-melton_probiotics/fastq/clean"
cd $fqdir || exit

mkdir renamed
for i in *.fastq;
do
  name=$(echo "$i" | cut -f1 -d"_")
  echo "renaming fastq headers for sample ${name}"
  #seqkit replace -j 8 -p " 1.*$" -r "/1" "$R1" > renamed/"${name}"_merged_clean.fastq
  #seqkit replace -j 8 -p " 4.*$" -r "/2" "$R2" > renamed/"${name}"_S1_L001_R2_001.fastq
  seqkit replace -j 8 -p " " -r "" $i > renamed/"${name}"_merged_clean.fastq
done

