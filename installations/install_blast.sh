#!/bin/bash

# 02/12/2021 SIF

conda create --name blast
conda activate blast
conda install -c bioconda blast
conda deactivate

update_blastdb.pl 16S_ribosomal_RNA
gzip -d 16S_ribosomal_RNA.tar.gz
tar -xf 16S_ribosomal_RNA.tar

