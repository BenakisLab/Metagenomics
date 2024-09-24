#!/bin/bash 

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "gtdb_tk"
#SBATCH --get-user-env
#SBATCH --clusters=inter
#SBATCH --partition=teramem_inter
#SBATCH --mem=512gb
#SBATCH --cpus-per-task=32
#SBATCH --mail-type=end
#SBATCH --ntasks=1
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=12:00:00


export OMP_NUM_THREADS=32

# set directories 
data_dir="/dss/dsshome1/lxc05/ra52noz2/shotgun_metagenomics/analysis/mouse_genome_taxonomy_MGBC/genomes"
output="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/mouse_genome_taxonomy_output"

# make external modules available 
module use /lrz/sys/share/modules/extfiles/
module load genome_assembly/fasttree/ genome_assembly/hmmer/ genome_assembly/mash genome_assembly/pplacer/ genome_assembly/prodigal/ genome_assembly/skani/

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate assembly

gtdbtk classify_wf --genome_dir $data_dir --out_dir $output  --skip_ani_screen --cpus 32
