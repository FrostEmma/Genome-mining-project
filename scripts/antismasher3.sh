#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-09-17

# Run the program with ./antismasher3.sh in ~/nz/scripts

# Set help text
help="
antismasher3 performs antismash for all the genomes under a folder using GNU parallel

Syntax:
    antismasher3.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
    -t,--threads N   Use N CPU threads, defaults to all available to the current process
"

# Set option defaults
genome_folder="../tdata/"
loop=false
all_threads=$( nproc )
threads=$[ ${all_threads} - 1 ]

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
        -t | --threads )
            threads=$2
            shift 2
            ;;
        *)
            echo "Error: unexpected option: $1"
            echo "Try antismasher3.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check if the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try antismasher3.sh --help for more information."
    exit 1
fi

# Set the number of CPU threads to use for each antismash
if [[ "$loop" == true ]] ; then
    antismash_threads=$threads
else
    antismash_threads=1
fi

# log is an echo function with logging
log() {
	echo $@ 
}

# logt is an log with timestamp
logt() {
	log $(date "+%Y-%m-%d %H:%M:%S") $@
}

# antismash_func performs antismash for a single gbk_file
antismash_func() {
    gbk_file=$1
    logt -- Starting antismash of $gbk_file
    as_time_start="$(date +%s)"
    output_dir=$( echo $gbk_file | sed "s/.gbk/antismash3/i")
    if [[ -d $output_dir ]] ; then
        rm -r $output_dir
    fi
    antismash --cb-knownclusters --asf $gbk_file --output-dir $output_dir -c $antismash_threads  
    as_time_end="$(date +%s)"
    as_time_used=$[ ${as_time_end} - ${as_time_start} ]
    logt -- Finished antismash of $gbk_file in $as_time_used seconds
}

# export variables and functions to be used by parallel execution
export -f antismash_func ; export antismash_threads ; export -f logt ; export -f log 

# Main
log
logt Starting antiSMASH of gbk files under $genome_folder

time_start="$(date +%s)"

logt - Activating conda antismash environment...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate antismash

logt - Finding gbk datafiles under $genome_folder...
gbk_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.gbk" -print | sort)


if [[ "$loop" == true ]] ; then
    logt - Starting antismash in a simple loop 
    for gbk_file in $gbk_files ; do
        antismash_func $gbk_file
    done
else
    logt - Starting antismash in parallel on $threads CPU threads...
    parallel -j $threads antismash_func ::: $gbk_files
fi

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
gbk_file_count=$(echo $gbk_files | wc -w)

logt Finished antiSMASH of the $gbk_file_count gbk files under $genome_folder in $minutes_used minutes $seconds_used seconds
log
