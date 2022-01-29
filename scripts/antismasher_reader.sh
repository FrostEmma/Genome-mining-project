#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-09-23

# Set help text
help="
antismasher_reader reads antismash output and gives a summary of predicted BGCs in a space-delimineted
.txt file that can be easily be read into excel where a pivot table can be constructed.

Syntax:
    antismash_reader.sh [ data_folder ] [ options ]

Options:
    -h,--help        Show this help
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
    -t,--threads N   Use N CPU threads, defaults to all available to the current process
"

# Set option defaults
loop=false
threads=$( nproc )
data_folder="../tdata/"

# Set options from the command line
if [[ $# -gt 0 && "$1" != "-"* ]] ; then
    data_folder=$1
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
            echo "Try antismash_reader.sh --help for more information."
            exit 1
            ;;
    esac
done

# echo_log is an echo function with logging
echo_log() {
	echo $@ 
}

# echo_logt is an echo_log with timestamp
echo_logt() {
	echo_log $(date "+%Y-%m-%d %H:%M:%S") $@
}

# antismash_func performs antismash for a single gbk_file
antismash_reader_func() {
    input_file=$1
    output_file=$( echo $input_file | sed "s/.gbk/_BGCs.fasta/i")
    python3 antismash_reader.py $input_file $output_file
}

# export variables and functions to be used by parallel execution
export -f antismash_reader_func ; export -f echo_logt ; export -f echo_log 

echo_log
echo_logt - Starting antismash_reader.py under $data_folder

time_start="$(date +%s)"

echo_logt - Activating conda biopython ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate biopython

# evt do a nested find?
echo_logt - Finding gbk datafiles under $data_folder...
gbk_files=$(find $data_folder -mindepth 3 -maxdepth 3 -type f -iname "*.gbk" ! -iname "*region*" -print | sort)

if [[ "$loop" == true ]] ; then
    echo_logt - Starting antismash_reader in a simple loop 
    for gbk_file in $gbk_files ; do
        antismash_reader_func $gbk_file
    done
else
    echo_logt - Starting antismash_reader in parallel on $threads CPU threads...
    parallel -j $threads antismash_reader_func ::: $gbk_files
fi

echo_logt - Concatenating output files...
output_files=$( echo $gbk_files | sed "s/.gbk/_BGCs.fasta/gi" )
header="ID BGC count"
body=$(cat $output_files)
echo -e "$header\n$body" > $data_folder/BGC_summary.txt

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
gbk_file_count=$(echo $gbk_files | wc -w)

echo_logt Finished antismash_reader.py in $minutes_used minutes $seconds_used seconds for $gbk_file_count files
echo_log
