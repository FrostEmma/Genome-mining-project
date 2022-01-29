        in_silico_PCR.pl -s EF -a 'ATYGAAATCGCCAARCG' -b 'CGGTTGATKTCCTTGA' -r -m -i > .summary 2> .temp.amplicons

        seqkit replace --quiet -p "(.+)" -r '{kv}' -k $genome_folder/$genome/clustertest/$genome-$name.summary \
        $genome_folder/$genome/clustertest/$genome-$name.temp.amplicons > $genome_folder/$genome/clustertest/$genome-$name.amplicons
