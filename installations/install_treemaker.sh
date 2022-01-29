#!/bin/bash

# 27/01/2022

conda create --name treemaker
conda activate treemaker

conda install -c bioconda mafft
conda install -c bioconda alv
conda install -c bioconda fasttree

# conda install -c conda-forge parallel

