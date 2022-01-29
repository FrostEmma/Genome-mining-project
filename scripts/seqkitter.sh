#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-09-23

# Run the program with ./seqkitter.sh in ~/nz/scripts
# or with ../scripts/seqkitter.sh . in data folder

# Set help text
help="
seqkitter performs seqkit stats for all the genomes (.fa files) under a folder and outputs 
a table with statistics for the genomes in a tab-deliminated .txt file

Syntax:
    seqkitter.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
"

# Set option defaults
genome_folder="../tdata/"
loop=false

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
        -l | --loop )
            loop=true
            shift 1
            ;;
        *)
            echo "Error: unexpected option: $1"
            echo "Try seqkitter.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try seqkitter.sh --help for more information."
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

# seqkit_func performs seqkit for a single fa_file
seqkit_func() {
    fa_file=$1
    output_file=$( echo $fa_file | sed "s/.fa/_stats.txt/i")
    logt -- Starting seqkit of $fa_file
    seqkit stats $fa_file -abT > $output_file
}

# export variables and functions to be used by parallel execution
export -f seqkit_func ; export -f logt ; export -f log 

# Main
log
logt Starting seqkit of fa files under $genome_folder

time_start="$(date +%s)"

logt - Activating conda seqkit ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate seqkit

logt - Finding fasta datafiles under $genome_folder...
fa_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.fa" ! -empty -print | sort)

if [[ "$loop" == true ]] ; then
    logt - Starting seqkit in a simple loop 
    for fa_file in $fa_files ; do
        seqkit_func $fa_file
    done
else
    logt - Starting seqkit in parallel...
    parallel seqkit_func ::: $fa_files
fi

logt - Concatenating output in summary file...
output_files=$( echo $fa_files | sed "s/.fa/_stats.txt/gi" )
header=$( cat $output_files | sed '1!d' )
body=$( cat $output_files | sed '1~2d' )
echo -e "$header\n$body" > $genome_folder/seqkit_stats_summary.txt

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
fa_file_count=$(echo $fa_files | wc -w)

logt Finished seqkit stats for $fa_file_count files in $minutes_used minutes $seconds_used seconds
log