#!/bin/bash

#29-10-2021

conda create --name reago python=3.9
#conda install -c bioconda reago
git clone https://github.com/chengyuan/reago-1.1
# edit PY
conda install -c bioconda infernal
pip install networkx
#conda install -c conda-forge networkx
conda install -c bioconda genometools-genometools

conda deactivate


python filter_input.py sample_1.fasta sample_2.fasta filter_out cm ba 10

python reago.py filter_out/filtered.fasta sample_out -l 101


#reago_2
conda create --name reago 
conda install -c bioconda reago
git clone https://github.com/chengyuan/reago-1.1
# copy 2x PY fra env/bin

python filter_input_env.py sample_1.fasta sample_2.fasta filter_out cm ba 10
python reago_env.py filter_out/filtered.fasta sample_out -l 101


#reago_3
conda create --name reago_3 python=3.8
#conda install -c bioconda reago
git clone https://github.com/chengyuan/reago-1.1
# edit PY
conda install -c bioconda infernal
#pip install networkx
conda install -c conda-forge networkx
conda install -c bioconda genometools-genometools

python filter_input_py3.py sample_1.fasta sample_2.fasta filter_out cm ba 10
python reago_py3.py filter_out/filtered.fasta sample_out -l 101

