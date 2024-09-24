#!/bin/bash

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "database_installation"
#SBATCH --get-user-env
#SBATCH --clusters=serial
#SBATCH --partition=serial_std
#SBATCH --mem=20gb
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=8:00:00

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate mpa3 

cd /gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/metaphlan3_db || exit

wget https://zenodo.org/records/3957592/files/mpa_latest
wget https://zenodo.org/records/3957592/files/mpa_v30_CHOCOPhlAn_201901.md5
wget https://zenodo.org/records/3957592/files/mpa_v30_CHOCOPhlAn_201901_marker_info.txt.bz2
wget https://zenodo.org/records/3957592/files/mpa_v30_CHOCOPhlAn_201901.tar

tar -xvf mpa_v30_CHOCOPhlAn_201901.tar
bzip2 -d mpa_v30_CHOCOPhlAn_201901.fna.bz2

bowtie2-build mpa_v30_CHOCOPhlAn_201901.fna mpa_v30_CHOCOPhlAn_201901

#metaphlan --install --index $db_version --bowtie2db $dbdir
#humann_databases --download chocophlan full $dbdir
#humann_databases --download uniref uniref90_diamond $dbdir

