#!/bin/bash 

#SBATCH -o ./%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "assem_test"
#SBATCH --get-user-env
#SBATCH --clusters=inter
#SBATCH --partition=teramem_inter
#SBATCH --mem=240gb
#SBATCH --cpus-per-task=4
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=02:00:00


data_dir="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/assembly_testing"

# make external modules available 
module use /lrz/sys/share/modules/extfiles/
module load genome_assembly/bowtie/2.5.3 genome_assembly/metabat/2.17 

source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate mag_test

## Read mapping 
# build bowtie2 index 
mkdir -p ${data_dir}/mapped 
mkdir -p ${data_dir}/binning
bowtie2-build ${data_dir}/megahit_results/final.contigs.fa ${data_dir}/megahit_assembly_test
bowtie2 --minins 200 --maxins 800 -x ${data_dir}/megahit_assembly_test --threads $SLURM_CPUS_PER_TASK -q -1 ${data_dir}/fastq/clean/M14-stool_S1_L001_R1_001_clean_R1.fastq.gz -2 ${data_dir}/fastq/clean/M14-stool_S1_L001_R1_001_clean_R2.fastq.gz -p 4 -S ${data_dir}/mapped/M14.sam
## 
samtools sort -o ${data_dir}/mapped/M14.bam ${data_dir}/mapped/M14.sam



## Binning 
jgi_summarize_bam_contig_depths --outputDepth ${data_dir}/binning/metabat.txt ${data_dir}/mapped/M14.bam

metabat2 -t 4 -m 1500 -i ${data_dir}/megahit_results/final.contigs.fa -a ${data_dir}/binning/metabat.txt -o ${data_dir}/metabat/metabat