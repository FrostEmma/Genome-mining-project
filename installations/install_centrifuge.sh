#!/bin/bash

# 03/11/2021 SIF

conda create --name centrifuge
conda activate centrifuge
conda install -c bioconda centrifuge

conda deactivate