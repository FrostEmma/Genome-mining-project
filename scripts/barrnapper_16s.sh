#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-10-04

# Run the program with ./barrnapper_16s.sh in ~/scripts

# Set help text
help="
barrnapper_16s finds and concatenates all 16S rRNA sequences in the genomes in the genome folder

Syntax:
    barrnapper_16s.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
    -r,--reject      Set reject length for rRNA sequence
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
    -t,--threads N   Use N CPU threads, defaults to all available to the current process
"

# Set option defaults
genome_folder="../tdata/"
loop=false
threads=$( nproc )
reject='0.80'

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
        -r | --reject )
            reject=$2
            shift 2
            ;;
        *)
            echo "Error: unexpected option: $1"
            echo "Try barrnapper.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try barrnapper.sh --help for more information."
    exit 1
fi

# Set the number of CPU threads to use for each barrnap
if [[ "$loop" == true ]] ; then
    barrnap_threads=$threads
else
    barrnap_threads=1
fi

# log is an echo function with logging
log() {
	echo $@ 
}

# logt is an log with timestamp
logt() {
	log $(date "+%Y-%m-%d %H:%M:%S") $@
}

# barrnap_func performs barrnap for a single fa file
barrnap_func() {
    fa_file=$1
    reject=$2
    rna_file=$( echo $fa_file | sed "s/.fa/.rRNA/i")
    rna_16S_file=$( echo $fa_file | sed "s/.fa/.16S/i")
    rna_16S_titles=$( echo $fa_file | sed "s/.fa/.title/i")
    if [[ -s $rna_file ]] ; then
        rm $rna_file
    fi
    
    logt -- Starting barrnap of $fa_file
    iterations=0
    while [[ ! -s $rna_file ]] && [[ $iterations -lt 3 ]] ; do
        barrnap -q --reject $reject -o $rna_file $fa_file
        iterations=$[ ${iterations} + 1 ]
    done
    logt -- Reconstructing $rna_file
    id=$( basename $fa_file .fa )
    if [[ -s ../data/id_species.csv ]] ; then # Looks up species in index if provided
        species=$( grep $id ../data/id_species.csv | cut -d "," -f 2 | sed "s/ /-/g" )
    fi
    sed -E -i "s/:.*/:$id/g" $rna_file
    awk '/16S_rRNA/{print;getline;print;}' $rna_file > $rna_16S_file
    count_duplicates=$( cat $rna_16S_file | grep 'rRNA' | wc -w )
    number=$count_duplicates
    while [[ $number -gt 0 ]] ; do
        sed -iw "0,/>16S_rRNA:$id/s//>16SrRNA_$id-$number\_$species/" $rna_16S_file
        number=$[ ${number} - 1 ]
    done
    cat $rna_16S_file
    rm $rna_16S_titles
    grep "^>" $rna_16S_file | cut -c 2- > $rna_16S_titles

    if [[ ! -s $rna_16S_file ]] ; then
        echo WARNING! empty 16S rRNA file $rna_16S_file
        echo '' > $rna_16S_titles
    fi
    if [[ ! -s $rna_file ]] ; then
        echo WARNING! empty rRNA file $rna_file
    fi
}

# export variables and functions to be used by parallel execution
export -f barrnap_func ; export barrnap_threads ; export -f logt ; export -f log 

# Main
log
logt - Starting barrnap under $genome_folder

time_start="$(date +%s)"

logt - Activating conda barrnap ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate barrnap

logt - Finding fasta datafiles under $genome_folder...
fa_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.fa" ! -empty -print | sort)

if [[ "$loop" == true ]] ; then
    logt - Starting barrnap in a simple loop 
    for fa_file in $fa_files ; do
        barrnap_func $fa_file $reject
    done
else
    logt - Starting barrnap in parallel...
    parallel barrnap_func ::: $fa_files ::: $reject
fi

logt - Concatenating 16S rRNA sequences into one file...
output_files=$( echo $fa_files | sed "s/.fa/.16S/gi" )
cat $output_files > $genome_folder/all_16S-$reject.txt

# Specific code for my dataset

# logt - Creating title file for meta data file
# title_files=$( echo $fa_files | sed "s/.fa/.title/gi")
# pretty_title=$( cat $title_files | cut -d "_" -f 2,3 | sed "s/_/ /g" )
# cat $title_files > $genome_folder/title_16S-$reject.txt
# echo $pretty_title > $genome_folder/pretty_title_16S-$reject.txt
# rm $title_files

cat $genome_folder/all_16S-$reject.txt | grep "rRNA*" | cut -d "-" -f 1 | uniq -c > $genome_folder/16S_with_$reject.log
count_16S=$( cat $genome_folder/16S_with_$reject.log | wc -l )
logt - There are $count_16S genomes with at least one 16S rRNA using threshold = $reject

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
fa_file_count=$(echo $fa_files | wc -w)

logt - Finished barrnap of $fa_file_count .fa files under $genome_folder in $minutes_used minutes $seconds_used seconds
log
