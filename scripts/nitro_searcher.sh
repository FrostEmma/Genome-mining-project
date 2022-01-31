#!/bin/bash

# Emma Thinggaard Frost, s173709@student.dtu.dk
# 2021-09-29

# Set help text
help="
nitro_search searches for genes related to nitrification and denitrification nitrogen metabolism

Syntax:
    nitro_search.sh [ data_folder ]
"

# Set option defaults
loop=true
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
            echo "Try nitro_search.sh --help for more information."
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

echo_logt - Finding gbk datafiles under $data_folder...
gbk_files=$(find $data_folder -mindepth 2 -maxdepth 2 -type f -iname "*.gbk" ! -iname "*region*" -print | sort)

echo_logt - Searching for nitro genes
nitro=$(grep -ri --include \*.gbk nitro $gbk_files | cut -d "=" -f 2) #|  sort | uniq -c | sort -nr
nitra=$(grep -ri --include \*.gbk nitrate $gbk_files | cut -d "=" -f 2) #|  sort | uniq -c | sort -nr
nitri=$(grep -riw --include \*.gbk nitri.* $gbk_files | cut -d "=" -f 2) #|  sort | uniq -c | sort -nr

echo_logt - Sorting and counting occurrences
echo -e "$nitro\n$nitra\n$nitri" | sort | uniq -c | sort -nr > $data_folder/nitro_genes.txt
cat $data_folder/nitro_genes.txt

# grep -riw --include \*.gbk amo. $gbk_files
# grep -ri --include \*.gbk "Conserved nitrate reductase-associated protein" $gbk_files
# grep -ri --include \*.gbk nitrogenase $gbk_files
# grep -ri --include \*.gbk nitroreductase $gbk_files | sort -u
# grep -ri --include \*.gbk "nitronate monooxygenase" $gbk_files
# grep -ri --include \*.gbk "Nitrous oxide reductase" $gbk_files
# grep -ri --include \*.gbk "ammonia monooxygenase" $gbk_files | cut -d "=" -f 2 |  sort | uniq -c | sort -nr
# grep -ri --include \*.gbk "hydroxylamine dehydrogenase" $gbk_files | cut -d "=" -f 2 |  sort | uniq -c | sort -nr
# grep -ri --include \*.gbk "nitrite oxidoreductase" $gbk_files
