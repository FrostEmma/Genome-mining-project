#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-10-12

# Run the program with ./gbk_to_fasta_converter.sh in ~/nz/scripts

# Set help text
help="
gbk_to_fasta_converter finds empty fasta files and creates a complete fasta file from the corresponding
gbk file.

Syntax:
    gbk_to_fasta_converter.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
"

# Set option defaults
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
            echo "Try converter.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try converter.sh --help for more information."
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

# converter_func converts a single gbk_file
converter_func() {
    empty_file=$1

    # Make copy of existing (empty) file
    copy_file=$( echo $empty_file | sed "s/.fa/_empty.fa/i")
    cp $empty_file $copy_file

    # Define input and output for converter
    input_file=$( echo $empty_file | sed "s/.fa/.gbk/i")
    output_file=$( echo $empty_file )

    # Convert the fasta file using python script
    logt - Converting $input_file to $output_file
    python3 gbk_to_fasta_converter.py $input_file $output_file
}

# export variables and functions to be used by parallel execution
export -f converter_func ; export -f logt ; export -f log 

# Main
log
logt - Starting converter under $genome_folder

time_start="$(date +%s)"

logt - Activating conda biopython ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate biopython

logt - Finding empty fasta datafiles under $genome_folder...
fa_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.fa" ! -iname "*empty.fa" -empty -print | sort)

ogt - Converting the following fasta files: $fa_files
logt $fa_files >> $genome_folder/empty_fasta_files.log

logt - Starting converter in a simple loop 
for fa_file in $fa_files ; do
    converter_func $fa_file
done


time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
fa_file_count=$(echo $fa_files | wc -w)

logt - Finished converter of $fa_file_count fasta files under $genome_folder in $minutes_used minutes $seconds_used seconds
log
