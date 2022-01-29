#!/bin/bash

# 11/10/2021

conda create --name matam
conda activate matam

# conda config --add channels defaults
conda config --add channels bioconda
# conda config --add channels conda-forge

conda install -c bioconda matam
conda install -c conda-forge parallel

index_default_ssu_rrna_db.py -d nz/scripts/dbdir --max_memory 10000