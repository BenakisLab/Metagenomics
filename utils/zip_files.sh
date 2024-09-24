#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "shotgun_data"
#SBATCH --get-user-env
#SBATCH --clusters=serial
#SBATCH --partition=serial_std
#SBATCH --cpus-per-task=12
#SBATCH --mem=32gb
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=16:00:00


cd /dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Hammond_et_al_2022/fastq/clean

for i in *.fastq;
do
 pigz -p 12 $i
done 

cd /dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/Liesz_melton_probiotics/fastq/clean

for i in *.fastq;
do
  pigz -p 12 $i  
done


