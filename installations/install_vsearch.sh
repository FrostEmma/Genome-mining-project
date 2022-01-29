#!/bin/bash
# 2021-10-18

conda create --name vsearch-seqkit
conda activate vsearch-seqkit
conda install -c bioconda vsearch
conda install -c bioconda seqkit
conda deactivate