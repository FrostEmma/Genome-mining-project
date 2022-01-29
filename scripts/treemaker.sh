#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-11-03

# Run the program with ./treemaker.sh in ~/nz/scripts

# Set help text
help="
Treemaker performs alignment using MAFFT and constructs a tree using FastTree.
Sequence file must be a .txt file.

Syntax:
    treemaker.sh [ sequence file ] [ options ]

Options:
    -h,--help        Show this help
"

# Set options from the command line
if [[ $# -gt 0 && "$1" != "-"* ]] ; then
    seq_file=$1
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
            echo "Try treemaker.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -f "$seq_file" ]] ; then
    echo "Error: seq_file does not exist: $1"
    echo "Try treemaker.sh --help for more information."
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

# export variables and functions to be used by parallel execution
export -f logt ; export -f log 

# Main
log
logt - Starting treemaker for $seq_file

time_start="$(date +%s)"

logt - Activating conda treemaker - contains MAFFT, alv, and FastTree...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate treemaker

aln_file=$( echo $seq_file | sed "s/.txt/.aln/i")
tree_file=$( echo $seq_file | sed "s/.txt/.tree/i")

mafft --adjustdirection $seq_file > $aln_file
alv $aln_file
fasttree -nt -gtr $aln_file > $tree_file

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]

logt - Finished tree for $seq_file in $minutes_used minutes $seconds_used seconds
log

