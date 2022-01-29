#!/bin/bash

# 11/10/2021

# 'workaround for bowtie2 error: /home/emma/miniconda3/envs/metaphlan/bin/bowtie2-build-s: error while loading shared libraries: libtbb.so.2: cannot open shared object file: No such file or directory'
sudo apt install libtbb2

conda create --name metaphlan
conda activate metaphlan
conda install -c bioconda python=3.7 metaphlan
conda deactivate

#  conda install -c biobakery graphlan
#  conda install -b bioconda export2graphlan