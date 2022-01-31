#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-10-17

# Run the program with ./clusterer.sh in ~/nz/scripts

# Set help text
help="
Clusterer 

NOT FINISHED

Syntax:
    clusterer.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
    -t,--threads N   Use N CPU threads, defaults to all available to the current process
"

# Set option defaults
genome_folder="../tdata"
loop=true
threads=$( nproc )
primers="../data/default.primers"
id=0.8

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
            echo "Try clusterer.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try clusterer.sh --help for more information."
    exit 1
fi

# Set the number of CPU threads to use for each cluster
if [[ "$loop" == true ]] ; then
    cluster_threads=$threads
else
    cluster_threads=1
fi

# log is an echo function with logging
log() {
	echo $@ 
}

# logt is an log with timestamp
logt() {
	log $(date "+%Y-%m-%d %H:%M:%S") $@
}

cluster_func() {
    logt -- entering function
    genome=$( basename $1 .gbk )
    if [[ -d $genome_folder/$genome/clustertest ]]; then
        rm -r $genome_folder/$genome/clustertest
    fi
    mkdir $genome_folder/$genome/clustertest
    while read line; do
        logt -- entering loop
        name=$(echo $line | cut -f1 -d " " )
        forw=$(echo $line | cut -f2 -d " " )
        rev=$(echo $line | cut -f3 -d " " )
        logt -- name is $name

        ./in_silico_PCR.pl -s $genome_folder/$genome/$genome.16S -a $forw -b $rev -r -m -i \
        > $genome_folder/$genome/clustertest/$genome-$name.summary \
        2> $genome_folder/$genome/clustertest/$genome-$name.temp.amplicons

        seqkit replace --quiet -p "(.+)" -r '{kv}' -k $genome_folder/$genome/clustertest/$genome-$name.summary \
        $genome_folder/$genome/clustertest/$genome-$name.temp.amplicons > $genome_folder/$genome/clustertest/$genome-$name.amplicons

        # echo -e "\nMaking unique clusters with vsearch.\n\n"
        # mkdir $genome_folder/$genome/amplicons/$name-clusters
        vsearch -cluster_fast $genome_folder/$genome/clustertest/$genome-$name.amplicons \
        --id $id  -strand both --uc $genome_folder/$genome/clustertest/$genome-$name.uc \
        --clusters $genome_folder/$genome/clustertest/$genome-$name-clus \
        --quiet

        rm $genome_folder/$genome/clustertest/$genome-$name.temp.amplicons
        rm $genome_folder/$genome/clustertest/$genome-$name.summary
    done < $primers
}

# export variables and functions to be used by parallel execution
export -f cluster_func ; export cluster_threads ; export -f logt ; export -f log 

# Main
log
logt - Starting cluster under $genome_folder

time_start="$(date +%s)"

logt - Activating conda vsearch-seqkit ...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate vsearch-seqkit

logt - Finding fasta datafiles under $genome_folder...
gbk_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.gbk" ! -empty -print | sort)
logt $gbk_files

if [[ "$loop" == true ]] ; then
    logt - Starting cluster in a simple loop 
    for gbk_file in $gbk_files ; do
        cluster_func $gbk_file
    done
else
    logt - Starting cluster in parallel...
    parallel cluster_func ::: $gbk_files
fi

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
gbk_file_count=$(echo $gbk_files | wc -w)

logt - Finished cluster of $gbk_file_count genomes under $genome_folder in $minutes_used minutes $seconds_used seconds
log
