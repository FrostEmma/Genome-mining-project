#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-10-05

# Set help text
help="
cazyme_finder performs run_dbcan for all the genomes under a folder (using GNU parallel). 
A summary .txt file will be created in the specified genome folder.

Syntax:
    cazyme_finder.sh [ genome_folder ] [ options ]

Options:
    -h,--help        Show this help
    -l,--loop        Use a simple loop instead of GNU parallel, for debugging
    -t,--threads N   Use N CPU threads, defaults to all available to the current process
"

# Set option defaults
genome_folder="../tdata/"
loop=false
threads=$( nproc )

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
            echo "Try cazyme_finder.sh --help for more information."
            exit 1
            ;;
    esac
done

# Check the genome folder exists
if  [[ ! -d "$genome_folder" ]] ; then
    echo "Error: genome_folder does not exist: $1"
    echo "Try cazyme_finder.sh --help for more information."
    exit 1
fi

# Set the number of CPU threads to use for each run_dbcan
if [[ "$loop" == true ]] ; then
    run_dbcan_threads=$threads
else
    run_dbcan_threads=1
fi

# log is an echo function with logging
log() {
	echo $@ 
}

# logt is an log with timestamp
logt() {
	log $(date "+%Y-%m-%d %H:%M:%S") $@
}

# run_dbcan_func performs run_dbcan for a single fa_file
run_dbcan_func() {
    fa_file=$1
    genome_folder=$2
    output_dir=$( echo $fa_file | sed "s/.fa/_cazyme/i")

    if [ -s "$fa_file" ] ; then
        if [[ -f $output_dir/signalp.out ]] ; then
            logt -  Cazyme analysis including SignalP has already been run on $fa_file
        else
            logt - Starting run_dbcan of $fa_file
            run_dbcan.py $fa_file prok --out_dir $output_dir --db_dir /home/s173709/run_dbcan/db \
            --dia_cpu 15 --hmm_cpu 15 --hotpep_cpu 15 --tf_cpu 10 --use_signalP True
        fi

        acc=$( basename $fa_file .fa )
        allhits=$( wc -l $output_dir/overview.txt | awk '{print $1-1}' )
        sp_hits=$( awk '$5~/^Y/' $output_dir/overview.txt)
        echo -e "$sp_hits" > $output_dir/sp_hits.tmp

        sp_count=$( wc -l $output_dir/sp_hits.tmp | cut -d " " -f 1 )
        echo -e $acc: $sp_count of $allhits hits have predicted signal peptides
        echo -e $acc'\t'$sp_count'\t'$allhits > $output_dir/sp_cazyme_hits1.txt
        
        hotpep=$( cut -f 3 $output_dir/sp_hits.tmp | grep -v '-' | sed 1d | sed -e 's/([^()]*)//g' | sort | uniq -c | sed -e "s/$/ $acc/" | awk '{$1=$1};1' )
        echo -e "$hotpep" > $output_dir/sp_cazyme_hits2.txt
        
        GH=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'GH' -c )
        GT=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'GT' -c )
        CBM=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'CBM' -c )
        AA=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'AA' -c )
        PL=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'PL' -c )
        CE=$(cut -f 3 $output_dir/sp_hits.tmp | grep 'CE' -c )
        echo -e $acc'\t'$GH'\t'$PL'\t'$CE'\t'$AA'\t'$CBM'\t'$GT > $output_dir/sp_cazyme_hits3.txt
    fi
}

# export variables and functions to be used by parallel execution
export -f run_dbcan_func ; export run_dbcan_threads ; export -f logt ; export -f log 

# Main
log
logt - Starting run_dbcan of .fa files under $genome_folder

time_start="$(date +%s)"

logt - Activating conda run_dbcan...
source ~/miniconda3/etc/profile.d/conda.sh
conda activate run_dbcan

logt - Finding fasta datafiles under $genome_folder...
fa_files=$(find $genome_folder -mindepth 1 -maxdepth 2 -type f -iname "*.fa" ! -empty -print | sort)
# echo $fa_files

if [[ "$loop" == true ]] ; then
    logt - Starting run_dbcan in a simple loop 
    for fa_file in $fa_files ; do
        run_dbcan_func $fa_file $genome_folder
    done
else
    logt - Starting run_dbcan in parallel on $threads CPU threads...
    parallel -j $run_dbcan_threads run_dbcan_func ::: $fa_files
fi

hits_files=$( find $genome_folder -mindepth 1 -maxdepth 3 -type f -iname "sp_cazyme_hits1.txt" -print | sort)
header="ID  sp_hits total_hits"
body=$( cat $hits_files )
echo -e "$header\n$body" > $genome_folder/sp_cazyme_hits_all.txt

hits_files2=$( find $genome_folder -mindepth 1 -maxdepth 3 -type f -iname "sp_cazyme_hits2.txt" -print | sort)
header2="count class ID"
body2=$( cat $hits_files2 )
echo -e "$header2\n$body2" > $genome_folder/sp_cazyme_hits_all_code.txt
cat $genome_folder/sp_cazyme_hits_all_code.txt

hits_files3=$( find $genome_folder -mindepth 1 -maxdepth 3 -type f -iname "sp_cazyme_hits3.txt" -print | sort)
header3="ID\t\tGH\tPL\tCE\tAA\tCBM\tGT"
body3=$( cat $hits_files3 )
echo -e "$header3\n$body3" > $genome_folder/sp_cazyme_hits_classes.txt
cat $genome_folder/sp_cazyme_hits_classes.txt

time_end="$(date +%s)"
time_used=$[ ${time_end} - ${time_start} ]
minutes_used=$[ ${time_used} / 60 ]
seconds_used=$[ ${time_used} - ${minutes_used} * 60 ]
fa_file_count=$(echo $fa_files | wc -w)

logt Finished run_dbcan of the $fa_file_count .fa files under $genome_folder in $minutes_used minutes $seconds_used seconds
log
