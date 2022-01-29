#!/bin/bash

# 27/10/2021 sif

conda create -n antismash
conda activate antismash
conda install -c bioconda antismash
# download-antismash-databases
conda deactivate