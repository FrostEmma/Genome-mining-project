
from Bio import SeqIO
import os
import sys
import numpy as np

# manual inputs for python debugging
# input_file = "/home/emma/nz/Programs/EFB1C56L6J.gbk" #Your GenBank file locataion. e.g C:\\Sequences\\my_genbank.gb
# output_file_name = r"/home/emma/nz/Programs/test2.txt"

# inputs from bash
input_file = sys.argv[1]
output_file_name = sys.argv[2]

text=""
organism=""
acc = os.path.basename(input_file)

for rec in SeqIO.parse(input_file, "gb"):
    for feature in rec.features:
        if feature.type == "proto_core":
            bgc = feature.qualifiers['product'][0]
            bgc_text = "{0} {1} 1\n".format(acc,bgc)
            text = "".join([text,bgc_text])

with open(output_file_name, "w+") as ofile:
    ofile.write("".join([text,"\n"]))