#!/bin/bash

# 1/11/2021

conda create --name mafft
conda activate mafft

conda install -c bioconda mafft
conda install -c bioconda alv
# conda install -c conda-forge parallel

