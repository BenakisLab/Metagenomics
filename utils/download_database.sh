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
#SBATCH --time=02:00:00

cd /dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/humann_db/uniref
/dss/dsshome1/lxc05/ra52noz2/.local/bin/humann_databases --download uniref uniref50_diamond .

