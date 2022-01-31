#!/bin/bash

# 2/10/2021

conda create -n run_dbcan python=3.8 diamond hmmer prodigal -c conda-forge -c bioconda
conda activate run_dbcan

pip install run-dbcan==2.0.11

mkdir run_dbcan
cd run_dbcan

test -d db || mkdir db
cd db \
    && wget http://bcb.unl.edu/dbCAN2/download/CAZyDB.07312019.fa.nr && diamond makedb --in CAZyDB.07312019.fa.nr -d CAZy \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/dbCAN-HMMdb-V8.txt && mv dbCAN-HMMdb-V8.txt dbCAN.txt && hmmpress dbCAN.txt \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tcdb.fa && diamond makedb --in tcdb.fa -d tcdb \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-1.hmm && hmmpress tf-1.hmm \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/tf-2.hmm && hmmpress tf-2.hmm \
    && wget http://bcb.unl.edu/dbCAN2/download/Databases/stp.hmm && hmmpress stp.hmm \
    && cd ../ && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.fna \
    && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.faa \
    && wget http://bcb.unl.edu/dbCAN2/download/Samples/EscheriaColiK12MG1655.gff


run_dbcan.py EscheriaColiK12MG1655.fna prok --out_dir output_EscheriaColiK12MG1655


# Installation of SignalP on SIF

# Download SignalP
mkdir -p run_dbcan/tools && run_dbcan/tools/
# Move tarball (signalp-4.1g.Linux.tar.gz) into directory 
tar xzf signalp-4.1g.Linux.tar.gz && cd signalp-4.1
# Change customizable settings in signalp
cp signalp /home/s173709/miniconda3/envs/run_dbcan/bin