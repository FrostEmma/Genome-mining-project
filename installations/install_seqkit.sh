#!/bin/bash
# 2021-09-23

# 27/10/2021 SIF

conda create --name seqkit
conda activate seqkit
conda install -c bioconda seqkit
conda deactivate