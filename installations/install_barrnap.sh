#!/bin/bash

# 4/10/2021
# 27/10/2021 SIF

conda create --name barrnap
conda activate barrnap
conda install -c bioconda -c conda-forge barrnap
conda deactivate