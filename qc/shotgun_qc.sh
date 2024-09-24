#!/bin/bash

#SBATCH -o /dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/%x.%j.%N.out 
#SBATCH -D ./ 
#SBATCH -J "mmprobioqc"
#SBATCH --get-user-env
#SBATCH --clusters=mpp3
#SBATCH --partition=mpp3_batch
#SBATCH --mem=80gb
#SBATCH --cpus-per-task=64
#SBATCH --mail-type=end
#SBATCH --mail-user=adam.sorbie@med.uni-muenchen.de
#SBATCH --export=NONE
#SBATCH --time=30:00:00

export OMP_NUM_THREADS=64
module load slurm_setup
 
# coolMuc3
source /dss/dsshome1/lxc05/ra52noz2/.conda_init
conda activate biobakery3

# edit outputdir name
inputdir="/dss/lxclscratch/05/ra52noz2/shotgun_metagenomics/shotgun_data/Liesz_melton_probiotics/mouse/fastq/"
intermediate="/gpfs/scratch/pr63la/ra52noz2/shotgun_metagenomics/"
# contam db
host="MOUSE"
if [ "$host" == "HUMAN" ];
then 
  contam_db="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/custom_db/human_contam"
elif [ "$host" == "MOUSE" ];
then 
  contam_db="/dss/dssfs02/lwp-dss-0001/pr63la/pr63la-dss-0000/ra52noz2/shotgun_data/custom_db/mouse_contam"
fi
# exe 
atria_exe="/dss/dsshome1/lxc05/ra52noz2/atria-3.2.2-linux/bin/atria"
# options
POLY_X=true
REMOVE_INTERMEDIATE=true
N_THREADS=32
ADAPTERS="NEXTERA"

if [ "$ADAPTERS" == "NEXTERA" ];
then 
  BARCODE_1="CTGTCTCTTATACACATCTGACGCTGCCGACGA"
  BARCODE_2="CTGTCTCTTATACACATCTCCGAGCCCACGAGAC"
elif [ "$ADAPTERS" == "TRUSEQ" ];
then 
  BARCODE_1="AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC"
  BARCODE_2="AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"
fi

echo "study folder: " ${inputdir}
echo "Poly_x removal: " ${POLY_X}
echo "Adapters: " ${ADAPTERS}



main(){
  cd $inputdir || exit
  # make directories for QC output (logging and reports)
  mkdir -p fastqc_start fastqc_end log reports clean
  # make directories for 
  mkdir -p ${intermediate}/merged ${intermediate}/trimmed
  # cat PE reads into single file
  cat_reads 
  # run fastqc on merged reads
  run_fastqc_start
  # run trimming and filtering
  run_trimming
  # remove sequences aligning to host genome
  remove_host
  # rerun fastqc after trimming and host removal
  run_fastqc_end
  # run multiqc to combined fastqc reports
  run_multiqc
  # run seqkit to get Gbp and number of seqs per read
  run_seqkit
  # clean up directories, remove unecessary files
  cleanup	
}


cat_reads(){
  echo "Merging reads: $(date +"%d/%m/%Y %H:%M")"
  samples=$(ls *S*_L001_R1_001.fastq.gz | cut -f1 -d"_")
  for i in $samples;
  do 
    R1="${i}_S*_L001_R1_001.fastq.gz"
    R2="${i}_S*_L001_R2_001.fastq.gz" 
    cat $R1 $R2 > ${intermediate}/merged/${i}_merged.fastq.gz
  done 
  echo "Reads merged: $(date +"%d/%dm/%Y %H:%M")"
}

run_fastqc_start(){
  fastqc -t $N_THREADS ${intermediate}/merged/*.fastq.gz -o fastqc_start
}

run_trimming(){
  echo "Starting trimming: $(date +"%d/%m/%Y %H:%M")"
  # loop through fastq files - need to change this or add rename script, _1 file naming pattern not most common 
  samples=$(ls ${intermediate}/merged/*.fastq.gz | tr '\n' '\0' | xargs -0 -n 1 basename | cut -f1 -d"_")
  for i in $samples;
  do 
    read=${intermediate}/merged/${i}_merged.fastq.gz
    echo "trimming: ${read}"
    if [ "$POLY_X" = true ] ; then
      $atria_exe -r $read -a $BARCODE_1 -A $BARCODE_2 --length-range 75:200 -q 20 -n 2 -g GZIP --polyG -t $N_THREADS --force --output-dir ${intermediate}/trimmed >> log/trimming.log 2>&1 
    else 
      $atria_exe -r $read -a $BARCODE_1 -A $BARCODE_2 --length-range 75:200 -q 20 -n 2 -g GZIP -t $N_THREADS --force --output-dir ${intermediate}/trimmed >> log/trimming.log 2>&1 
    fi 
  done
  echo "Trimming completed: $(date +"%d/%m/%Y %H:%M")"
}

remove_host(){
  echo "Starting host removal: $(date +"%d/%m/%Y %H:%M")"
  samples=$(ls ${intermediate}/trimmed/*.fastq.gz | tr '\n' '\0' | xargs -0 -n 1 basename | cut -f1 -d".")
  for i in $samples;
  do 
    read=${intermediate}/trimmed/${i}.atria.fastq.gz
    echo "decontaminating: ${read}"
    bowtie2 -x $contam_db -U $read -p $N_THREADS --very-sensitive --un-gz clean/${i}_clean.fastq.gz  
  done
  echo "Host removal completed: $(date +"%d/%m/%Y %H:%M")"
}

run_fastqc_end(){
  fastqc -t $N_THREADS clean/*.fastq.gz -o fastqc_end
}

run_multiqc(){
  multiqc fastqc_start -o fastqc_start
  multiqc fastqc_end -o fastqc_end
}

run_seqkit(){
  seqkit stats -j $N_THREADS -a ${intermediate}/merged/*.fastq.gz -b -T > reports/sequence_stats_start.tsv
  seqkit stats -j $N_THREADS -a ${intermediate}/trimmed/*.fastq.gz -b -T > reports/sequence_stats_trim.tsv
  seqkit stats -j $N_THREADS -a clean/*.fastq.gz -b -T > reports/sequence_stats_end.tsv
  sequence_stats.py -r reports/sequence_stats_start.tsv \
    -t reports/sequence_stats_trim.tsv \
    -c reports/sequence_stats_end.tsv \
    -o reports/sequence_stats_merged.tsv
}
 
cleanup(){ 
  if [ "$REMOVE_INTERMEDIATE" = true ] ; then
    # remove merged and trimmed files to save space
    rm -rf ${intermediate}/merged ${intermediate}/trimmed
    # move multiqc reports and delete fastqc folders
    mv fastqc_start/multiqc_report.html reports/multiqc_start.html
    mv fastqc_end/multiqc_report.html reports/multiqc_end.html
    rm -rf fastqc_start fastqc_end
  else 
    # move multiqc reports and delete fastqc folders
    cp fastqc_start/multiqc_report.html reports/multiqc_start.html
    cp fastqc_end/multiqc_report.html reports/multiqc_end.html
    rm -rf fastqc_start fastqc_end
  fi

}

echo "Starting processing: $(date +"%d/%m/%Y %H:%M")"

main
cat reports/sequence_stats_merged.tsv
echo "Processing complete: $(date +"%d/%m/%Y %H:%M")"

echo "Job information: " 
srun hostname
scontrol show job $SLURM_JOB_ID
sacct -l -j $SLURM_JOB_ID