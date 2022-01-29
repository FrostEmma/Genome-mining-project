
from Bio import SeqIO
import sys

# manual inputs for python debugging
# input_file = "/home/emma/nz/scripts/EFB1C56L6J.gbk" #Your GenBank file locataion. e.g C:\\Sequences\\my_genbank.gb
# output_file = r"/home/emma/nz/scripts/test_of_converter.fa"

# inputs from bash
input_file = sys.argv[1]
output_file = sys.argv[2]

records = SeqIO.parse( input_file , "genbank" )
count = SeqIO.write( records, output_file , "fasta")
print("Converted %i records" % count)
