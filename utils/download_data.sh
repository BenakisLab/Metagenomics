#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "shotgun_data"
#SBATCH --get-user-env
#SBATCH --clusters=serial
#SBATCH --partition=serial_std
#SBATCH --cpus-per-task=2
#SBATCH --mem=32gb
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=03:00:00

#cd /gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/Karlsson_et_al
cd /dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/gene_catalog
wget https://zenodo.org/record/6418369/files/MGBC-ffn_26640.tar.gz 
#source /dss/dsshome1/lxc05/ra52noz2/.conda_init
#conda activate fastq-dl

#fastq-dl --outdir . --cpus 12 -a $1 --provider ENA
#while read a; do
 # prid=$a
 # echo $prid
 # grabseqs sra $a -r 3 -t 12 -m "metadata_${prid}.csv" -o ${prid}_data/ 
#done < prjids.txt
