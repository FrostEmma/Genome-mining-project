#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-11-03

# Run the program with ./centrifuger.sh in ~/nz/scripts

# Set help text
help="
Centrifuger runs centrifuge analysis on a specified genome folder against p+h+v database

Syntax:
    centrifuger.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
"
genome_folder="../tdata/"


# Set options from the command line
if [[ $# -gt 0 && "$1" != "-"* ]] ; then
    genome_folder=$1
    shift 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help )
            echo "$help"
            exit 0
            ;;
        *)
            echo "Error: unexpected option: $1"
            echo "Try centrifuger.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try centrifuger.sh --help for more information."
    exit 1
fi

# log is an echo function with logging
log() {
	echo $@ 
}

# logt is an log with timestamp
logt() {
	log $(date "+%Y-%m-%d %H:%M:%S") $@
}

# centrifuge_func performs centrifuge for a single fa file
centrifuge_func() {
    folder=$1
    acc=$( basename $folder )
    R1=$( find $folder -mindepth 1 -maxdepth 1 -type f -iname "*R1_P_trimmed.fastq.gz" -print )
    R2=$( find $folder -mindepth 1 -maxdepth 1 -type f -iname "*R2_P_trimmed.fastq.gz" -print )

    if [[ -f $folder/centrifuge_summary.txt ]] ; then
        logt -  centrifuge analysis has already been run on $acc
    else
        logt - Starting centrifuge of $acc
        centrifuge --threads 19 -x /home/common/databases/centrifuge/p+h+v -1 $R1 -2 $R2 -S $folder/reads.centri --report-file $folder/centri.classi
    fi

    sort -k6 -t$'\t' -nr $folder/centri.classi | head > $folder/centrifuge_summary.txt

    all_reads=$( wc -l $folder/reads.centri | cut -d " " -f 1)
    unclassified_reads=$( grep unclassified $folder/reads.centri | wc -l )
    unclassified_ratio=$[ 100 * ${unclassified_reads} / ${all_reads} ]
    echo -e "$acc,$unclassified_reads,$all_reads,$unclassified_ratio" > $folder/unclassified.temp
}

# export variables and functions to be used by parallel execution
export -f centrifuge_func ; export -f logt ; export -f log 

# Main
log
logt - Starting centrifuge under $genome_folder

time_start="$(date +%s)"

logt - Activating conda centrifuge ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate centrifuge


logt - Finding fasta datafiles under $genome_folder...
indiv_genome_folders=$(find $genome_folder -mindepth 1 -maxdepth 1 -type d -iname "EFB*" -print | sort)

logt - Starting centrifuge in a simple loop 
for folder in $indiv_genome_folders ; do
    centrifuge_func $folder
done


temp_files=$( find $genome_folder -type f -iname "*unclassified.temp")
cat $temp_files > $genome_folder/unclassified_ratio.txt
rm $temp_files

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
genome_count=$(echo $indiv_genome_folders | wc -w)

logt - Finished centrifuge of $genome_count genomes under $genome_folder in $minutes_used minutes $seconds_used seconds
log

